import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rackup/core/models/player.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_spacing.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/core/websocket/lobby_message_listener.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/bloc/room_event.dart';
import 'package:rackup/features/lobby/bloc/room_state.dart';
import 'package:rackup/features/lobby/view/widgets/player_list_tile.dart';
import 'package:rackup/features/lobby/view/widgets/punishment_input.dart';
import 'package:rackup/features/lobby/view/widgets/room_code_display.dart';
import 'package:share_plus/share_plus.dart';

/// The pre-game lobby screen.
///
/// Shows room code, share invite link, and real-time player list.
/// Portrait-locked, dark canvas (#0F0E1A), bottom-weighted layout.
class LobbyPage extends StatefulWidget {
  /// Creates a [LobbyPage].
  const LobbyPage({super.key});

  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  LobbyMessageListener? _messageListener;

  @override
  void initState() {
    super.initState();
    _messageListener = LobbyMessageListener(
      webSocketCubit: context.read<WebSocketCubit>(),
      roomBloc: context.read<RoomBloc>(),
    );
  }

  @override
  void dispose() {
    _messageListener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.read<WebSocketCubit>().disconnect();
          context.read<RoomBloc>().add(const ResetRoom());
          context.go('/');
        }
      },
      child: Scaffold(
        backgroundColor: RackUpColors.canvas,
        body: BlocBuilder<RoomBloc, RoomState>(
          builder: (context, state) {
            if (state is! RoomLobby) {
              return const Center(
                child: CircularProgressIndicator(
                  color: RackUpColors.streakGold,
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: RackUpSpacing.spaceXl,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: RackUpSpacing.spaceXl),
                    // Room code display.
                    RoomCodeDisplay(roomCode: state.roomCode),
                    const SizedBox(height: RackUpSpacing.spaceLg),
                    // Share invite link button.
                    SizedBox(
                      width: double.infinity,
                      height: RackUpSpacing.primaryButtonHeight,
                      child: _ShareInviteButton(roomCode: state.roomCode),
                    ),
                    const SizedBox(height: RackUpSpacing.spaceLg),
                    // Player list header.
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Players (${state.players.length})',
                        style: RackUpTypography.bodyLg.copyWith(
                          color: RackUpColors.textSecondary,
                        ),
                        textScaler:
                            ClampedTextScaler.of(context, TextRole.body),
                      ),
                    ),
                    const SizedBox(height: RackUpSpacing.spaceMd),
                    // Scrollable player list with lobby tier background.
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: RackUpColors.tierLobby,
                          borderRadius:
                              BorderRadius.circular(RackUpSpacing.spaceSm),
                        ),
                        child: _PlayerList(
                          players: state.players,
                        ),
                      ),
                    ),
                    const SizedBox(height: RackUpSpacing.spaceMd),
                    // Punishment input.
                    const PunishmentInput(),
                    // TODO: Story 2.3 — Slide-to-start
                    const SizedBox(height: RackUpSpacing.spaceMd),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ShareInviteButton extends StatelessWidget {
  const _ShareInviteButton({required this.roomCode});

  final String roomCode;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Share Invite Link',
      child: Material(
        color: RackUpColors.madeGreen,
        borderRadius: BorderRadius.circular(RackUpSpacing.spaceSm),
        child: InkWell(
          onTap: () async {
            await SharePlus.instance.share(
              ShareParams(
                text: 'Join my RackUp game! '
                    'Use code: $roomCode '
                    'or tap: https://rackup.app/join/$roomCode',
              ),
            );
          },
          borderRadius: BorderRadius.circular(RackUpSpacing.spaceSm),
          child: Center(
            child: Text(
              'Share Invite Link',
              style: RackUpTypography.bodyLg.copyWith(
                fontFamily: RackUpFontFamilies.display,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textScaler:
                  ClampedTextScaler.of(context, TextRole.buttonLabel),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerList extends StatelessWidget {
  const _PlayerList({required this.players});

  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(RackUpSpacing.spaceSm),
      itemCount: players.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: RackUpSpacing.spaceMd),
      itemBuilder: (context, index) {
        return PlayerListTile(
          player: players[index],
          staggerIndex: index,
        );
      },
    );
  }
}
