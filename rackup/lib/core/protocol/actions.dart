// SYNC WITH: rackup-server/internal/protocol/actions.go

/// Action constants for WebSocket message routing.
abstract final class Actions {
  /// A player joined the lobby.
  static const String lobbyPlayerJoined = 'lobby.player_joined';

  /// A game turn was completed.
  static const String gameTurnComplete = 'game.turn_complete';

  /// An error occurred.
  static const String error = 'error';
}
