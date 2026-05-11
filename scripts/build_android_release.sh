#!/usr/bin/env bash
set -euo pipefail

flutter clean
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter build appbundle --release \
  --dart-define=APP_FLAVOR=production \
  --dart-define=APP_VERSION_LABEL=1.0.0 \
  --dart-define=APP_BUILD_LABEL=1.0.0
