// SYNC WITH: rackup-server/internal/protocol/messages.go
import 'dart:convert';

/// Wire format for all WebSocket communication.
/// All messages use: {"action": "namespace.verb_noun", "payload": {...}}
class Message {
  /// Creates a [Message].
  const Message({required this.action, required this.payload});

  /// Creates a [Message] from a JSON map.
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      action: json['action'] as String,
      payload: json['payload'] as Map<String, dynamic>,
    );
  }

  /// Creates a [Message] from a raw JSON string.
  factory Message.fromRawJson(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return Message.fromJson(json);
  }

  /// The action identifier (e.g., "lobby.player_joined").
  final String action;

  /// The payload data.
  final Map<String, dynamic> payload;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {'action': action, 'payload': payload};

  /// Converts to raw JSON string.
  String toRawJson() => jsonEncode(toJson());
}

/// Response from POST /rooms — room creation.
class CreateRoomResponse {
  /// Creates a [CreateRoomResponse].
  const CreateRoomResponse({required this.roomCode, required this.jwt});

  /// Creates from JSON map.
  factory CreateRoomResponse.fromJson(Map<String, dynamic> json) {
    final roomCode = json['roomCode'];
    final jwt = json['jwt'];
    if (roomCode is! String || jwt is! String) {
      throw const FormatException(
        'Invalid CreateRoomResponse: missing roomCode or jwt',
      );
    }
    return CreateRoomResponse(roomCode: roomCode, jwt: jwt);
  }

  /// The 4-character room code.
  final String roomCode;

  /// The JWT for WebSocket authentication.
  final String jwt;
}

/// Response from POST /rooms/:code/join — room joining.
/// SYNC WITH: rackup-server/internal/handler/http.go (joinRoomResponse)
class JoinRoomResponse {
  /// Creates a [JoinRoomResponse].
  const JoinRoomResponse({required this.jwt});

  /// Creates from JSON map.
  factory JoinRoomResponse.fromJson(Map<String, dynamic> json) {
    final jwt = json['jwt'];
    if (jwt is! String) {
      throw const FormatException('Invalid JoinRoomResponse: missing jwt');
    }
    return JoinRoomResponse(jwt: jwt);
  }

  /// The JWT for WebSocket authentication.
  final String jwt;
}

/// Wire payload for a single player in lobby messages.
class LobbyPlayerPayload {
  /// Creates a [LobbyPlayerPayload].
  const LobbyPlayerPayload({
    required this.displayName,
    required this.deviceIdHash,
    required this.slot,
    required this.isHost,
    required this.status,
  });

  /// Creates from JSON map.
  factory LobbyPlayerPayload.fromJson(Map<String, dynamic> json) {
    return LobbyPlayerPayload(
      displayName: json['displayName'] as String,
      deviceIdHash: json['deviceIdHash'] as String,
      slot: json['slot'] as int,
      isHost: json['isHost'] as bool,
      status: json['status'] as String,
    );
  }

  /// The player's display name.
  final String displayName;

  /// SHA-256 hash of the player's device ID.
  final String deviceIdHash;

  /// 1-based slot index (1–8).
  final int slot;

  /// Whether this player is the host.
  final bool isHost;

  /// Status string (e.g., "joining", "writing", "ready").
  final String status;
}

/// Wire payload for lobby.room_state — full room snapshot.
class LobbyRoomStatePayload {
  /// Creates a [LobbyRoomStatePayload].
  const LobbyRoomStatePayload({
    required this.roomCode,
    required this.hostDeviceIdHash,
    required this.players,
    this.allReadyOrTimedOut = false,
  });

  /// Creates from JSON map.
  factory LobbyRoomStatePayload.fromJson(Map<String, dynamic> json) {
    final playersList = (json['players'] as List<dynamic>)
        .map(
          (e) => LobbyPlayerPayload.fromJson(e as Map<String, dynamic>),
        )
        .toList();
    return LobbyRoomStatePayload(
      roomCode: json['roomCode'] as String,
      hostDeviceIdHash: json['hostDeviceIdHash'] as String,
      players: playersList,
      allReadyOrTimedOut: json['allReadyOrTimedOut'] as bool? ?? false,
    );
  }

  /// The room code.
  final String roomCode;

  /// The host's device ID hash.
  final String hostDeviceIdHash;

  /// All players currently in the room.
  final List<LobbyPlayerPayload> players;

  /// Whether all punishments are submitted or the timeout has elapsed.
  final bool allReadyOrTimedOut;
}

/// Wire payload for client→server punishment submission.
class PunishmentSubmitPayload {
  /// Creates a [PunishmentSubmitPayload].
  const PunishmentSubmitPayload({required this.text});

  /// Creates from JSON map.
  factory PunishmentSubmitPayload.fromJson(Map<String, dynamic> json) {
    return PunishmentSubmitPayload(text: json['text'] as String);
  }

  /// The punishment text.
  final String text;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {'text': text};
}

/// Wire payload for server→client player status change broadcast.
class PlayerStatusChangedPayload {
  /// Creates a [PlayerStatusChangedPayload].
  const PlayerStatusChangedPayload({
    required this.deviceIdHash,
    required this.status,
  });

