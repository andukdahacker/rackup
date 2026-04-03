import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/websocket/game_message_listener.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/core/websocket/web_socket_state.dart';
import 'package:rackup/features/game/bloc/event_feed_cubit.dart';
import 'package:rackup/features/game/bloc/event_feed_state.dart';
import 'package:rackup/features/game/bloc/game_bloc.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/game_state.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_state.dart';

class MockWebSocketCubit extends MockCubit<WebSocketState>
    implements WebSocketCubit {
  final StreamController<Message> _messageController =
      StreamController<Message>.broadcast();

  @override
  Stream<Message> get messages => _messageController.stream;

  void emitMessage(Message message) {
    _messageController.add(message);
  }

  void disposeController() {
    _messageController.close();
  }
}

void main() {
  group('GameMessageListener', () {
    late MockWebSocketCubit mockWsCubit;
    late GameBloc gameBloc;
    late LeaderboardBloc leaderboardBloc;
    late EventFeedCubit eventFeedCubit;

    setUp(() {
      mockWsCubit = MockWebSocketCubit();
      gameBloc = GameBloc();
      leaderboardBloc = LeaderboardBloc();
      eventFeedCubit = EventFeedCubit();
    });

    tearDown(() {
      eventFeedCubit.close();
      leaderboardBloc.close();
      gameBloc.close();
      mockWsCubit.disposeController();
    });

    test('gameInitialized message dispatches GameInitialized event',
        () async {
      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
        leaderboardBloc: leaderboardBloc,
        eventFeedCubit: eventFeedCubit,
        localDeviceIdHash: 'local-hash',
      );

      mockWsCubit.emitMessage(Message(
        action: 'game.initialized',
        payload: {
          'roundCount': 10,
          'refereeDeviceIdHash': 'ref-hash',
          'turnOrder': ['hash-a', 'hash-b'],
          'currentShooterDeviceIdHash': 'hash-a',
          'players': [
            {
              'deviceIdHash': 'hash-a',
              'displayName': 'Alice',
              'slot': 1,
              'score': 0,
              'streak': 0,
              'isReferee': false,
            },
            {
              'deviceIdHash': 'hash-b',
              'displayName': 'Bob',
              'slot': 2,
              'score': 0,
              'streak': 0,
              'isReferee': true,
            },
          ],
        },
      ));

      // Allow the stream event to propagate.
      await Future<void>.delayed(Duration.zero);

      expect(gameBloc.state, isA<GameActive>());
      final state = gameBloc.state as GameActive;
      expect(state.roundCount, 10);
      expect(state.refereeDeviceIdHash, 'ref-hash');
      expect(state.players.length, 2);

      listener.dispose();
    });

    test('gameTurnComplete message dispatches GameTurnCompleted event',
        () async {
      // First initialize the game.
      gameBloc.add(const GameInitialized(
        roundCount: 10,
        refereeDeviceIdHash: 'ref-hash',
        turnOrder: ['hash-a', 'hash-b'],
        currentShooterDeviceIdHash: 'hash-a',
        players: [],
      ));
      await Future<void>.delayed(Duration.zero);

      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
        leaderboardBloc: leaderboardBloc,
        eventFeedCubit: eventFeedCubit,
        localDeviceIdHash: 'local-hash',
      );

      mockWsCubit.emitMessage(Message(
        action: 'game.turn_complete',
        payload: {
          'shooterHash': 'hash-a',
          'result': 'made',
          'pointsAwarded': 3,
          'newScore': 3,
          'newStreak': 1,
          'currentShooterHash': 'hash-b',
          'currentRound': 1,
          'isGameOver': false,
          'streakLabel': '',
          'streakMilestone': false,
          'leaderboard': [
            {
              'deviceIdHash': 'hash-a',
              'score': 3,
              'streak': 1,
              'rank': 1,
              'rankChanged': false,
              'displayName': '',
              'streakLabel': '',
            },
            {
              'deviceIdHash': 'hash-b',
              'score': 0,
              'streak': 0,
              'rank': 2,
              'rankChanged': false,
              'displayName': '',
              'streakLabel': '',
            },
          ],
          'cascadeProfile': 'routine',
        },
      ));

      await Future<void>.delayed(Duration.zero);

      final state = gameBloc.state as GameActive;
      expect(state.currentShooterDeviceIdHash, 'hash-b');

      // Verify leaderboard bloc was updated.
      expect(leaderboardBloc.state, isA<LeaderboardActive>());
      final lbState = leaderboardBloc.state as LeaderboardActive;
      expect(lbState.entries.length, 2);
      expect(lbState.entries.first.deviceIdHash, 'hash-a');

      listener.dispose();
    });

    test(
        'gameTurnComplete with streak milestone dispatches correct data',
        () async {
      gameBloc.add(const GameInitialized(
        roundCount: 10,
        refereeDeviceIdHash: 'ref-hash',
        turnOrder: ['hash-a', 'hash-b'],
        currentShooterDeviceIdHash: 'hash-a',
        players: [],
      ));
      await Future<void>.delayed(Duration.zero);

      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
        leaderboardBloc: leaderboardBloc,
        eventFeedCubit: eventFeedCubit,
        localDeviceIdHash: 'local-hash',
      );

      mockWsCubit.emitMessage(Message(
        action: 'game.turn_complete',
        payload: {
          'shooterHash': 'hash-a',
          'result': 'made',
          'pointsAwarded': 4,
          'newScore': 7,
          'newStreak': 2,
          'currentShooterHash': 'hash-b',
          'currentRound': 1,
          'isGameOver': false,
          'streakLabel': 'warming_up',
          'streakMilestone': true,
          'leaderboard': [
            {
              'deviceIdHash': 'hash-a',
              'score': 7,
              'streak': 2,
              'rank': 1,
              'rankChanged': false,
              'displayName': '',
              'streakLabel': '',
            },
          ],
          'cascadeProfile': 'streak_milestone',
        },
      ));

      await Future<void>.delayed(Duration.zero);

      final lbState = leaderboardBloc.state as LeaderboardActive;
      expect(lbState.entries.first.streak, 2);

      listener.dispose();
    });

    test('malformed gameTurnComplete payload is dropped gracefully',
        () async {
      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
        leaderboardBloc: leaderboardBloc,
        eventFeedCubit: eventFeedCubit,
        localDeviceIdHash: 'local-hash',
      );

      // Send malformed payload.
      mockWsCubit.emitMessage(Message(
        action: 'game.turn_complete',
        payload: {'invalid': true},
      ));

      await Future<void>.delayed(Duration.zero);

      // State should still be initial (not crash).
      expect(gameBloc.state, isA<GameInitial>());

      listener.dispose();
    });

    test('gameTurnComplete generates score event feed item for made shot',
        () async {
      gameBloc.add(const GameInitialized(
        roundCount: 10,
        refereeDeviceIdHash: 'ref-hash',
        turnOrder: ['hash-a'],
        currentShooterDeviceIdHash: 'hash-a',
        players: [],
      ));
      await Future<void>.delayed(Duration.zero);

      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
        leaderboardBloc: leaderboardBloc,
        eventFeedCubit: eventFeedCubit,
        localDeviceIdHash: 'local-hash',
      );

      mockWsCubit.emitMessage(Message(
        action: 'game.turn_complete',
        payload: {
          'shooterHash': 'hash-a',
          'result': 'made',
          'pointsAwarded': 3,
          'newScore': 3,
          'newStreak': 1,
          'currentShooterHash': 'hash-a',
          'currentRound': 1,
          'isGameOver': false,
          'leaderboard': [
            {
              'deviceIdHash': 'hash-a',
              'displayName': 'Alice',
              'score': 3,
              'streak': 1,
              'rank': 1,
              'streakLabel': '',
            },
          ],
          'cascadeProfile': 'routine',
        },
      ));

      await Future<void>.delayed(Duration.zero);

      expect(eventFeedCubit.state.events, hasLength(1));
      expect(eventFeedCubit.state.events.first.text, contains('Alice scored'));
      expect(eventFeedCubit.state.events.first.category,
          EventFeedCategory.score);

      listener.dispose();
    });

    test('gameTurnComplete generates missed event for missed shot', () async {
      gameBloc.add(const GameInitialized(
        roundCount: 10,
        refereeDeviceIdHash: 'ref-hash',
        turnOrder: ['hash-a'],
        currentShooterDeviceIdHash: 'hash-a',
        players: [],
      ));
      await Future<void>.delayed(Duration.zero);

      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
        leaderboardBloc: leaderboardBloc,
        eventFeedCubit: eventFeedCubit,
        localDeviceIdHash: 'local-hash',
      );

      mockWsCubit.emitMessage(Message(
        action: 'game.turn_complete',
        payload: {
          'shooterHash': 'hash-a',
          'result': 'missed',
          'pointsAwarded': 0,
          'newScore': 0,
          'newStreak': 0,
          'currentShooterHash': 'hash-a',
          'currentRound': 1,
          'isGameOver': false,
          'leaderboard': [
            {
              'deviceIdHash': 'hash-a',
              'displayName': 'Bob',
              'score': 0,
              'streak': 0,
              'rank': 1,
              'streakLabel': '',
            },
          ],
          'cascadeProfile': 'routine',
        },
      ));

      await Future<void>.delayed(Duration.zero);

      expect(eventFeedCubit.state.events.first.text, 'Bob missed');

      listener.dispose();
    });

    test('gameTurnComplete generates streak event on milestone', () async {
      gameBloc.add(const GameInitialized(
        roundCount: 10,
        refereeDeviceIdHash: 'ref-hash',
        turnOrder: ['hash-a'],
        currentShooterDeviceIdHash: 'hash-a',
        players: [],
      ));
      await Future<void>.delayed(Duration.zero);

      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
        leaderboardBloc: leaderboardBloc,
        eventFeedCubit: eventFeedCubit,
        localDeviceIdHash: 'local-hash',
      );

      mockWsCubit.emitMessage(Message(
        action: 'game.turn_complete',
        payload: {
          'shooterHash': 'hash-a',
          'result': 'made',
          'pointsAwarded': 4,
          'newScore': 7,
          'newStreak': 3,
          'currentShooterHash': 'hash-a',
          'currentRound': 1,
          'isGameOver': false,
          'streakLabel': 'on_fire',
          'streakMilestone': true,
          'leaderboard': [
            {
              'deviceIdHash': 'hash-a',
              'displayName': 'Alice',
              'score': 7,
              'streak': 3,
              'rank': 1,
              'streakLabel': 'on_fire',
            },
          ],
          'cascadeProfile': 'streak_milestone',
        },
      ));

      await Future<void>.delayed(Duration.zero);

      // Should have score + streak events.
      expect(eventFeedCubit.state.events.length, 2);
      final streakEvent = eventFeedCubit.state.events.first;
      expect(streakEvent.text, contains('ON FIRE'));
      expect(streakEvent.category, EventFeedCategory.streak);

      listener.dispose();
    });

    test('gameTurnComplete generates game over event', () async {
      gameBloc.add(const GameInitialized(
        roundCount: 10,
        refereeDeviceIdHash: 'ref-hash',
        turnOrder: ['hash-a'],
        currentShooterDeviceIdHash: 'hash-a',
        players: [],
      ));
      await Future<void>.delayed(Duration.zero);

      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
        leaderboardBloc: leaderboardBloc,
        eventFeedCubit: eventFeedCubit,
        localDeviceIdHash: 'local-hash',
      );

      mockWsCubit.emitMessage(Message(
        action: 'game.turn_complete',
        payload: {
          'shooterHash': 'hash-a',
          'result': 'made',
          'pointsAwarded': 3,
          'newScore': 30,
          'newStreak': 1,
          'currentShooterHash': 'hash-a',
          'currentRound': 10,
          'isGameOver': true,
          'leaderboard': [
            {
              'deviceIdHash': 'hash-a',
              'displayName': 'Alice',
              'score': 30,
              'streak': 1,
              'rank': 1,
              'streakLabel': '',
            },
          ],
          'cascadeProfile': 'routine',
        },
      ));

      await Future<void>.delayed(Duration.zero);

      // Should have score + game over events.
      expect(eventFeedCubit.state.events.length, 2);
      final gameOverEvent = eventFeedCubit.state.events.first;
      expect(gameOverEvent.text, 'GAME OVER');
      expect(gameOverEvent.category, EventFeedCategory.system);

      listener.dispose();
    });

    test('game.game_ended dispatches GameEndReceived', () async {
      gameBloc.add(const GameInitialized(
        roundCount: 10,
        refereeDeviceIdHash: 'ref-hash',
        turnOrder: ['hash-a'],
        currentShooterDeviceIdHash: 'hash-a',
        players: [],
      ));
      await Future<void>.delayed(Duration.zero);

      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
        leaderboardBloc: leaderboardBloc,
        eventFeedCubit: eventFeedCubit,
        localDeviceIdHash: 'local-hash',
      );

      mockWsCubit.emitMessage(const Message(
        action: 'game.game_ended',
        payload: {'gameOver': true},
      ));

      await Future<void>.delayed(Duration.zero);

      // GameEndReceived should transition GameActive to GameEnded.
      expect(gameBloc.state, isA<GameEnded>());

      listener.dispose();
    });

    test('recordThis dispatches RecordThisReceived when not target', () async {
      gameBloc.add(const GameInitialized(
        roundCount: 10,
        refereeDeviceIdHash: 'ref-hash',
        turnOrder: ['hash-a'],
        currentShooterDeviceIdHash: 'hash-a',
        players: [],
      ));
      await Future<void>.delayed(Duration.zero);

      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
        leaderboardBloc: leaderboardBloc,
        eventFeedCubit: eventFeedCubit,
        localDeviceIdHash: 'local-hash',
      );

      mockWsCubit.emitMessage(Message(
        action: 'game.turn_complete',
        payload: {
          'shooterHash': 'hash-a',
          'result': 'missed',
          'pointsAwarded': 0,
          'newScore': 0,
          'newStreak': 0,
          'currentShooterHash': 'hash-a',
          'currentRound': 3,
          'isGameOver': false,
          'leaderboard': [
            {
              'deviceIdHash': 'hash-a',
              'displayName': 'Alice',
              'score': 0,
              'streak': 0,
              'rank': 1,
              'streakLabel': '',
            },
          ],
          'cascadeProfile': 'record_this',
          'recordThis': true,
          'recordThisSubtext': "Alice's streak just got broken!",
          'recordThisTargetHash': 'hash-a',
        },
      ));

      await Future<void>.delayed(Duration.zero);

      final state = gameBloc.state as GameActive;
      expect(state.showRecordThis, isTrue);
      expect(state.recordThisSubtext, "Alice's streak just got broken!");

      listener.dispose();
    });

    test('recordThis NOT dispatched when local device is target', () async {
      gameBloc.add(const GameInitialized(
        roundCount: 10,
        refereeDeviceIdHash: 'ref-hash',
        turnOrder: ['hash-a'],
        currentShooterDeviceIdHash: 'hash-a',
        players: [],
      ));
      await Future<void>.delayed(Duration.zero);

      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
        leaderboardBloc: leaderboardBloc,
        eventFeedCubit: eventFeedCubit,
        localDeviceIdHash: 'hash-a', // matches target
      );

      mockWsCubit.emitMessage(Message(
        action: 'game.turn_complete',
        payload: {
          'shooterHash': 'hash-a',
          'result': 'missed',
          'pointsAwarded': 0,
          'newScore': 0,
          'newStreak': 0,
          'currentShooterHash': 'hash-a',
          'currentRound': 3,
          'isGameOver': false,
          'leaderboard': [
            {
              'deviceIdHash': 'hash-a',
              'displayName': 'Alice',
              'score': 0,
              'streak': 0,
              'rank': 1,
              'streakLabel': '',
            },
          ],
          'cascadeProfile': 'record_this',
          'recordThis': true,
          'recordThisSubtext': "Alice's streak just got broken!",
          'recordThisTargetHash': 'hash-a',
        },
      ));

      await Future<void>.delayed(Duration.zero);

      final state = gameBloc.state as GameActive;
      expect(state.showRecordThis, isFalse);

      listener.dispose();
    });

    test('recordThis NOT dispatched when isGameOver is true', () async {
      gameBloc.add(const GameInitialized(
        roundCount: 10,
        refereeDeviceIdHash: 'ref-hash',
        turnOrder: ['hash-a'],
        currentShooterDeviceIdHash: 'hash-a',
        players: [],
      ));
      await Future<void>.delayed(Duration.zero);

      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
        leaderboardBloc: leaderboardBloc,
        eventFeedCubit: eventFeedCubit,
        localDeviceIdHash: 'local-hash',
      );

      mockWsCubit.emitMessage(Message(
        action: 'game.turn_complete',
        payload: {
          'shooterHash': 'hash-a',
          'result': 'missed',
          'pointsAwarded': 0,
          'newScore': 0,
          'newStreak': 0,
          'currentShooterHash': 'hash-a',
          'currentRound': 10,
          'isGameOver': true,
          'leaderboard': [
            {
              'deviceIdHash': 'hash-a',
              'displayName': 'Alice',
              'score': 0,
              'streak': 0,
              'rank': 1,
              'streakLabel': '',
            },
          ],
          'cascadeProfile': 'record_this',
          'recordThis': true,
          'recordThisSubtext': "Alice's streak just got broken!",
          'recordThisTargetHash': 'hash-a',
        },
      ));

      await Future<void>.delayed(Duration.zero);

      // Should be GameEnded, not showing record this.
      expect(gameBloc.state, isA<GameEnded>());

      listener.dispose();
    });

    test('recordThis event feed excluded for target player', () async {
      gameBloc.add(const GameInitialized(
        roundCount: 10,
        refereeDeviceIdHash: 'ref-hash',
        turnOrder: ['hash-a'],
        currentShooterDeviceIdHash: 'hash-a',
        players: [],
      ));
      await Future<void>.delayed(Duration.zero);

      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
        leaderboardBloc: leaderboardBloc,
        eventFeedCubit: eventFeedCubit,
        localDeviceIdHash: 'hash-a', // matches target
      );

      mockWsCubit.emitMessage(Message(
        action: 'game.turn_complete',
        payload: {
          'shooterHash': 'hash-a',
          'result': 'missed',
          'pointsAwarded': 0,
          'newScore': 0,
          'newStreak': 0,
          'currentShooterHash': 'hash-a',
          'currentRound': 3,
          'isGameOver': false,
          'leaderboard': [
            {
              'deviceIdHash': 'hash-a',
              'displayName': 'Alice',
              'score': 0,
              'streak': 0,
              'rank': 1,
              'streakLabel': '',
            },
          ],
          'cascadeProfile': 'record_this',
          'recordThis': true,
          'recordThisSubtext': "Alice's streak just got broken!",
          'recordThisTargetHash': 'hash-a',
        },
      ));

      await Future<void>.delayed(Duration.zero);

      // Only score event — no recordThis event for target player.
      expect(eventFeedCubit.state.events.length, 1);
      expect(eventFeedCubit.state.events.first.text, 'Alice missed');

      listener.dispose();
    });

    test('recordThis event feed excluded when isGameOver', () async {
      gameBloc.add(const GameInitialized(
        roundCount: 10,
        refereeDeviceIdHash: 'ref-hash',
        turnOrder: ['hash-a'],
        currentShooterDeviceIdHash: 'hash-a',
        players: [],
      ));
      await Future<void>.delayed(Duration.zero);

      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
        leaderboardBloc: leaderboardBloc,
        eventFeedCubit: eventFeedCubit,
        localDeviceIdHash: 'local-hash',
      );

      mockWsCubit.emitMessage(Message(
        action: 'game.turn_complete',
        payload: {
          'shooterHash': 'hash-a',
          'result': 'missed',
          'pointsAwarded': 0,
          'newScore': 0,
          'newStreak': 0,
          'currentShooterHash': 'hash-a',
          'currentRound': 10,
          'isGameOver': true,
          'leaderboard': [
            {
              'deviceIdHash': 'hash-a',
              'displayName': 'Alice',
              'score': 0,
              'streak': 0,
              'rank': 1,
              'streakLabel': '',
            },
          ],
          'cascadeProfile': 'record_this',
          'recordThis': true,
          'recordThisSubtext': "Alice's streak just got broken!",
          'recordThisTargetHash': 'hash-a',
        },
      ));

      await Future<void>.delayed(Duration.zero);

      // Score event + game over event — no recordThis event.
      expect(eventFeedCubit.state.events.length, 2);
      final texts = eventFeedCubit.state.events.map((e) => e.text).toList();
      expect(texts, isNot(contains(contains('streak just got broken'))));

      listener.dispose();
    });

    test('recordThis adds event feed entry', () async {
      gameBloc.add(const GameInitialized(
        roundCount: 10,
        refereeDeviceIdHash: 'ref-hash',
        turnOrder: ['hash-a'],
        currentShooterDeviceIdHash: 'hash-a',
        players: [],
      ));
      await Future<void>.delayed(Duration.zero);

      final listener = GameMessageListener(
        webSocketCubit: mockWsCubit,
        gameBloc: gameBloc,
        leaderboardBloc: leaderboardBloc,
        eventFeedCubit: eventFeedCubit,
        localDeviceIdHash: 'local-hash',
      );

      mockWsCubit.emitMessage(Message(
        action: 'game.turn_complete',
        payload: {
          'shooterHash': 'hash-a',
          'result': 'missed',
          'pointsAwarded': 0,
          'newScore': 0,
          'newStreak': 0,
          'currentShooterHash': 'hash-a',
          'currentRound': 3,
          'isGameOver': false,
          'leaderboard': [
            {
              'deviceIdHash': 'hash-a',
              'displayName': 'Alice',
              'score': 0,
              'streak': 0,
              'rank': 1,
              'streakLabel': '',
            },
          ],
          'cascadeProfile': 'record_this',
          'recordThis': true,
          'recordThisSubtext': "Alice's streak just got broken!",
          'recordThisTargetHash': 'hash-a',
        },
      ));

      await Future<void>.delayed(Duration.zero);

      // Should have recordThis event + score event (newest first).
      expect(eventFeedCubit.state.events.length, 2);
      // Score event is newest (added last) → index 0.
      // RecordThis event is older → index 1.
      final recordEvent = eventFeedCubit.state.events[1];
      expect(recordEvent.text, contains("Alice's streak just got broken!"));
      expect(recordEvent.category, EventFeedCategory.system);

      listener.dispose();
    });
  });
}
