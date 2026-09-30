import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tasbeh/core/theme/app_theme.dart';
import 'package:tasbeh/features/tasbeeh/application/tasbeeh_controller.dart';
import 'package:tasbeh/features/tasbeeh/presentation/screens/tasbeeh_home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const focusChannel = MethodChannel('tasbeh/focus_mode');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(focusChannel, (_) async => null);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(focusChannel, null);
  });

  testWidgets('Focus Mode reaches the same collapsed and enlarged end state', (
    tester,
  ) async {
    final controller = TasbeehController();
    addTearDown(controller.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: TasbeehHomeScreen(
          state: controller.state,
          onIncrement: () {},
          onResetSession: () {},
          onOpenSettings: () {},
          phrases: controller.phrases,
          onSelectDhikr: (_) {},
          onAddCustomPhrase: (_) async {},
          onOpenStatistics: () {},
          onOpenManualLog: () {},
          focusController: controller,
          hapticEnabled: false,
          onHapticChanged: (_) {},
        ),
      ),
    );

    double chromeHeight() => tester
        .widget<Align>(find.byKey(const ValueKey('tasbeeh-top-chrome')))
        .heightFactor!;
    double countSize() => tester
        .widget<Text>(find.byKey(const ValueKey('tasbeeh-focus-count')))
        .style!
        .fontSize!;

    expect(chromeHeight(), 1);
    final normalCountSize = countSize();

    await tester.tap(find.text('وضع التركيز'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 480));

    expect(chromeHeight(), 0);
    expect(countSize(), greaterThan(normalCountSize));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