  /// Creates from JSON map.
  factory PlayerStatusChangedPayload.fromJson(Map<String, dynamic> json) {
    return PlayerStatusChangedPayload(
      deviceIdHash: json['deviceIdHash'] as String,
      status: json['status'] as String,
    );
  }

  /// SHA-256 hash of the player's device ID.
  final String deviceIdHash;

  /// Status string (e.g., "writing", "ready").
  final String status;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {
        'deviceIdHash': deviceIdHash,
        'status': status,
      };
}

/// Wire payload for client→server game start request.
class StartGamePayload {
  /// Creates a [StartGamePayload].
  const StartGamePayload({required this.roundCount});

  /// The number of rounds (5, 10, or 15).
  final int roundCount;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {'roundCount': roundCount};
}

/// Wire payload for server→client game started broadcast.
class GameStartedPayload {
  /// Creates a [GameStartedPayload].
  const GameStartedPayload({required this.roundCount});

  /// Creates from JSON map.
  factory GameStartedPayload.fromJson(Map<String, dynamic> json) {
    return GameStartedPayload(
      roundCount: (json['roundCount'] as num?)?.toInt() ?? 10,
    );
  }

  /// The number of rounds.
  final int roundCount;
}

/// Wire payload for a single player in game initialization messages.
class GamePlayerPayload {
  /// Creates a [GamePlayerPayload].
  const GamePlayerPayload({
    required this.deviceIdHash,
    required this.displayName,
    required this.slot,
    required this.score,
    required this.streak,
    required this.isReferee,
  });

  /// Creates from JSON map.
  factory GamePlayerPayload.fromJson(Map<String, dynamic> json) {
    return GamePlayerPayload(
      deviceIdHash: json['deviceIdHash'] as String,
      displayName: json['displayName'] as String,
      slot: json['slot'] as int,
      score: json['score'] as int,
      streak: json['streak'] as int,
      isReferee: json['isReferee'] as bool,
    );
  }

  /// SHA-256 hash of the player's device ID.
  final String deviceIdHash;

  /// The player's display name.
  final String displayName;

  /// 1-based slot index (1–8).
  final int slot;

  /// The player's current score.
  final int score;

  /// The player's current streak.
  final int streak;

  /// Whether this player is the referee.
  final bool isReferee;
}

/// Wire payload for server→client game.initialized broadcast.
class GameInitializedPayload {
  /// Creates a [GameInitializedPayload].
  const GameInitializedPayload({
    required this.roundCount,
    required this.refereeDeviceIdHash,
    required this.turnOrder,
    required this.currentShooterDeviceIdHash,
    required this.players,
  });

  /// Creates from JSON map.
  factory GameInitializedPayload.fromJson(Map<String, dynamic> json) {
    final playersList = (json['players'] as List<dynamic>)
        .map((e) => GamePlayerPayload.fromJson(e as Map<String, dynamic>))
        .toList();
    return GameInitializedPayload(
      roundCount: json['roundCount'] as int,
      refereeDeviceIdHash: json['refereeDeviceIdHash'] as String,
      turnOrder:
          (json['turnOrder'] as List<dynamic>).cast<String>(),
      currentShooterDeviceIdHash:
          json['currentShooterDeviceIdHash'] as String,
      players: playersList,
    );
  }

  /// The number of rounds.
  final int roundCount;

  /// The referee's device ID hash.
  final String refereeDeviceIdHash;

  /// Device ID hashes in play order.
  final List<String> turnOrder;

  /// The current shooter's device ID hash.
  final String currentShooterDeviceIdHash;

  /// All players with their game state.
  final List<GamePlayerPayload> players;
}

/// Wire payload for client→server referee.confirm_shot.
/// SYNC WITH: rackup-server/internal/protocol/messages.go (ConfirmShotPayload)
class ConfirmShotPayload {
  /// Creates a [ConfirmShotPayload].
  const ConfirmShotPayload({required this.result});

  /// The shot result: "made" or "missed".
  final String result;

  /// Converts to JSON map.
  Map<String, dynamic> toJson() => {'result': result};
}

/// Nested punishment payload in turn_complete.
/// Null when no punishment is drawn (on MADE shots).
/// SYNC WITH: rackup-server/internal/protocol/messages.go (PunishmentPayload)
class PunishmentPayload {
  /// Creates a [PunishmentPayload].
  const PunishmentPayload({required this.text, required this.tier});

  /// Creates from JSON map.
  factory PunishmentPayload.fromJson(Map<String, dynamic> json) {
    return PunishmentPayload(
      text: json['text'] as String,
      tier: json['tier'] as String,
    );
  }

  /// The punishment text.
  final String text;

  /// The punishment tier: "mild", "medium", "spicy", "custom".
  final String tier;
}

