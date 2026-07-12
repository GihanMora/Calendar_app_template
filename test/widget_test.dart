// Basic sanity tests for the Thai Calendar app.
//
// The default Flutter counter template test was removed because this app has
// no counter UI. Pumping the full app in a test would require ad/notification
// platform channels that aren't available in the widget-test harness, so we
// verify configuration defaults instead.

import 'package:flutter_test/flutter_test.dart';

import 'package:calendar_app_template/config/app_config.dart';

void main() {
  test('AppConfig exposes sensible defaults before initialization', () {
    expect(AppConfig.appName, isNotEmpty);
    expect(AppConfig.packageName, 'com.gihan.thaicalendar');
    expect(AppConfig.applicationId, 'com.gihan.thaicalendar');
  });
}
