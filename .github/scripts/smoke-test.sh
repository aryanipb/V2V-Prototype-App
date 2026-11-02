#!/usr/bin/env bash
# Installs the APK on a running emulator/device and fails if the app crashes at launch.
set -euo pipefail

apk=$1
package=com.aryan.v2v
settle_seconds=${SETTLE_SECONDS:-30}

adb install -r -g "$apk"
adb logcat -c
adb shell am start -W -n "$package/.MainActivity"
sleep "$settle_seconds"

crashes=$(adb logcat -d -b crash,main | grep -E "FATAL EXCEPTION|Process: $package|UnsatisfiedLinkError|ClassNotFoundException|NoSuchMethodError" || true)
if [ -n "$crashes" ]; then
  echo "$crashes"
  adb logcat -d -b crash | tail -50
  exit 1
fi

if ! adb shell pidof "$package" > /dev/null; then
  echo "App is not running after ${settle_seconds}s"
  adb logcat -d | tail -100
  exit 1
fi

echo "Smoke test passed: $package is running with no crash."
