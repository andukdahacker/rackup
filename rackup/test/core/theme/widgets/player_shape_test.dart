import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/theme/player_identity.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/widgets/player_shape.dart';

void main() {
  group('PlayerShapeWidget', () {
    testWidgets('renders without error for all shapes', (tester) async {
      for (final shape in PlayerShape.values) {
        await tester.pumpWidget(
          Center(
            child: PlayerShapeWidget(
              shape: shape,
              color: RackUpColors.playerCoral,
            ),
          ),
        );
        expect(find.byType(PlayerShapeWidget), findsOneWidget);
        expect(find.byType(CustomPaint), findsOneWidget);
      }
    });

    testWidgets('uses specified size', (tester) async {
      await tester.pumpWidget(
        const Center(
          child: PlayerShapeWidget(
            shape: PlayerShape.circle,
            color: RackUpColors.playerCyan,
            size: 48,
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byType(CustomPaint),
      );
      expect(customPaint.size, const Size(48, 48));
    });

    testWidgets('default size is 24', (tester) async {
      await tester.pumpWidget(
        const Center(
          child: PlayerShapeWidget(
            shape: PlayerShape.star,
            color: RackUpColors.playerLime,
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.byType(CustomPaint),
      );
      expect(customPaint.size, const Size(24, 24));
    });
  });
}
