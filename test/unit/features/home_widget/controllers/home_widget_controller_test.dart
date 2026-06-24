import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/features/home_widget/presentation/controllers/home_widget_controller.dart';

void main() {
  group('HomeWidgetController', () {
    test('provider is accessible from ProviderContainer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(homeWidgetControllerProvider);
      expect(controller, isA<HomeWidgetController>());
    });
  });
}
