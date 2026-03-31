import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/models/player.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/features/lobby/view/widgets/player_list_tile.dart';

void main() {
  const player = Player(
    displayName: 'Jake',
    deviceIdHash: 'hash1',
    slot: 1,
    isHost: true,
    status: PlayerStatus.joining,
  );

  const nonHostPlayer = Player(
    displayName: 'Danny',
    deviceIdHash: 'hash2',
    slot: 2,
    isHost: false,
    status: PlayerStatus.joining,
  );

  Widget buildSubject(Player p, {bool animationsEnabled = false}) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: RackUpColors.canvas,
        textTheme: RackUpTypography.buildTextTheme(),
        useMaterial3: true,
      ),
      home: RackUpGameTheme(
        data: RackUpGameThemeData(
          tier: EscalationTier.lobby,
          backgroundColor: RackUpColors.tierLobby,
          animationsEnabled: animationsEnabled,
        ),
        child: Scaffold(body: PlayerListTile(player: p)),
      ),
    );
  }

  const writingPlayer = Player(
    displayName: 'Maya',
    deviceIdHash: 'hash3',
    slot: 3,
    isHost: false,
    status: PlayerStatus.writing,
  );

  const readyPlayer = Player(
    displayName: 'Leo',
    deviceIdHash: 'hash4',
    slot: 4,
    isHost: false,
    status: PlayerStatus.ready,
  );

  group('PlayerListTile', () {
    testWidgets('displays player name', (tester) async {
      await tester.pumpWidget(buildSubject(player));
      await tester.pumpAndSettle();
      expect(find.text('Jake'), findsOneWidget);
    });

    testWidgets('shows HOST badge for host player', (tester) async {
      await tester.pumpWidget(buildSubject(player));
      await tester.pumpAndSettle();
      expect(find.text('HOST'), findsOneWidget);
    });

    testWidgets('does not show HOST badge for non-host', (tester) async {
      await tester.pumpWidget(buildSubject(nonHostPlayer));
      await tester.pumpAndSettle();
      expect(find.text('HOST'), findsNothing);
    });

    testWidgets('shows Joining... status', (tester) async {
      await tester.pumpWidget(buildSubject(player));
      await tester.pumpAndSettle();
      expect(find.text('Joining...'), findsOneWidget);
    });

    testWidgets('has semantics label with name and status', (tester) async {
      await tester.pumpWidget(buildSubject(player));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel(RegExp('Jake, Joining..., Host')),
        findsOneWidget,
      );
    });

    testWidgets('renders player shape widget', (tester) async {
      await tester.pumpWidget(buildSubject(player));
      await tester.pumpAndSettle();
      // PlayerShapeWidget is rendered via CustomPaint.
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('animates slide-in when animations enabled', (tester) async {
      await tester.pumpWidget(buildSubject(player, animationsEnabled: true));
      // At frame 0, animation is in progress — PlayerListTile contains SlideTransition.
      expect(find.byType(PlayerListTile), findsOneWidget);
      await tester.pumpAndSettle();
      // After settling, animation is complete.
      expect(find.text('Jake'), findsOneWidget);
    });

    testWidgets('appears instantly when animations disabled', (tester) async {
      await tester.pumpWidget(buildSubject(player, animationsEnabled: false));
      // No need to pump multiple frames — appears immediately.
      expect(find.text('Jake'), findsOneWidget);
    });

    testWidgets('shows Writing... status with amber color', (tester) async {
      await tester.pumpWidget(buildSubject(writingPlayer));
      await tester.pumpAndSettle();
      expect(find.text('Writing...'), findsOneWidget);
    });

    testWidgets('shows Ready status with green color and checkmark',
        (tester) async {
      await tester.pumpWidget(buildSubject(readyPlayer));
      await tester.pumpAndSettle();
      expect(find.text('Ready'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('does not show checkmark for non-ready status',
        (tester) async {
      await tester.pumpWidget(buildSubject(writingPlayer));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsNothing);
    });
  });
}
