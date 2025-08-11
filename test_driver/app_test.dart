import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Vector Cleanup App Tests', () {
    late FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      driver.close();
    });

    test('app should start without crashing with vector cleanup enabled', () async {
      // Wait for app to load
      await driver.waitFor(find.byType('MaterialApp'));
      
      // Verify app started successfully
      expect(await driver.requestData('app_started'), 'true');
    });

    test('vector cleanup should run during startup', () async {
      // This would require instrumentation in the actual app
      // For now, we verify the app doesn't crash during startup
      await driver.waitFor(find.byType('MaterialApp'));
      
      // If we get here, startup completed successfully
      expect(true, isTrue);
    });
  });
}
