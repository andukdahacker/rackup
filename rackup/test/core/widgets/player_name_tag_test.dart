import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/widgets/player_name_tag.dart';

import '../../helpers/helpers.dart';

void main() {
  group('PlayerNameTag', () {
    testWidgets('compact variant renders name and shape', (tester) async {
      await tester.pumpApp(
        const PlayerNameTag(
          displayName: 'Alice',
          slot: 1,
          size: PlayerNameTagSize.compact,
        ),
      );

      expect(find.text('Alice'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Alice, coral circle',
        ),
        findsOneWidget,
      );
    });

    testWidgets('standard variant renders name and shape', (tester) async {
      await tester.pumpApp(
        const PlayerNameTag(
          displayName: 'Bob',
          slot: 2,
          size: PlayerNameTagSize.standard,
        ),
      );

      expect(find.text('Bob'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Bob, cyan square',
        ),
        findsOneWidget,
      );
    });

    testWidgets('large variant renders name and shape', (tester) async {
      await tester.pumpApp(
        const PlayerNameTag(
          displayName: 'Carol',
          slot: 3,
          size: PlayerNameTagSize.large,
        ),
      );

      expect(find.text('Carol'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == 'Carol, amber triangle',
        ),
        findsOneWidget,
      );
    });
  });
}
