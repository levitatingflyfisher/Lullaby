// Android host config no widget test can see. home_widget finds the widget's
// provider with Class.forName: by qualifiedAndroidName if given, else
// "<applicationId>.<name>". Lullaby asked for "LullabyWidget" while the class is
// LullabyWidgetProvider, so every update threw ClassNotFoundException on the
// emulator and the home-screen widget never refreshed.
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullaby/services/home_widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the provider named to home_widget is a class declared under android/', () {
    final name = HomeWidgetService.androidProvider;
    final dot = name.lastIndexOf('.');
    final package = name.substring(0, dot), cls = name.substring(dot + 1);
    final declared = <String>[];
    for (final f in Directory('android/app/src/main').listSync(recursive: true)) {
      if (f is! File || !RegExp(r'\.(kt|java)$').hasMatch(f.path)) continue;
      final src = f.readAsStringSync();
      final pkg = RegExp(r'^package\s+([\w.]+)', multiLine: true).firstMatch(src)?.group(1);
      for (final m in RegExp(r'^\s*(?:public\s+)?(?:open\s+)?class\s+(\w+)', multiLine: true).allMatches(src)) {
        declared.add('$pkg.${m.group(1)}');
      }
    }
    expect(declared, contains(name));

    // The manifest's receiver resolves (against the Gradle namespace) to it too.
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    final namespace = RegExp(r'namespace\s*=\s*"([^"]+)"').firstMatch(gradle)!.group(1)!;
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final receivers = [
      for (final m in RegExp(r'<receiver\s+android:name="([^"]+)"').allMatches(manifest))
        m.group(1)!.startsWith('.') ? '$namespace${m.group(1)}' : m.group(1)!,
    ];
    expect(receivers, contains(name));
    expect(package, namespace);
    expect(cls, 'LullabyWidgetProvider');
  });

  test('update asks home_widget for that exact class', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), (call) async {
      calls.add(call);
      return true;
    });
    await HomeWidgetService.update(
      baby: null,
      lastFeeding: null,
      lastSleep: null,
      lastDiaper: null,
      activeTimer: null,
    );
    final update = calls.singleWhere((c) => c.method == 'updateWidget');
    expect((update.arguments as Map)['qualifiedAndroidName'], HomeWidgetService.androidProvider);
  });
}
