// Protocol message mapper — maps between wire format and domain models.

import 'package:rackup/core/models/game_player.dart';
import 'package:rackup/core/models/player.dart';
import 'package:rackup/core/protocol/messages.dart';

/// Maps a [LobbyPlayerPayload] wire type to a [Player] domain model.
Player mapToPlayer(LobbyPlayerPayload payload) {
  return Player(
    displayName: payload.displayName,
    deviceIdHash: payload.deviceIdHash,
    slot: payload.slot,
    isHost: payload.isHost,
    status: _mapStatus(payload.status),
  );
}

/// Maps a [GamePlayerPayload] wire type to a [GamePlayer] domain model.
GamePlayer mapToGamePlayer(GamePlayerPayload payload) {
  return GamePlayer(
    deviceIdHash: payload.deviceIdHash,
    displayName: payload.displayName,
    slot: payload.slot,
    score: payload.score,
    streak: payload.streak,
    isReferee: payload.isReferee,
  );
}

PlayerStatus _mapStatus(String status) {
  return switch (status) {
    'joining' => PlayerStatus.joining,
    'writing' => PlayerStatus.writing,
    'ready' => PlayerStatus.ready,
    _ => PlayerStatus.joining, // default to joining for unknown statuses
  };
}
