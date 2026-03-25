import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_spacing.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/bloc/room_event.dart';
import 'package:rackup/features/lobby/bloc/room_state.dart';
import 'package:rackup/features/lobby/view/widgets/room_code_display.dart';

/// The room joining screen.
///
/// Shows a form with room code input, display name input, and Join button.
/// Displays loading during join, success on completion, and inline errors
/// with retry on failure.
class JoinRoomPage extends StatelessWidget {
  /// Creates a [JoinRoomPage].
  const JoinRoomPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Room'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<RoomBloc, RoomState>(
        builder: (context, state) {
          return switch (state) {
            RoomInitial() || RoomError() => _JoinFormView(
                errorMessage:
                    state is RoomError ? state.message : null,
              ),
            RoomJoining() || RoomCreating() => const _LoadingView(),
            RoomCreatedState() => _SuccessView(roomCode: state.roomCode),
          };
        },
      ),
    );
  }
}

class _JoinFormView extends StatefulWidget {
  const _JoinFormView({this.errorMessage});

  final String? errorMessage;

  @override
  State<_JoinFormView> createState() => _JoinFormViewState();
}

class _JoinFormViewState extends State<_JoinFormView> {
  late final List<TextEditingController> _codeControllers;
  late final List<FocusNode> _codeFocusNodes;
  late final List<FocusNode> _keyListenerFocusNodes;
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;

  String get _code =>
      _codeControllers.map((c) => c.text).join().toUpperCase();

  bool get _isValid =>
      _code.length == 4 && _nameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _codeControllers = List.generate(4, (_) => TextEditingController());
    _codeFocusNodes = List.generate(4, (_) => FocusNode());
    _keyListenerFocusNodes = List.generate(4, (_) => FocusNode());
    _nameController = TextEditingController();
    _nameFocusNode = FocusNode();

    for (final controller in _codeControllers) {
      controller.addListener(_onChanged);
    }
    _nameController.addListener(_onChanged);
  }

  @override
  void dispose() {
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final n in _codeFocusNodes) {
      n.dispose();
    }
    for (final n in _keyListenerFocusNodes) {
      n.dispose();
    }
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _submit() {
    if (!_isValid) return;
    context.read<RoomBloc>().add(
          JoinRoom(code: _code, displayName: _nameController.text.trim()),
        );
  }

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
              'Enter Room Code',
              style: RackUpTypography.displaySm.copyWith(
                color: RackUpColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RackUpSpacing.spaceXl),
            // Room code input: 4 separate fields.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: i == 0 ? 0 : RackUpSpacing.spaceSm,
                  ),
                  child: SizedBox(
                    width: 48,
                    child: _CodeCharField(
                      controller: _codeControllers[i],
                      focusNode: _codeFocusNodes[i],
                      keyListenerFocusNode: _keyListenerFocusNodes[i],
                      onChanged: (value) {
                        if (value.isNotEmpty && i < 3) {
                          _codeFocusNodes[i + 1].requestFocus();
                        }
                        if (value.isNotEmpty && i == 3) {
                          _nameFocusNode.requestFocus();
                        }
                      },
                      onBackspace: () {
                        if (_codeControllers[i].text.isEmpty && i > 0) {
                          _codeControllers[i - 1].clear();
                          _codeFocusNodes[i - 1].requestFocus();
                        }
                      },
                    ),
                  ),
                );
              }),
            ),
            if (widget.errorMessage != null) ...[
              const SizedBox(height: RackUpSpacing.spaceMd),
              Text(
                widget.errorMessage!,
                style: RackUpTypography.caption.copyWith(
                  color: RackUpColors.missedRed,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: RackUpSpacing.spaceLg),
            // Display name input.
            TextField(
              controller: _nameController,
              focusNode: _nameFocusNode,
              maxLength: 20,
              style: RackUpTypography.body.copyWith(
                color: RackUpColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your name',
                hintStyle: RackUpTypography.body.copyWith(
                  color: RackUpColors.textSecondary,
                ),
                counterStyle: RackUpTypography.caption.copyWith(
                  color: RackUpColors.textSecondary,
                ),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: RackUpColors.textSecondary),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: RackUpColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(height: RackUpSpacing.spaceXl),
            // Join button.
            SizedBox(
              width: double.infinity,
              height: RackUpSpacing.primaryButtonHeight,
              child: Semantics(
                button: true,
                label: 'Join',
                child: Material(
                  color:
                      _isValid ? RackUpColors.madeGreen : RackUpColors.canvas,
                  borderRadius:
                      BorderRadius.circular(RackUpSpacing.spaceSm),
                  child: InkWell(
                    onTap: _isValid ? _submit : null,
                    borderRadius:
                        BorderRadius.circular(RackUpSpacing.spaceSm),
                    child: Center(
                      child: Text(
                        'Join',
                        style: RackUpTypography.bodyLg.copyWith(
                          fontFamily: RackUpFontFamilies.display,
                          fontWeight: FontWeight.w700,
                          color: _isValid
                              ? Colors.white
                              : RackUpColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

/// A single-character text field for the room code input.
class _CodeCharField extends StatelessWidget {
  const _CodeCharField({
    required this.controller,
    required this.focusNode,
    required this.keyListenerFocusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode keyListenerFocusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: keyListenerFocusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          onBackspace();
        }
      },
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLength: 1,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        style: RackUpTypography.displaySm.copyWith(
          color: RackUpColors.textPrimary,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
          TextInputFormatter.withFunction(
            (oldValue, newValue) =>
                newValue.copyWith(text: newValue.text.toUpperCase()),
          ),
        ],
        decoration: const InputDecoration(
          counterText: '',
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: RackUpColors.textSecondary,
              width: RackUpSpacing.borderWidth,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: RackUpColors.textPrimary,
              width: RackUpSpacing.borderWidth,
            ),
          ),
        ),
        onChanged: onChanged,
      ),
    );
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
          Text('Joining room...', style: RackUpTypography.body),
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
              'Joined!',
              style: RackUpTypography.displaySm.copyWith(
                color: RackUpColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: RackUpSpacing.spaceXl),
            RoomCodeDisplay(roomCode: roomCode),
            const SizedBox(height: RackUpSpacing.spaceLg),
            Text(
              'Waiting for game to start...',
              style: RackUpTypography.body.copyWith(
                color: RackUpColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}
