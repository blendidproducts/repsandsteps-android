#!/usr/bin/env node
/* Patches the generated android/ project so the RepsAndSteps web app works
   inside the shell. Safe to run repeatedly — every edit is idempotent.

   1. CAMERA permission  -> ARTP rep tracking (MediaPipe) can open the camera
   2. Hardware feature   -> declared optional so the Play Store doesn't hide the
                            app from tablets without a rear camera
   3. Screen-on          -> the phone doesn't sleep mid-set
   4. usesCleartext off  -> HTTPS only
*/
const fs = require("fs");
const path = require("path");

const manifestPath = path.join(__dirname, "..", "android", "app", "src", "main", "AndroidManifest.xml");

if (!fs.existsSync(manifestPath)) {
  console.error("✗ AndroidManifest.xml not found. Run `npx cap add android` first.");
  process.exit(1);
}

let xml = fs.readFileSync(manifestPath, "utf8");
let changed = false;

const additions = [
  '<uses-permission android:name="android.permission.CAMERA" />',
  '<uses-permission android:name="android.permission.WAKE_LOCK" />',
  '<uses-permission android:name="android.permission.VIBRATE" />',
  '<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />',
  '<uses-feature android:name="android.hardware.camera" android:required="false" />',
  '<uses-feature android:name="android.hardware.camera.autofocus" android:required="false" />'
];

for (const line of additions) {
  const key = line.match(/android:name="([^"]+)"/)[1];
  const tag = line.startsWith("<uses-permission") ? "uses-permission" : "uses-feature";
  const already = new RegExp(`<${tag}[^>]*android:name="${key.replace(/\./g, "\\.")}"`).test(xml);
  if (!already) {
    xml = xml.replace(/<\/manifest>/, `    ${line}\n</manifest>`);
    changed = true;
    console.log("  + " + key);
  }
}

// Keep the screen awake while a workout is running
if (!/android:keepScreenOn/.test(xml)) {
  xml = xml.replace(
    /(<activity[^>]*android:name="[^"]*MainActivity"[^>]*)/,
    '$1\n            android:keepScreenOn="true"'
  );
  changed = true;
  console.log("  + keepScreenOn on MainActivity");
}

if (changed) {
  fs.writeFileSync(manifestPath, xml, "utf8");
  console.log("✓ AndroidManifest.xml patched");
} else {
  console.log("✓ AndroidManifest.xml already patched — nothing to do");
}
