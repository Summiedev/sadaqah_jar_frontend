import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sadaqah_jar/core/theme/app_theme.dart';
import 'package:sadaqah_jar/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('onboarding keeps its copy and mode choices across all slides', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
    );
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox &&
            widget.color == MizanColors.light.surfaceContainerHigh,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'lib/assets/images/onboarding_prayer_scene.png',
      ),
      findsOneWidget,
    );
    expect(find.text('Make room\nfor what matters.'), findsOneWidget);
    expect(
      find.text('A private place for the small acts you want to keep close.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(PageView), const Offset(-420, 0));
    await tester.pumpAndSettle();
    expect(find.text('Keep the rhythm\ngentle.'), findsOneWidget);
    expect(
      find.text(
        'Read a page. Make a prayer. Give what you can. Come back without guilt.',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(PageView), const Offset(-420, 0));
    await tester.pumpAndSettle();
    expect(find.text('Begin where\nyou are.'), findsOneWidget);
    expect(find.text('Just me'), findsOneWidget);
    expect(find.text('With family'), findsOneWidget);
    expect(find.text('Both'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            extensions: const [MizanColors.dark],
          ),
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox &&
            widget.color == MizanColors.dark.surfaceContainerHigh,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
