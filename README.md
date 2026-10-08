# Happier: unofficial Android build of Happy

An **unofficial** build of [Happy](https://github.com/slopus/happy), the open-source mobile client for
Claude Code and Codex. It is built from Happy's own source code plus two small patches. It is **not made or
endorsed by the Happy team**.

**Download:** <https://thedyxer.github.io/happier/> (or the [latest release](https://github.com/TheDyXer/happier/releases/latest))

## What's different from the official app

- **Newer models in the model menu.** Claude: Opus 5.5 (+1M), Sonnet 5.5 (+1M), Haiku 5.5 (+1M), Haiku 4.5, next to
  Fable 5.1, Fable 5, Opus 5 and Sonnet 5. Codex: GPT-6.1 Sol, GPT-6 Sol, GPT-6 Luna, GPT-5.5, next to GPT-6 Astra and
  GPT-5.6. ([patch 0001](patches/0001-app-newer-models.patch))
- **Uses the server `https://happy.colombus.fun` by default** instead of Happy's hosted server. You can
  change it in Settings → Server.
- **Installs next to the official app** (its own app ID `fun.colombus.happier`), named "Happier".
- **No push notifications** and **no automatic over-the-air updates**. New versions are published here.
  ([patch 0002](patches/0002-app-own-android-variant.patch))

Everything else is the official Happy app at tag `cli-1.2.5` (app version 1.8.0). Messages stay end-to-end
encrypted the same way: the server only stores data it can't read.

## Install (Android)

1. Open the download page on your phone and tap **Download APK**.
2. Open the file. If Android asks, allow your browser to install apps ("Install unknown apps").
3. Optional: compare the file's SHA-256 with the one on the release page.

## Log in

Accounts on `happy.colombus.fun` are separate from accounts on Happy's hosted server.

- **New here:** tap **Create account**.
- **Already use this server on another device:** on that device go to Settings → Account → Link New Device
  and scan the QR code shown by this app.
- **Same phone as the official app (already on this server):** in the official app go to Settings → Account →
  Secret Key (tap to copy), then in this app choose **Restore an existing account** → **Use a secret key
  instead** and paste it.

## Connect your computer

On the computer that runs Claude Code or Codex:

```bash
npm install -g happy
```

Point it at the server by creating `~/.happy/settings.json` (Windows: `%USERPROFILE%\.happy\settings.json`):

```json
{ "serverUrl": "https://happy.colombus.fun" }
```

Then run `happy`, choose **Mobile App**, and scan the QR code with this app. The CLI passes the model you pick
straight to Claude Code / Codex, so a model only works if your installed Claude Code or Codex knows it.

There is also a browser version with the same model menus: <https://happyweb.colombus.fun>.

## Updates

- **Obtainium** (recommended): install [Obtainium](https://github.com/ImranR98/Obtainium/releases/latest),
  tap **Add app**, paste `https://github.com/TheDyXer/happier` and install Happier through it. Installed that
  way it updates in the background; an app first installed from the browser still gets found, but each update
  needs a tap.
- Or download the newest APK from the page and install it over the old one; the account stays.

Versions look like `1.8.0+3`: the Happy app version, then this project's release number, which only goes up.

## Build it yourself

The build runs in Docker (Linux host) with `reactnativecommunity/react-native-android:v20.1`, which matches
React Native 0.83.1 (SDK 36, build-tools 36.0.0, NDK 27.1.12297006, JDK 17).

```bash
git clone --depth 1 --branch cli-1.2.5 https://github.com/slopus/happy.git src
git -C src apply "$PWD"/patches/*.patch     # run from a folder that contains patches/ and android/
sudo ./android/build-apk.sh --new-key       # first build; later builds without --new-key
                                            # → android/out/happier.apk
```

`--new-key` creates your own signing key in `android-keys/`. Back it up somewhere private: Android only installs
an update over an app signed with the same key. Without `--new-key` the script stops if the key is missing,
so a wrong folder or a lost key never produces an APK that can't update.

`HAPPIER_BUILD=N sudo -E ./android/build-apk.sh` builds release N (version `X.Y.Z+N`, versionCode `100+N`);
without it the version stays `X.Y.Z` / `1`.

## License

MIT. Happy is © Happy Coder Contributors, see [LICENSE](LICENSE). The patches and build scripts in this
repository are released under the same license.
