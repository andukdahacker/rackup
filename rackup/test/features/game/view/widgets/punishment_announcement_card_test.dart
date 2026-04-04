import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/features/game/view/widgets/punishment_announcement_card.dart';

import '../../../../helpers/helpers.dart';

void main() {
  group('PunishmentAnnouncementCard', () {
    testWidgets('renders header, tier badge, punishment text, and Delivered button for mild tier',
        (tester) async {
      var delivered = false;
      await tester.pumpApp(
        PunishmentAnnouncementCard(
          punishment: const PunishmentPayload(
            text: 'Take a sip of water',
            tier: 'mild',
          ),
          onDelivered: () => delivered = true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('THE POOL GODS HAVE SPOKEN'), findsOneWidget);
      expect(find.text('MILD'), findsOneWidget);
      expect(find.text('Take a sip of water'), findsOneWidget);
      expect(find.text('PUNISHMENT DELIVERED'), findsOneWidget);

      // Verify mild badge has grey background.
      final badge = tester.widget<Container>(
        find.ancestor(
          of: find.text('MILD'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = badge.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFF616161));
    });

    testWidgets('renders medium tier with exclamation header and amber badge',
        (tester) async {
      await tester.pumpApp(
        PunishmentAnnouncementCard(
          punishment: const PunishmentPayload(
            text: 'Do 10 pushups',
            tier: 'medium',
          ),
          onDelivered: () {},
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('THE POOL GODS HAVE SPOKEN!'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget);

      final badge = tester.widget<Container>(
        find.ancestor(
          of: find.text('MEDIUM'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = badge.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFFF59E0B));
    });

    testWidgets('renders spicy tier with dramatic header and red badge',
        (tester) async {
      await tester.pumpApp(
        PunishmentAnnouncementCard(
          punishment: const PunishmentPayload(
            text: 'Sing a song',
            tier: 'spicy',
          ),
          onDelivered: () {},
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('THE POOL GODS DEMAND SACRIFICE'), findsOneWidget);
      expect(find.text('SPICY'), findsOneWidget);

      final badge = tester.widget<Container>(
        find.ancestor(
          of: find.text('SPICY'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = badge.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFFEF4444));
    });

    testWidgets('renders custom tier with default header and purple badge',
        (tester) async {
      await tester.pumpApp(
        PunishmentAnnouncementCard(
          punishment: const PunishmentPayload(
            text: 'Custom punishment',
            tier: 'custom',
          ),
          onDelivered: () {},
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('THE POOL GODS HAVE SPOKEN'), findsOneWidget);
      expect(find.text('CUSTOM'), findsOneWidget);

      final badge = tester.widget<Container>(
        find.ancestor(
          of: find.text('CUSTOM'),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = badge.decoration! as BoxDecoration;
      expect(decoration.color, const Color(0xFFA855F7));
    });

    testWidgets('spicy tier header uses gold-tinted color', (tester) async {
      await tester.pumpApp(
        PunishmentAnnouncementCard(
          punishment: const PunishmentPayload(
            text: 'Spicy punishment',
            tier: 'spicy',
          ),
          onDelivered: () {},
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final header = tester.widget<Text>(
        find.text('THE POOL GODS DEMAND SACRIFICE'),
      );
      expect(header.style!.color, const Color(0xFFFFE4B5));
    });

    testWidgets('mild tier header uses off-white color', (tester) async {
      await tester.pumpApp(
        PunishmentAnnouncementCard(
          punishment: const PunishmentPayload(
            text: 'Mild punishment',
            tier: 'mild',
          ),
          onDelivered: () {},
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final header = tester.widget<Text>(
        find.text('THE POOL GODS HAVE SPOKEN'),
      );
      expect(header.style!.color, const Color(0xFFF0EDF6));
    });

    testWidgets('tapping Delivered button calls onDelivered callback',
        (tester) async {
      var delivered = false;
      await tester.pumpApp(
        PunishmentAnnouncementCard(
          punishment: const PunishmentPayload(
            text: 'Take a sip',
            tier: 'mild',
          ),
          onDelivered: () => delivered = true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('PUNISHMENT DELIVERED'));
      expect(delivered, isTrue);
    });

    testWidgets('The Reveal animation controller fires on mount',
        (tester) async {
      await tester.pumpApp(
        PunishmentAnnouncementCard(
          punishment: const PunishmentPayload(
            text: 'Test animation',
            tier: 'mild',
          ),
          onDelivered: () {},
        ),
      );
      // Pump initial frame — animation starts.
      await tester.pump();

      // Find the Transform.scale from AnimatedBuilder.
      final transform = tester.widget<Transform>(
        find.byType(Transform).first,
      );
      // At frame 0, scale should be 1.0 (beginning of animation).
      expect(transform.transform.getMaxScaleOnAxis(), closeTo(1.0, 0.05));

      // Pump through full animation (400ms) — scale returns to ~1.0 with easeOutBack overshoot.
      await tester.pump(const Duration(milliseconds: 500));
      final endTransform = tester.widget<Transform>(
        find.byType(Transform).first,
      );
      expect(
        endTransform.transform.getMaxScaleOnAxis(),
        closeTo(1.0, 0.05),
      );
    });

    testWidgets('uses smaller font for long punishment text (>80 chars)',
        (tester) async {
      final longText = 'A' * 81;
      await tester.pumpApp(
        PunishmentAnnouncementCard(
          punishment: PunishmentPayload(
            text: longText,
            tier: 'mild',
          ),
          onDelivered: () {},
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final textWidget = tester.widget<Text>(find.text(longText));
      expect(textWidget.style!.fontSize, 18);
    });

    testWidgets('uses larger font for short punishment text (<=80 chars)',
        (tester) async {
      const shortText = 'Take a sip';
      await tester.pumpApp(
        PunishmentAnnouncementCard(
          punishment: const PunishmentPayload(
            text: shortText,
            tier: 'mild',
          ),
          onDelivered: () {},
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final textWidget = tester.widget<Text>(find.text(shortText));
      expect(textWidget.style!.fontSize, 24);
    });
  });
}
