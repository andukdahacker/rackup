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
	ActionError                    = "error"
)
