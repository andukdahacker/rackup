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
