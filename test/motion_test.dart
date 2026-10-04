import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindcare/config/theme.dart';
import 'package:mindcare/views/patient/breathing_screen.dart';
import 'package:mindcare/widgets/feedback.dart';
import 'package:mindcare/widgets/motion.dart';
import 'package:mindcare/widgets/sliding_tabs.dart';

Widget host(Widget child) => MaterialApp(
      theme: MindCareTheme.lightTheme,
      builder: (context, c) => ToastHost(child: c!),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  testWidgets('FadeSlideIn waits for its delay, then settles', (tester) async {
    await tester.pumpWidget(host(const FadeSlideIn(
      delay: Duration(milliseconds: 100),
      child: Text('hello'),
    )));
    double opacity() => tester.widget<Opacity>(find.byType(Opacity).first).opacity;

    expect(opacity(), 0);
    await tester.pump(const Duration(milliseconds: 150)); // timer fires
    await tester.pump(const Duration(milliseconds: 100)); // mid-animation
    expect(opacity(), greaterThan(0));
    expect(opacity(), lessThan(1));
    await tester.pump(const Duration(milliseconds: 400));
    expect(opacity(), 1);
  });

  testWidgets('with reduced motion content simply appears', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(host(const FadeSlideIn(
      delay: Duration(milliseconds: 300),
      child: Text('hello'),
    )));
    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 1);
  });

  testWidgets('AsyncButton goes Save -> Saving -> Saved -> Save', (tester) async {
    var saves = 0;
    await tester.pumpWidget(host(AsyncButton(
      label: 'Save',
      onPressed: () async {
        saves++;
        return true;
      },
    )));
    expect(find.text('Save'), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.text('Saving'), findsOneWidget);

    // A second tap while saving is ignored.
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Saved'), findsOneWidget);
    expect(saves, 1);

    await tester.pump(const Duration(milliseconds: 1400));
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('AsyncButton returns to idle when the action fails', (tester) async {
    await tester.pumpWidget(host(AsyncButton(
      label: 'Go',
      onPressed: () async => false,
    )));
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(find.text('Saving'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Go'), findsOneWidget);
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('toasts slide in, wait, and leave on their own', (tester) async {
    await tester.pumpWidget(host(const SizedBox()));
    Toasts.show('Reflection saved');
    await tester.pump();
    expect(find.text('Reflection saved'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Reflection saved'), findsNothing);
  });

  testWidgets('a soft dialog opens and closes', (tester) async {
    await tester.pumpWidget(host(Builder(
      builder: (context) => TextButton(
        onPressed: () => showSoftDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Hello'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
        child: const Text('Open'),
      ),
    )));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Hello'), findsNothing);
  });

  testWidgets('sliding tabs move the indicator and report taps', (tester) async {
    var index = 0;
    await tester.pumpWidget(host(StatefulBuilder(
      builder: (context, setState) => SizedBox(
        width: 360,
        child: SlidingTabs(
          labels: const ['Overview', 'Trends', 'History'],
          index: index,
          onChanged: (i) => setState(() => index = i),
        ),
      ),
    )));
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(index, 2);
    final slide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
    expect(slide.offset, const Offset(2, 0));
  });

  testWidgets('count-up reaches its value', (tester) async {
    await tester.pumpWidget(host(const CountUp(value: 7)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('7'), findsNothing); // still counting
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('breathing exercise runs and cleans up its timers', (tester) async {
    await tester.pumpWidget(host(const BreathingScreen(minutes: 1)));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Breathe in'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Breathe out'), findsOneWidget);
    // Leaving the screen disposes the controller and timer without errors.
    await tester.pumpWidget(host(const SizedBox()));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the loader renders in both motion modes', (tester) async {
    await tester.pumpWidget(host(const BreathingLoader()));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Taking a moment…'), findsOneWidget);
    await tester.pumpWidget(host(const SizedBox()));
  });
}
