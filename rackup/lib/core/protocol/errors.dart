// SYNC WITH: rackup-server/internal/protocol/errors.go

/// Error code constants for protocol error responses.
abstract final class ErrorCodes {
  /// Room is at maximum player capacity.
  static const String roomFull = 'ROOM_FULL';

  /// Room code does not match any active room.
  static const String roomNotFound = 'ROOM_NOT_FOUND';

  /// JWT is missing, invalid, or expired.
  static const String unauthorized = 'UNAUTHORIZED';

  /// Feature not yet implemented.
  static const String notImplemented = 'NOT_IMPLEMENTED';

  /// Request body is invalid or missing required fields.
  static const String invalidRequest = 'INVALID_REQUEST';

  /// Internal server error.
  static const String internal = 'INTERNAL';

  /// Server at capacity — too many rooms.
  static const String capacityExceeded = 'CAPACITY_EXCEEDED';
}
