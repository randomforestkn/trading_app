#!/usr/bin/env bash
set -euo pipefail

flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build apk --release \
  --dart-define=APP_FLAVOR=demo \
  --dart-define=APP_VERSION_LABEL=MVP\ Demo \
  --dart-define=APP_BUILD_LABEL=MVP\ Demo\ -\ Demo