/// Wire payload for server→client game.turn_complete.
/// SYNC WITH: rackup-server/internal/protocol/messages.go (TurnCompletePayload)
class TurnCompletePayload {
  /// Creates a [TurnCompletePayload].
  const TurnCompletePayload({
    required this.shooterHash,
    required this.result,
    required this.pointsAwarded,
    required this.newScore,
    required this.newStreak,
    required this.currentShooterHash,
    required this.currentRound,
    required this.isGameOver,
    this.streakLabel = '',
    this.streakMilestone = false,
    this.leaderboard = const [],
    this.cascadeProfile = 'routine',
    this.isTriplePoints = false,
    this.triplePointsActivated = false,
    this.punishment,
    this.recordThis = false,
    this.recordThisSubtext = '',
    this.recordThisTargetHash = '',
  });

  /// Creates from JSON map.
  factory TurnCompletePayload.fromJson(Map<String, dynamic> json) {
    final leaderboardList = (json['leaderboard'] as List<dynamic>?)
            ?.map(
              (e) =>
                  LeaderboardEntryPayload.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        const [];
    final punishmentJson = json['punishment'] as Map<String, dynamic>?;
    return TurnCompletePayload(
      shooterHash: json['shooterHash'] as String,
      result: json['result'] as String,
      pointsAwarded: json['pointsAwarded'] as int,
      newScore: json['newScore'] as int,
      newStreak: json['newStreak'] as int,
      currentShooterHash: json['currentShooterHash'] as String,
      currentRound: json['currentRound'] as int,
      isGameOver: json['isGameOver'] as bool,
      streakLabel: json['streakLabel'] as String? ?? '',
      streakMilestone: json['streakMilestone'] as bool? ?? false,
      leaderboard: leaderboardList,
      cascadeProfile: json['cascadeProfile'] as String? ?? 'routine',
      isTriplePoints: json['isTriplePoints'] as bool? ?? false,
      triplePointsActivated: json['triplePointsActivated'] as bool? ?? false,
      punishment: punishmentJson != null
          ? PunishmentPayload.fromJson(punishmentJson)
          : null,
      recordThis: json['recordThis'] as bool? ?? false,
      recordThisSubtext: json['recordThisSubtext'] as String? ?? '',
      recordThisTargetHash: json['recordThisTargetHash'] as String? ?? '',
    );
  }

  /// The shooter's device ID hash.
  final String shooterHash;

  /// The shot result: "made" or "missed".
  final String result;

  /// Points awarded for this shot.
  final int pointsAwarded;

  /// The shooter's new total score.
  final int newScore;

  /// The shooter's new streak count.
  final int newStreak;

  /// The next shooter's device ID hash.
  final String currentShooterHash;

  /// The current round number.
  final int currentRound;

  /// Whether the game has ended.
  final bool isGameOver;

  /// Streak label: "", "warming_up", "on_fire", "unstoppable".
  final String streakLabel;

  /// True when streak threshold was just crossed (2, 3, or 4).
  final bool streakMilestone;

  /// Leaderboard snapshot sorted by score descending.
  final List<LeaderboardEntryPayload> leaderboard;

  /// Cascade timing profile: "routine", "streak_milestone", "triple_points", etc.
  final String cascadeProfile;

  /// Whether the game is in the final 3 rounds (triple-point territory).
  final bool isTriplePoints;

  /// Whether triple points just activated this turn (fires once).
  final bool triplePointsActivated;

  /// Punishment drawn on missed shot. Null when shot was made.
  final PunishmentPayload? punishment;

  /// Whether a RECORD THIS moment was detected.
  final bool recordThis;

  /// Descriptive text for the RECORD THIS alert.
  final String recordThisSubtext;

  /// Device ID hash of the player to exclude from the alert.
  final String recordThisTargetHash;
}

/// Wire payload for a single leaderboard entry.
/// SYNC WITH: rackup-server/internal/protocol/messages.go (LeaderboardEntry)
class LeaderboardEntryPayload {
  /// Creates a [LeaderboardEntryPayload].
  const LeaderboardEntryPayload({
    required this.deviceIdHash,
    required this.displayName,
    required this.score,
    required this.streak,
    required this.streakLabel,
    required this.rank,
    this.rankChanged = false,
  });

  /// Creates from JSON map.
  factory LeaderboardEntryPayload.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryPayload(
      deviceIdHash: json['deviceIdHash'] as String,
      displayName: json['displayName'] as String? ?? '',
      score: json['score'] as int,
      streak: json['streak'] as int,
      streakLabel: json['streakLabel'] as String? ?? '',
      rank: json['rank'] as int,
      rankChanged: json['rankChanged'] as bool? ?? false,
    );
  }

  /// The player's device ID hash.
  final String deviceIdHash;

  /// The player's display name.
  final String displayName;

  /// The player's current score.
  final int score;

  /// The player's current streak.
  final int streak;

  /// Streak label: "", "warming_up", "on_fire", "unstoppable".
  final String streakLabel;

  /// The player's rank (1-based).
  final int rank;

  /// Whether the player's rank changed this turn.
  final bool rankChanged;
}

/// Error response payload.
class ErrorResponse {
  /// Creates an [ErrorResponse].
  const ErrorResponse({required this.code, required this.message});

  /// Creates from JSON map.
  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }

  /// Error code constant (e.g., "ROOM_FULL").
  final String code;

  /// Human-readable error message.
  final String message;
}
