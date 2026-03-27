import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_spacing.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/bloc/room_event.dart';
import 'package:rackup/features/lobby/bloc/room_state.dart';

/// The room creation screen.
///
/// Shows loading during creation, room code on success, and inline errors
/// with retry on failure.
class CreateRoomPage extends StatelessWidget {
  /// Creates a [CreateRoomPage].
  const CreateRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<RoomBloc, RoomState>(
      listenWhen: (_, current) => current is RoomCreatedState,
      listener: (context, state) {
        context.go('/lobby');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Create Room',
            textScaler: ClampedTextScaler.of(context, TextRole.display),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: BlocBuilder<RoomBloc, RoomState>(
          builder: (context, state) {
            return switch (state) {
              RoomInitial() => const _InitialView(),
              RoomCreating() || RoomJoining() => const _LoadingView(),
              RoomCreatedState() => const _LoadingView(),
              RoomLobby() => const SizedBox.shrink(),
              RoomError() => _ErrorView(message: state.message),
            };
          },
        ),
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
    return Center(
      child: Semantics(
        liveRegion: true,
        label: 'Creating room',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExcludeSemantics(
              child: CircularProgressIndicator(color: RackUpColors.streakGold),
            ),
            const SizedBox(height: RackUpSpacing.spaceMd),
            Text(
              'Creating room...',
              style: RackUpTypography.body,
              textScaler: ClampedTextScaler.of(context, TextRole.body),
            ),
          ],
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
            const ExcludeSemantics(
              child: Icon(
                Icons.error_outline,
                color: RackUpColors.missedRed,
                size: 48,
              ),
            ),
            const SizedBox(height: RackUpSpacing.spaceMd),
            Semantics(
              liveRegion: true,
              child: Text(
                message,
                style: RackUpTypography.body.copyWith(
                  color: RackUpColors.missedRed,
                ),
                textScaler: ClampedTextScaler.of(context, TextRole.body),
                textAlign: TextAlign.center,
              ),
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
                          textScaler: ClampedTextScaler.of(
                            context,
                            TextRole.buttonLabel,
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
