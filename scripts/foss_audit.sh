#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 ASPTechnologies Incorporation
# SPDX-License-Identifier: MIT
#
# Fails if YumMealPrep depends on proprietary, tracking or network-only
# libraries. Any of these would stop the app being accepted by F-Droid or
# break its promise to work offline without tracking.
#
# Usage: ./scripts/foss_audit.sh
# Run `flutter pub get` first. The Gradle check runs when android/gradlew
# exists (create it with `flutter build apk --config-only`).
set -euo pipefail
cd "$(dirname "$0")/.."

status=0

# Dart packages, as resolved in pubspec.lock.
#   firebase_*, cloud_firestore  Google Firebase (proprietary SDKs, tracking)
#   google_mobile_ads            adverts
#   google_sign_in, google_maps  Google Play services
#   in_app_review/in_app_purchase Google Play / App Store only
#   google_fonts                 downloads fonts from Google at run time
#   sentry_*, onesignal, appsflyer, facebook  crash reporting and tracking
banned_pub='firebase_[a-z_]+|cloud_firestore|google_mobile_ads|google_sign_in|google_maps_flutter|in_app_review|in_app_purchase|google_fonts|sentry_[a-z_]+|sentry|onesignal_flutter|appsflyer_sdk|facebook_[a-z_]+|flutter_facebook_[a-z_]+'

if [[ ! -f pubspec.lock ]]; then
  echo "pubspec.lock is missing. Run 'flutter pub get' first." >&2
  exit 1
fi

if matches=$(grep -En "^  (${banned_pub}):$" pubspec.lock); then
  echo "Non-free or tracking Dart packages found in pubspec.lock:"
  echo "$matches"
  status=1
else
  echo "Dart packages: OK"
fi

# Native Android libraries pulled in by plugins.
banned_maven='com\.google\.firebase|com\.google\.android\.gms|com\.google\.android\.play|com\.android\.billingclient|com\.google\.mlkit|com\.crashlytics'

if [[ -x android/gradlew ]]; then
  if ! dependencies=$(cd android && ./gradlew -q :app:dependencies --configuration releaseRuntimeClasspath); then
    echo "Could not list the Android dependencies." >&2
    exit 1
  fi
  if matches=$(grep -E "$banned_maven" <<<"$dependencies"); then
    echo "Non-free Android libraries found:"
    echo "$matches" | sort -u
    status=1
  else
    echo "Android libraries: OK"
  fi
else
  echo "Skipping the Android check: android/gradlew not found."
  echo "Create it with: flutter build apk --config-only"
fi

# The Firebase Gradle plugin must not come back either.
if grep -rEn "google-services|firebase" android --include='*.gradle' --include='*.gradle.kts'; then
  echo "Firebase Gradle configuration found."
  status=1
fi

exit "$status"
