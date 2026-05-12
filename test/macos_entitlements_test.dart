import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS entitlements include outbound network client access', () {
    final debugEntitlements = File(
      'macos/Runner/DebugProfile.entitlements',
    ).readAsStringSync();
    final releaseEntitlements = File(
      'macos/Runner/Release.entitlements',
    ).readAsStringSync();

    expect(debugEntitlements, contains('com.apple.security.network.client'));
    expect(releaseEntitlements, contains('com.apple.security.network.client'));
  });
}
