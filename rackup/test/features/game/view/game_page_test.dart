import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/services/device_identity_service.dart';
import 'package:rackup/core/theme/game_theme.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/features/game/bloc/game_bloc.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/game_state.dart';
import 'package:rackup/features/game/view/game_page.dart';
import 'package:rackup/l10n/l10n.dart';

class MockGameBloc extends MockBloc<GameEvent, GameState>
    implements GameBloc {}

class MockDeviceIdentityService extends Mock
    implements DeviceIdentityService {}

const _testPlayers = [
  GamePlayer(
    deviceIdHash: 'hash-a',
    displayName: 'Alice',
    slot: 1,
    score: 0,
    streak: 0,
    isReferee: false,
  ),
  GamePlayer(
    deviceIdHash: 'hash-b',
    displayName: 'Bob',
    slot: 2,
    score: 0,
    streak: 0,
    isReferee: true,
  ),
];

const _gameActiveState = GameActive(
  roundCount: 10,
  currentRound: 1,
  refereeDeviceIdHash: 'hash-b',
  currentShooterDeviceIdHash: 'hash-a',
  turnOrder: ['hash-a', 'hash-b'],
  players: _testPlayers,
  tier: EscalationTier.mild,
);

Widget _buildTestWidget({
  required GameBloc gameBloc,
  required DeviceIdentityService deviceIdentityService,
}) {
  return MaterialApp(
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: RackUpColors.canvas,
      colorScheme: const ColorScheme.dark(
        surface: RackUpColors.canvas,
        primary: RackUpColors.itemBlue,
        secondary: RackUpColors.missionPurple,
        error: RackUpColors.missedRed,
      ),
      textTheme: RackUpTypography.buildTextTheme(),
      useMaterial3: true,
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DeviceIdentityService>.value(
          value: deviceIdentityService,
        ),
      ],
      child: BlocProvider<GameBloc>.value(
        value: gameBloc,
        child: Builder(
          builder: (context) {
            return RackUpGameTheme(
              data: RackUpGameThemeData(
                tier: EscalationTier.mild,
                backgroundColor: RackUpColors.tierMild,
                animationsEnabled: false,
              ),
              child: const MediaQuery(
                data: MediaQueryData(disableAnimations: true),
                child: GamePage(),
              ),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  late MockGameBloc mockGameBloc;
  late MockDeviceIdentityService mockDeviceIdentity;

  setUp(() {
    mockGameBloc = MockGameBloc();
    mockDeviceIdentity = MockDeviceIdentityService();
  });

  group('GamePage', () {
    testWidgets('shows overlay for referee', (tester) async {
      // Device is the referee (hash-b).
      when(() => mockDeviceIdentity.getHashedDeviceId())
          .thenReturn('hash-b');
      when(() => mockGameBloc.state).thenReturn(_gameActiveState);

      await tester.pumpWidget(_buildTestWidget(
        gameBloc: mockGameBloc,
        deviceIdentityService: mockDeviceIdentity,
      ));

      // Overlay should be visible.
      expect(find.text("YOU'RE THE REFEREE NOW"), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('shows player screen for non-referee', (tester) async {
      // Device is NOT the referee (hash-a).
      when(() => mockDeviceIdentity.getHashedDeviceId())
          .thenReturn('hash-a');
      when(() => mockGameBloc.state).thenReturn(_gameActiveState);

      await tester.pumpWidget(_buildTestWidget(
        gameBloc: mockGameBloc,
        deviceIdentityService: mockDeviceIdentity,
      ));

      // Player screen should show.
      expect(find.text('Game started!'), findsOneWidget);
      expect(find.text('No items'), findsOneWidget);
      // No overlay.
      expect(find.text("YOU'RE THE REFEREE NOW"), findsNothing);
    });

    testWidgets('disables back navigation', (tester) async {
      when(() => mockDeviceIdentity.getHashedDeviceId())
          .thenReturn('hash-a');
      when(() => mockGameBloc.state).thenReturn(_gameActiveState);

      await tester.pumpWidget(_buildTestWidget(
        gameBloc: mockGameBloc,
        deviceIdentityService: mockDeviceIdentity,
      ));

      // Verify PopScope prevents back navigation.
      final popScope = tester.widget<PopScope>(find.byType(PopScope));
      expect(popScope.canPop, isFalse);
    });
  });
}
