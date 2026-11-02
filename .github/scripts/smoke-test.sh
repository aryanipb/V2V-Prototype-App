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

# Only this app's crash records and process logs count; other apps log unrelated errors.
crash_report=$(adb logcat -d -b crash | grep -A 30 "Process: $package" || true)
if [ -n "$crash_report" ]; then
  echo "$crash_report"
  exit 1
fi

pid=$(adb shell pidof "$package" | tr -d '\r' || true)
if [ -z "$pid" ]; then
  echo "App is not running after ${settle_seconds}s"
  adb logcat -d | tail -100
  exit 1
fi

fatal_errors=$(adb logcat -d --pid="$pid" | grep -E "UnsatisfiedLinkError|ClassNotFoundException|NoSuchMethodError|NoClassDefFoundError" || true)
if [ -n "$fatal_errors" ]; then
  echo "$fatal_errors"
  exit 1
fi

echo "Smoke test passed: $package is running with no crash."
