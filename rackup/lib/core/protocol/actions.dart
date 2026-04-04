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

  /// Host requests to start the game (client→server).
  static const String lobbyStartGame = 'lobby.start_game';

  /// Game has started — broadcast to all players (server→client).
  static const String lobbyGameStarted = 'lobby.game_started';

  /// Game initialized — server broadcasts full game state (server→client).
  static const String gameInitialized = 'game.initialized';

  /// A game turn was completed.
  static const String gameTurnComplete = 'game.turn_complete';

  /// Referee confirms a shot result (client→server, referee-only).
  static const String refereeConfirmShot = 'referee.confirm_shot';

  /// Referee undoes the last shot (client→server, referee-only).
  static const String refereeUndoShot = 'referee.undo_shot';

  /// Game has ended (server→client).
  static const String gameEnded = 'game.game_ended';

  /// Player deploys an item (client→server).
  static const String itemDeploy = 'item.deploy';

  /// Item deployment confirmed (server→client broadcast).
  static const String itemDeployed = 'item.deployed';

  /// Item deployment failed (server→client to deployer only).
  static const String itemFizzled = 'item.fizzled';

  /// An error occurred.
  static const String error = 'error';
}
