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
    );
  }

  /// The room code.
  final String roomCode;

  /// The host's device ID hash.
  final String hostDeviceIdHash;

  /// All players currently in the room.
  final List<LobbyPlayerPayload> players;
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
