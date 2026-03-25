import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_spacing.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/bloc/room_event.dart';
import 'package:rackup/features/lobby/bloc/room_state.dart';
import 'package:rackup/features/lobby/view/widgets/room_code_display.dart';
import 'package:share_plus/share_plus.dart';

/// The room creation screen.
///
/// Shows loading during creation, room code on success, and inline errors
/// with retry on failure.
class CreateRoomPage extends StatelessWidget {
  /// Creates a [CreateRoomPage].
  const CreateRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Room'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<RoomBloc, RoomState>(
        builder: (context, state) {
          return switch (state) {
            RoomInitial() => const _InitialView(),
            RoomCreating() || RoomJoining() => const _LoadingView(),
            RoomCreatedState() => _SuccessView(
                roomCode: state.roomCode,
              ),
            RoomError() => _ErrorView(message: state.message),
          };
        },
      ),
    );
  }
}

class _InitialView extends StatefulWidget {
  const _InitialView();

  @override
  State<_InitialView> createState() => _InitialViewState();
}

class _InitialViewState extends State<_InitialView> {
  bool _dispatched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dispatched && mounted) {
        _dispatched = true;
        context.read<RoomBloc>().add(const CreateRoom());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _LoadingView();
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: RackUpColors.streakGold),
          SizedBox(height: RackUpSpacing.spaceMd),
          Text('Creating room...', style: RackUpTypography.body),
        ],
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.roomCode});

  final String roomCode;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RackUpSpacing.spaceXl,
        ),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text(
              'Room Created!',
              style: RackUpTypography.displaySm.copyWith(
                color: RackUpColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RackUpSpacing.spaceXl),
            RoomCodeDisplay(roomCode: roomCode),
            const SizedBox(height: RackUpSpacing.spaceLg),
            Text(
              'Share this code with your friends',
              style: RackUpTypography.body.copyWith(
                color: RackUpColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RackUpSpacing.spaceXl),
            SizedBox(
              width: double.infinity,
              height: RackUpSpacing.primaryButtonHeight,
              child: _ShareButton(roomCode: roomCode),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({required this.roomCode});

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
                    'or tap: rackup.app/join/$roomCode',
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
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: RackUpSpacing.spaceXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: RackUpColors.missedRed,
              size: 48,
            ),
            const SizedBox(height: RackUpSpacing.spaceMd),
            Text(
              message,
              style: RackUpTypography.body.copyWith(
                color: RackUpColors.missedRed,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RackUpSpacing.spaceLg),
            SizedBox(
              width: double.infinity,
              height: RackUpSpacing.primaryButtonHeight,
              child: Semantics(
                button: true,
                label: 'Try Again',
                child: Material(
                  color: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: RackUpColors.textPrimary,
                        width: RackUpSpacing.borderWidth,
                      ),
                      borderRadius:
                          BorderRadius.circular(RackUpSpacing.spaceSm),
                    ),
                    child: InkWell(
                      onTap: () {
                        context.read<RoomBloc>().add(const CreateRoom());
                      },
                      borderRadius:
                          BorderRadius.circular(RackUpSpacing.spaceSm),
                      child: Center(
                        child: Text(
                          'Try Again',
                          style: RackUpTypography.bodyLg.copyWith(
                            fontFamily: RackUpFontFamilies.display,
                            fontWeight: FontWeight.w700,
                            color: RackUpColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
