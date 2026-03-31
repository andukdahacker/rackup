// SYNC WITH: rackup-server/internal/protocol/actions.go

/// Action constants for WebSocket message routing.
abstract final class Actions {
  /// A player joined the lobby.
  static const String lobbyPlayerJoined = 'lobby.player_joined';

  /// A player left the lobby.
  static const String lobbyPlayerLeft = 'lobby.player_left';

  /// Full room state snapshot sent on WebSocket connect.
  static const String lobbyRoomState = 'lobby.room_state';

  /// A player submitted a punishment.
  static const String lobbyPunishmentSubmitted = 'lobby.punishment_submitted';

  /// A player's lobby status changed.
  static const String lobbyPlayerStatusChanged = 'lobby.player_status_changed';

  // Story 2.3: lobby.game_started — no handler in 2.1.

  /// A game turn was completed.
  static const String gameTurnComplete = 'game.turn_complete';

  /// An error occurred.
  static const String error = 'error';
}
