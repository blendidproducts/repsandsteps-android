# RepsAndSteps Android app (APK)

A Capacitor shell that wraps the live RepsAndSteps web app in a real Android app:
its own icon, full screen, no browser bars, camera access for ARTP rep tracking.

**Why this design:** the shell loads `https://repsandsteps.com` at runtime, so every
web change you publish is live in the app immediately — no new APK, no store review.
You only rebuild the APK when the *shell* changes (icon, permissions, app name, version).
That is the "continuous updates" promise on the install page, and it is true.

---

## One-time setup

1. **Point it at the right URL.** In `capacitor.config.json`, `server.url` is
   `https://repsandsteps.com`. If the app itself lives on a Base44 URL, put that URL
   there instead and keep `repsandsteps.com` in `allowNavigation`.
2. **Drop in the icon.** Put `logo-icon.png` (1024×1024, from
   `website-public-updated/public/`) at `resources/icon.png`, and a 2732×2732 splash at
   `resources/splash.png`. Then `npx @capacitor/assets generate --android`.
   Skip this and you ship the default Capacitor icon.
3. **Make the signing key — once, ever:** `powershell -ExecutionPolicy Bypass -File .\make-keystore.ps1`
   Back `release.keystore` up. Lose it and you can never update the Play listing.

## Build it

**On your machine** (needs Node 18+, JDK 21, Android SDK):

```powershell
cd F:\Personal\Per\RepsAndSteps\apk
powershell -ExecutionPolicy Bypass -File .\build-apk.ps1 -Version 1.0.0            # debug, installs anywhere
powershell -ExecutionPolicy Bypass -File .\build-apk.ps1 -Version 1.0.0 -Release   # signed release
```

**On GitHub** (no Android SDK needed on your machine at all):

- Copy `.github/workflows/build-apk.yml` into the repo, commit, push.
- Add the four secrets printed by `make-keystore.ps1`.
- Actions → *Build RepsAndSteps APK* → Run workflow. Or push a tag: `git tag v1.0.0 && git push --tags`
- The APK downloads from the run's Artifacts, and a tag also creates a GitHub Release.

## Ship it

1. Rename the APK to `repsandsteps-latest.apk`.
2. Upload to your site at `/downloads/repsandsteps-latest.apk`.
3. Update `/app-version.json` with the version, size and SHA-256 the build printed
   (the CI job writes this file for you — just upload it).

The install page reads `app-version.json`, so the version and file size shown to
visitors update the moment you upload it.

## Debug vs release — which do I give people?

| | Debug APK | Release APK |
|---|---|---|
| Installs on a phone | yes | yes |
| Signed with | throwaway debug key | your `release.keystore` |
| Fine for public download | no | **yes** |
| Can be uploaded to Google Play | no | yes (as .aab) |

Use debug to test on your own phone today; ship release to the website.

## For Google Play later

Play wants an **App Bundle**, not an APK: `cd android && ./gradlew bundleRelease`
→ `android/app/build/outputs/bundle/release/app-release.aab`, signed with the same
keystore. A Play listing also needs a privacy policy URL — `privacy.html` on the site
still doesn't exist, and Play will reject the submission without it.

## Known constraints — worth reading once

- **Nobody can silently auto-install an APK.** Android requires the person to tap the
  file and allow installs from your browser, once. The install page automates every
  part that *can* be automated (the download starts by itself) and walks them through
  the rest in three steps.
- **iOS cannot install APKs at all.** iPhone visitors get the Add-to-Home-Screen path
  instead, which gives them an icon and a full-screen app without the App Store.
- **Play Protect will show a warning** the first few hundred installs because the app
  is new and unknown to Google. That's expected; the install page tells people so they
  don't bail. It goes away as install volume builds, or once you're on Play.
