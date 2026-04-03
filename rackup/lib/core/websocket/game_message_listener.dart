import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rackup/core/protocol/actions.dart';
import 'package:rackup/core/protocol/mapper.dart';
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/features/game/bloc/event_feed_cubit.dart';
import 'package:rackup/features/game/bloc/event_feed_state.dart';
import 'package:rackup/features/game/bloc/game_bloc.dart';
import 'package:rackup/features/game/bloc/game_event.dart';
import 'package:rackup/features/game/bloc/leaderboard_bloc.dart';
import 'package:rackup/features/game/bloc/leaderboard_event.dart';

/// Listens to WebSocket messages and dispatches game events to [GameBloc]
/// and [LeaderboardBloc].
///
/// Subscribes to [WebSocketCubit.messages] and routes game-related actions.
/// Created at the shell level so it receives `game.*` messages even during
/// the lobby→game navigation transition.
class GameMessageListener {
  GameMessageListener({
    required WebSocketCubit webSocketCubit,
    required GameBloc gameBloc,
    required LeaderboardBloc leaderboardBloc,
    required EventFeedCubit eventFeedCubit,
    required String localDeviceIdHash,
  }) : _subscription = webSocketCubit.messages.listen((message) {
          _handleMessage(
            message,
            gameBloc,
            leaderboardBloc,
            eventFeedCubit,
            localDeviceIdHash,
          );
        });

  final StreamSubscription<Message> _subscription;

  static void _handleMessage(
    Message message,
    GameBloc gameBloc,
    LeaderboardBloc leaderboardBloc,
    EventFeedCubit eventFeedCubit,
    String localDeviceIdHash,
  ) {
    try {
      switch (message.action) {
        case Actions.gameInitialized:
          final payload =
              GameInitializedPayload.fromJson(message.payload);
          final players = payload.players.map(mapToGamePlayer).toList();
          gameBloc.add(GameInitialized(
            roundCount: payload.roundCount,
            refereeDeviceIdHash: payload.refereeDeviceIdHash,
            turnOrder: payload.turnOrder,
            currentShooterDeviceIdHash:
                payload.currentShooterDeviceIdHash,
            players: players,
          ));

        case Actions.gameTurnComplete:
          final payload =
              TurnCompletePayload.fromJson(message.payload);
          final leaderboardEntries =
              payload.leaderboard.map(mapToLeaderboardEntry).toList();

          gameBloc.add(GameTurnCompleted(
            shooterHash: payload.shooterHash,
            result: payload.result,
            pointsAwarded: payload.pointsAwarded,
            newScore: payload.newScore,
            newStreak: payload.newStreak,
            currentShooterHash: payload.currentShooterHash,
            currentRound: payload.currentRound,
            isGameOver: payload.isGameOver,
            streakLabel: payload.streakLabel,
            streakMilestone: payload.streakMilestone,
            leaderboard: leaderboardEntries,
            cascadeProfile: payload.cascadeProfile,
            isTriplePoints: payload.isTriplePoints,
          ));

          // Dispatch leaderboard update to LeaderboardBloc.
          leaderboardBloc.add(LeaderboardUpdated(
            entries: leaderboardEntries,
            shooterHash: payload.shooterHash,
            streakMilestone: payload.streakMilestone,
            cascadeProfile: payload.cascadeProfile,
          ));

          // Generate event feed items from turn result.
          _generateEventFeedItems(payload, eventFeedCubit, localDeviceIdHash);

          // Dispatch RECORD THIS if applicable.
          if (payload.recordThis &&
              localDeviceIdHash != payload.recordThisTargetHash &&
              !payload.isGameOver) {
            gameBloc.add(RecordThisReceived(
              subtext: payload.recordThisSubtext,
              targetHash: payload.recordThisTargetHash,
            ));
          }

        case Actions.gameEnded:
          // Safety net: server sends game.game_ended after game.turn_complete.
          // GameBloc may already be in GameEnded state from isGameOver flag.
          gameBloc.add(const GameEndReceived());

        default:
          break;
      }
    } on Object catch (e) {
      // Malformed game payloads are dropped with a debug log.
      assert(() {
        debugPrint('GameMessageListener: dropped malformed payload: $e');
        return true;
      }());
    }
  }

  /// Generates event feed items from a turn complete payload.
  static void _generateEventFeedItems(
    TurnCompletePayload payload,
    EventFeedCubit eventFeedCubit,
    String localDeviceIdHash,
  ) {
    final now = DateTime.now();

    // Resolve shooter display name from leaderboard.
    var shooterName = 'Player';
    for (final entry in payload.leaderboard) {
      if (entry.deviceIdHash == payload.shooterHash) {
        shooterName = entry.displayName;
        break;
      }
    }

    // 0. RECORD THIS event (before score event).
    // Exclude target player and game-over to match overlay filtering.
    if (payload.recordThis &&
        localDeviceIdHash != payload.recordThisTargetHash &&
        !payload.isGameOver) {
      eventFeedCubit.addEvent(EventFeedItem(
        id: 'recordthis-${now.microsecondsSinceEpoch}',
        text: '\u{1F4F7} ${payload.recordThisSubtext}',
        category: EventFeedCategory.system,
        timestamp: now,
      ));
    }

    // 1. Score event (always).
    if (payload.result == 'made') {
      final ptsText = payload.isTriplePoints
          ? '+${payload.pointsAwarded} (3X)'
          : '+${payload.pointsAwarded}';
      eventFeedCubit.addEvent(EventFeedItem(
        id: 'score-${now.microsecondsSinceEpoch}',
        text: '$shooterName scored $ptsText',
        category: EventFeedCategory.score,
        timestamp: now,
      ));
    } else {
      eventFeedCubit.addEvent(EventFeedItem(
        id: 'score-${now.microsecondsSinceEpoch}',
        text: '$shooterName missed',
        category: EventFeedCategory.score,
        timestamp: now,
      ));
    }

    // 2. Streak event (if milestone).
    if (payload.streakMilestone) {
      final streakText = switch (payload.streakLabel) {
        'warming_up' => '$shooterName is warming up',
        'on_fire' => '$shooterName is ON FIRE 🔥',
        'unstoppable' => '$shooterName is UNSTOPPABLE 💪',
        _ => '$shooterName is on a streak',
      };
      eventFeedCubit.addEvent(EventFeedItem(
        id: 'streak-${now.microsecondsSinceEpoch}',
        text: streakText,
        category: EventFeedCategory.streak,
        timestamp: now,
      ));
    }

    // 3. Triple points activated (if just activated this turn).
    if (payload.triplePointsActivated) {
      eventFeedCubit.addEvent(EventFeedItem(
        id: 'triple-${now.microsecondsSinceEpoch}',
        text: 'TRIPLE POINTS! All scores 3X',
        category: EventFeedCategory.system,
        timestamp: now,
      ));
    }

    // 4. Game over.
    if (payload.isGameOver) {
      eventFeedCubit.addEvent(EventFeedItem(
        id: 'gameover-${now.microsecondsSinceEpoch}',
        text: 'GAME OVER',
        category: EventFeedCategory.system,
        timestamp: now,
      ));
    }

    // Extension points for future event sources:
    // - Item deployments (Epic 5): EventFeedCategory.item
    // - Punishment reveals (Epic 4): EventFeedCategory.punishment
    // - Mission completions (Epic 6): EventFeedCategory.mission
  }

  /// Cancels the message subscription.
  void dispose() {
    _subscription.cancel();
  }
}
