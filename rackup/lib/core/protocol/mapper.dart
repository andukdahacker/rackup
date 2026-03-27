// Protocol message mapper — maps between wire format and domain models.

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

PlayerStatus _mapStatus(String status) {
  return switch (status) {
    'joining' => PlayerStatus.joining,
    // Story 2.2 will add: 'writing' => PlayerStatus.writing,
    // Story 2.2 will add: 'ready' => PlayerStatus.ready,
    _ => PlayerStatus.joining, // default to joining for unknown statuses
  };
}
