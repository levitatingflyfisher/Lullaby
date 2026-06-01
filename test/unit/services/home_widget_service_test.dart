import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/services/home_widget_service.dart';

void main() {
  group('HomeWidgetService._ago', () {
    String ago(DateTime? dt) => HomeWidgetService.agoForTesting(dt);

    test('null returns dash', () {
      expect(ago(null), '–');
    });

    test('30 seconds ago returns Just now', () {
      final dt = DateTime.now().subtract(const Duration(seconds: 30));
      expect(ago(dt), 'Just now');
    });

    test('45 minutes ago returns 45m ago', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 45));
      expect(ago(dt), '45m ago');
    });

    test('1h 30m ago returns 1h 30m ago', () {
      final dt = DateTime.now().subtract(const Duration(hours: 1, minutes: 30));
      expect(ago(dt), '1h 30m ago');
    });

    test('exactly 2h ago returns 2h ago', () {
      final dt = DateTime.now().subtract(const Duration(hours: 2));
      expect(ago(dt), '2h ago');
    });

    test('3 days ago returns 3d ago', () {
      final dt = DateTime.now().subtract(const Duration(days: 3));
      expect(ago(dt), '3d ago');
    });
  });
}
