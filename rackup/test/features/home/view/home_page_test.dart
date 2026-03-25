import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_spacing.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/features/home/view/home_page.dart';

import '../../../helpers/pump_app.dart';

class _MockGoRouter extends Mock implements GoRouter {}

void main() {
  group('HomePage', () {
    late GoRouter mockRouter;

    setUp(() {
      mockRouter = _MockGoRouter();
      when(() => mockRouter.push<Object?>(any(), extra: any(named: 'extra')))
          .thenAnswer((_) async => null);
    });

    Future<void> pumpHomePage(WidgetTester tester) {
      return tester.pumpApp(
        InheritedGoRouter(goRouter: mockRouter, child: const HomePage()),
      );
    }

    testWidgets('renders headline text correctly', (tester) async {
      await pumpHomePage(tester);

      expect(find.text('Turn pool night into chaos'), findsOneWidget);
    });

    testWidgets('renders subtext with textSecondary color', (tester) async {
      await pumpHomePage(tester);

      final subtextFinder = find.text(
        'Grab friends. Find a pool table. Let the chaos begin.',
      );
      expect(subtextFinder, findsOneWidget);

      final text = tester.widget<Text>(subtextFinder);
      expect(text.style?.color, equals(RackUpColors.textSecondary));
    });

    testWidgets('Create Room button is visible and tappable', (tester) async {
      await pumpHomePage(tester);

      final buttonFinder = find.text('Create Room');
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      verify(
        () => mockRouter.push<Object?>('/create', extra: any(named: 'extra')),
      ).called(1);
    });

    testWidgets('Join Room button is visible and tappable', (tester) async {
      await pumpHomePage(tester);

      final buttonFinder = find.text('Join Room');
      expect(buttonFinder, findsOneWidget);

      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      verify(
        () => mockRouter.push<Object?>('/join', extra: any(named: 'extra')),
      ).called(1);
    });

    testWidgets('applies design system tokens', (tester) async {
      await pumpHomePage(tester);

      // Headline uses Oswald (display font family)
      final headline = tester.widget<Text>(
        find.text('Turn pool night into chaos'),
      );
      expect(headline.style?.fontFamily, equals(RackUpFontFamilies.display));
      expect(headline.style?.fontWeight, equals(FontWeight.w700));

      // Create Room button text uses display font
      final createText = tester.widget<Text>(find.text('Create Room'));
      expect(
        createText.style?.fontFamily,
        equals(RackUpFontFamilies.display),
      );
      expect(createText.style?.fontWeight, equals(FontWeight.w700));

      // Join Room button text uses display font
      final joinText = tester.widget<Text>(find.text('Join Room'));
      expect(joinText.style?.fontFamily, equals(RackUpFontFamilies.display));
      expect(joinText.style?.fontWeight, equals(FontWeight.w700));
    });

    testWidgets('buttons have correct minimum height', (tester) async {
      await pumpHomePage(tester);

      // Find the SizedBox wrapping each button (64dp height)
      final sizedBoxes = tester.widgetList<SizedBox>(
        find.byWidgetPredicate(
          (widget) =>
              widget is SizedBox &&
              widget.height == RackUpSpacing.primaryButtonHeight,
        ),
      );
      // Two buttons — Create Room and Join Room
      expect(sizedBoxes.length, equals(2));
    });

    testWidgets('buttons navigate to correct routes', (tester) async {
      await pumpHomePage(tester);

      // Tap Create Room
      await tester.tap(find.text('Create Room'));
      await tester.pumpAndSettle();
      verify(
        () => mockRouter.push<Object?>('/create', extra: any(named: 'extra')),
      ).called(1);

      // Tap Join Room
      await tester.tap(find.text('Join Room'));
      await tester.pumpAndSettle();
      verify(
        () => mockRouter.push<Object?>('/join', extra: any(named: 'extra')),
      ).called(1);
    });
  });
}
