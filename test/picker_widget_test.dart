import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_colours/just_colours.dart';

Widget _host(Widget child) => MaterialApp(
  theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
  home: Scaffold(body: Center(child: SizedBox(width: 360, child: child))),
);

void main() {
  setUp(() => ColourLibrary.session.clearRecentColours());

  testWidgets('switching to Gradient gives a gradient built from the colour', (
    tester,
  ) async {
    final changes = <ColourSelection>[];
    await tester.pumpWidget(
      _host(
        ColourPickerPanel(
          initialSelection: const ColourSelection(color: Color(0xFFFF0044)),
          onChanged: changes.add,
          onApply: (_) {},
          onCancel: () {},
        ),
      ),
    );
    await tester.tap(find.text('Gradient'));
    await tester.pumpAndSettle();
    expect(changes.last.useGradient, isTrue);
    expect(changes.last.gradient.colors.first, const Color(0xFFFF0044));
    expect(find.text('Linear'), findsOneWidget);
  });

  testWidgets('Enter applies, Escape cancels', (tester) async {
    ColourSelection? applied;
    var cancelled = false;
    await tester.pumpWidget(
      _host(
        ColourPickerPanel(
          initialSelection: const ColourSelection(color: Colors.blue),
          onApply: (s) => applied = s,
          onCancel: () => cancelled = true,
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(applied?.color, Colors.blue);
    expect(ColourLibrary.session.recentColours.first, Colors.blue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(cancelled, isTrue);
  });

  testWidgets('typing a hex code changes the colour and keeps alpha', (
    tester,
  ) async {
    ColourSelection? last;
    await tester.pumpWidget(
      _host(
        ColourPickerPanel(
          initialSelection: const ColourSelection(color: Color(0x80FFFFFF)),
          onChanged: (s) => last = s,
          onApply: (_) {},
          onCancel: () {},
        ),
      ),
    );
    await tester.enterText(find.byType(TextField).first, '00ff00');
    await tester.pump();
    expect(last?.color.toARGB32(), 0x8000FF00);
  });

  testWidgets('a colour-only picker never gives a gradient', (tester) async {
    ColourSelection? applied;
    await tester.pumpWidget(
      _host(
        ColourPickerPanel(
          initialSelection: const ColourSelection(
            color: Colors.red,
            useGradient: true,
          ),
          view: ColourDialogView.colourOnly,
          onApply: (s) => applied = s,
          onCancel: () {},
        ),
      ),
    );
    expect(find.text('Gradient'), findsNothing);
    await tester.tap(find.text('Apply'));
    expect(applied?.useGradient, isFalse);
  });

  testWidgets('clicking the stop bar adds a colour', (tester) async {
    ColourSelection? last;
    await tester.pumpWidget(
      _host(
        ColourPickerPanel(
          initialSelection: const ColourSelection(
            color: Colors.red,
            useGradient: true,
            gradient: GradientConfig(colors: [Colors.black, Colors.white]),
          ),
          view: ColourDialogView.gradientOnly,
          onChanged: (s) => last = s,
          onApply: (_) {},
          onCancel: () {},
        ),
      ),
    );
    final bar = find.byType(GradientStopBar);
    expect(bar, findsOneWidget);
    await tester.tap(bar);
    await tester.pump();
    expect(last?.gradient.colors.length, 3);
  });

  testWidgets('popover: a click outside applies, Escape cancels', (
    tester,
  ) async {
    late BuildContext anchor;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: Builder(
              builder: (context) {
                anchor = context;
                return const SizedBox(width: 120, height: 30);
              },
            ),
          ),
        ),
      ),
    );

    var result = ColourPopover.show(
      anchor,
      initialSelection: const ColourSelection(color: Colors.orange),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ColourPickerPanel), findsOneWidget);
    await tester.tapAt(const Offset(5, 590));
    await tester.pumpAndSettle();
    expect((await result)?.color, Colors.orange);

    result = ColourPopover.show(
      anchor,
      initialSelection: const ColourSelection(color: Colors.orange),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(await result, isNull);
  });

  testWidgets('the eyedropper picks through the sampler; Escape gives up', (
    tester,
  ) async {
    ColourSelection? last;
    Offset? asked;
    await tester.pumpWidget(
      _host(
        ColourPickerPanel(
          initialSelection: const ColourSelection(color: Colors.white),
          sampler: (at) async {
            asked = at;
            return const Color(0xFF123456);
          },
          onChanged: (s) => last = s,
          onApply: (_) {},
          onCancel: () {},
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.colorize_rounded));
    await tester.pump();
    expect(find.text('Click to pick a colour · Esc to cancel'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Click to pick a colour · Esc to cancel'), findsNothing);
    expect(last, isNull);

    await tester.tap(find.byIcon(Icons.colorize_rounded));
    await tester.pump();
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(asked, const Offset(5, 5));
    expect(last?.color, const Color(0xFF123456));
  });
}
