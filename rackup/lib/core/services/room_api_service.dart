import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:rackup/core/protocol/messages.dart';

/// HTTP client for room-related API calls.
class RoomApiService {
  /// Creates a [RoomApiService] with the given [apiBaseUrl].
  RoomApiService({required this.apiBaseUrl, http.Client? client})
      : _client = client ?? http.Client();

  /// The base URL for the API (e.g., "http://localhost:8080").
  final String apiBaseUrl;
  final http.Client _client;

  /// Request timeout for room creation (NFR1: < 2 seconds).
  static const _requestTimeout = Duration(seconds: 5);

  /// Creates a new room by sending the hashed device ID to the server.
  ///
  /// Implements single automatic retry on network error before throwing.
  Future<CreateRoomResponse> createRoom(String deviceIdHash) async {
    try {
      return await _postCreateRoom(deviceIdHash);
    } on SocketException {
      // Single automatic retry on network error.
      return _postCreateRoom(deviceIdHash);
    } on http.ClientException {
      // Single automatic retry on network error.
      return _postCreateRoom(deviceIdHash);
    } on TimeoutException {
      // Single automatic retry on timeout.
      return _postCreateRoom(deviceIdHash);
    }
  }

  Future<CreateRoomResponse> _postCreateRoom(String deviceIdHash) async {
    final uri = Uri.parse('$apiBaseUrl/rooms');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'deviceIdHash': deviceIdHash}),
        )
        .timeout(_requestTimeout);

    if (response.statusCode == 201) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return CreateRoomResponse.fromJson(json);
    }

    // Parse error response.
    String errorMessage;
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final payload = json['payload'] as Map<String, dynamic>?;
      errorMessage = payload?['message'] as String? ?? 'Unknown error';
    } on FormatException {
      errorMessage = 'Server error (${response.statusCode})';
    }

    throw RoomApiException(
      statusCode: response.statusCode,
      message: errorMessage,
    );
  }
  /// Joins an existing room by sending the room code, display name, and
  /// hashed device ID to the server.
  ///
  /// Implements single automatic retry on network error before throwing.
  Future<JoinRoomResponse> joinRoom(
    String code,
    String displayName,
    String deviceIdHash,
  ) async {
    try {
      return await _postJoinRoom(code, displayName, deviceIdHash);
    } on SocketException {
      return _postJoinRoom(code, displayName, deviceIdHash);
    } on http.ClientException {
      return _postJoinRoom(code, displayName, deviceIdHash);
    } on TimeoutException {
      return _postJoinRoom(code, displayName, deviceIdHash);
    }
  }

  Future<JoinRoomResponse> _postJoinRoom(
    String code,
    String displayName,
    String deviceIdHash,
  ) async {
    final uri = Uri.parse('$apiBaseUrl/rooms/$code/join');
    final response = await _client
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'deviceIdHash': deviceIdHash,
            'displayName': displayName,
          }),
        )
        .timeout(_requestTimeout);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return JoinRoomResponse.fromJson(json);
    }

    // Parse error response.
    String errorMessage;
    String? errorCode;
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final payload = json['payload'] as Map<String, dynamic>?;
      errorMessage = payload?['message'] as String? ?? 'Unknown error';
      errorCode = payload?['code'] as String?;
    } on FormatException {
      errorMessage = 'Server error (${response.statusCode})';
    }

    throw RoomApiException(
      statusCode: response.statusCode,
      message: errorMessage,
      errorCode: errorCode,
    );
  }
}

/// Exception thrown when a room API call fails.
class RoomApiException implements Exception {
  /// Creates a [RoomApiException].
  const RoomApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
  });

  /// The HTTP status code.
  final int statusCode;

  /// Human-readable error message.
  final String message;

  /// Server error code (e.g., "ROOM_NOT_FOUND", "ROOM_FULL").
  final String? errorCode;

  @override
  String toString() => 'RoomApiException($statusCode): $message';
}
