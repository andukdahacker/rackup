package protocol

const (
	ActionLobbyPlayerJoined = "lobby.player_joined"
	ActionLobbyPlayerLeft   = "lobby.player_left"
	ActionLobbyRoomState    = "lobby.room_state"
	ActionGameTurnComplete  = "game.turn_complete"
	ActionLobbyPunishmentSubmitted  = "lobby.punishment_submitted"
	ActionLobbyPlayerStatusChanged = "lobby.player_status_changed"
	ActionLobbyStartGame           = "lobby.start_game"
	ActionLobbyGameStarted         = "lobby.game_started"
	ActionGameInitialized          = "game.initialized"
	ActionRefereeConfirmShot       = "referee.confirm_shot"
	ActionRefereeUndoShot          = "referee.undo_shot"
	ActionGameEnded                = "game.game_ended"
	ActionItemDeploy               = "item.deploy"    // client→server: player deploys an item
	ActionItemDeployed             = "item.deployed"  // server→client: broadcast item deployment
	ActionItemFizzled              = "item.fizzled"   // server→client: deployment failed (to deployer only)
	ActionError                    = "error"
)
