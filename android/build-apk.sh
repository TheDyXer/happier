#!/usr/bin/env bash
# Build the Happier Android app. Run from the folder that contains src/, patches/ and android/
# (needs Docker with BuildKit; use sudo if your user is not in the docker group).
#   ./android/build-apk.sh            build + verify, APK in android/out/happier.apk
#   ./android/build-apk.sh --new-key  first build only: also create the signing key
#   HAPPIER_BUILD=N ./android/build-apk.sh   release build N (version X.Y.Z+N)
# Assumes src/ is checked out at the Happy tag with patches/*.patch applied (see README "Build it yourself").
set -euo pipefail
cd "$(dirname "$0")/.."

IMAGE=reactnativecommunity/react-native-android:v20.1
KEYDIR=android-keys
KEY=$KEYDIR/happier.keystore
OUT=android/out

# 1. Own signing key, created once and kept here (never in src/, never published). Back it up:
#    Android only installs an update signed with the same key, so losing it means uninstall + restore.
#    Never created silently: a missing key usually means a wrong folder or a lost key, not a first build.
if [ ! -f "$KEY" ]; then
  if [ "${1:-}" != "--new-key" ]; then
    echo "No signing key at $KEY. Restore your backup there, or pass --new-key on the very first build" >&2
    echo "(APKs signed with a new key can't install over an app signed with an older one)." >&2
    exit 1
  fi
  mkdir -p "$KEYDIR" && chmod 700 "$KEYDIR"
  docker run --rm -v "$PWD/$KEYDIR:/k" "$IMAGE" keytool -genkeypair -noprompt \
    -keystore /k/happier.keystore -alias androiddebugkey -keyalg RSA -keysize 2048 \
    -validity 20000 -storepass android -keypass android -dname "CN=Happier, O=colombus.fun"
  chown "$(stat -c %u .):$(stat -c %g .)" "$KEY" && chmod 600 "$KEY"
fi

# 2. Build (layers + Gradle cache are reused on later builds).
rm -rf "$OUT"
docker build -f android/Dockerfile.android \
  --secret id=keystore,src="$KEY" \
  --build-arg HAPPY_BUILD_COMMIT_SHA="$(git -C src rev-parse HEAD)" \
  --build-arg HAPPIER_BUILD="${HAPPIER_BUILD:-0}" \
  --target out --output type=local,dest="$OUT" \
  --progress=plain src
APK=$OUT/happier.apk

# 3. Verify before anyone installs it.
docker run --rm -v "$PWD/$OUT:/o" -v "$PWD/$KEYDIR:/k:ro" "$IMAGE" bash -c "
  set -e
  BT=\$(ls -d \$ANDROID_HOME/build-tools/* | sort -V | tail -1)
  echo '== badging'; \$BT/aapt dump badging /o/happier.apk | grep -E '^(package|application-label|sdkVersion|targetSdkVersion|native-code)'
  echo '== OTA updates (value must be 0x0 = off)'; \$BT/aapt dump xmltree /o/happier.apk AndroidManifest.xml | grep -A1 'expo.modules.updates.ENABLED' | tr -s ' '
  echo '== signer'; \$BT/apksigner verify --print-certs /o/happier.apk | grep -E 'SHA-256|DN'
  echo '== keystore'; keytool -list -keystore /k/happier.keystore -storepass android | grep -i sha-256 || true
  echo '== bundle strings'; cd /tmp && unzip -o -q /o/happier.apk assets/index.android.bundle
  for s in happy.colombus.fun claude-opus-5-5 gpt-6.1-sol api.cluster-fluster.com; do
    printf '%-26s %s\n' \"\$s\" \"\$(grep -a -o \"\$s\" assets/index.android.bundle | wc -l)\"; done
"
chown "$(stat -c %u .):$(stat -c %g .)" -R "$OUT"
sha256sum "$APK" | tee "$APK.sha256"
ls -la "$APK"
