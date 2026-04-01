import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/features/lobby/view/widgets/round_count_selector.dart';

void main() {
  Widget buildSubject({
    int selectedRoundCount = 10,
    ValueChanged<int>? onChanged,
  }) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: RackUpTypography.buildTextTheme(),
      ),
      home: Scaffold(
        body: RoundCountSelector(
          selectedRoundCount: selectedRoundCount,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    );
  }

  group('RoundCountSelector', () {
    testWidgets('default selection is 10', (tester) async {
      await tester.pumpWidget(buildSubject());

      // All three options are visible.
      expect(find.text('5'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);

      // Check that 10 has green background (selected).
      final tenButton = tester.widget<Material>(
        find.ancestor(
          of: find.text('10'),
          matching: find.byType(Material),
        ).first,
      );
      expect(tenButton.color, RackUpColors.madeGreen);
    });

    testWidgets('tap changes selection via callback', (tester) async {
      int? selectedValue;
      await tester.pumpWidget(
        buildSubject(onChanged: (v) => selectedValue = v),
      );

      await tester.tap(find.text('5'));
      expect(selectedValue, 5);

      await tester.tap(find.text('15'));
      expect(selectedValue, 15);
    });

    testWidgets('callbacks fire for each option', (tester) async {
      final values = <int>[];
      await tester.pumpWidget(
        buildSubject(onChanged: values.add),
      );

      await tester.tap(find.text('5'));
      await tester.tap(find.text('10'));
      await tester.tap(find.text('15'));

      expect(values, [5, 10, 15]);
    });
  });
}
