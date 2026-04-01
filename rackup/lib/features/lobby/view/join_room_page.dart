import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_spacing.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/bloc/room_event.dart';
import 'package:rackup/features/lobby/bloc/room_state.dart';

/// The room joining screen.
///
/// Shows a form with room code input, display name input, and Join button.
/// Displays loading during join, success on completion, and inline errors
/// with retry on failure.
class JoinRoomPage extends StatelessWidget {
  /// Creates a [JoinRoomPage].
  ///
  /// When [initialCode] is provided (from a deep link), the room code fields
  /// are pre-filled and set as read-only. The display name field receives
  /// focus instead.
  const JoinRoomPage({this.initialCode, super.key});

  /// Optional room code from a deep link (e.g. `/join/ABCD`).
  final String? initialCode;

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
            'Join Room',
            textScaler: ClampedTextScaler.of(context, TextRole.display),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: BlocBuilder<RoomBloc, RoomState>(
          builder: (context, state) {
            return switch (state) {
              RoomInitial() || RoomError() => _JoinFormView(
                  errorMessage:
                      state is RoomError ? state.message : null,
                  initialCode: initialCode,
                ),
              RoomJoining() || RoomCreating() => const _LoadingView(),
              RoomCreatedState() => const _LoadingView(),
              RoomLobby() || RoomStarting() => const SizedBox.shrink(),
            };
          },
        ),
      ),
    );
  }
}

class _JoinFormView extends StatefulWidget {
  const _JoinFormView({this.errorMessage, this.initialCode});

  final String? errorMessage;
  final String? initialCode;

  @override
  State<_JoinFormView> createState() => _JoinFormViewState();
}

class _JoinFormViewState extends State<_JoinFormView> {
  late final List<TextEditingController> _codeControllers;
  late final List<FocusNode> _codeFocusNodes;
  late final List<FocusNode> _keyListenerFocusNodes;
  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  bool _codeReadOnly = false;
  bool _hasInitialCode = false;

  String get _code =>
      _codeControllers.map((c) => c.text).join().toUpperCase();

  bool get _isValid =>
      _code.length == 4 && _nameController.text.trim().isNotEmpty;

  /// Whether the initial code from a deep link is valid
  /// (exactly 4 alpha chars).
  static bool _isValidInitialCode(String? code) {
    if (code == null || code.length != 4) return false;
    return RegExp(r'^[a-zA-Z]{4}$')
        .hasMatch(code);
  }

  @override
  void initState() {
    super.initState();
    _codeControllers = List.generate(4, (_) => TextEditingController());
    _codeFocusNodes = List.generate(4, (_) => FocusNode());
    _keyListenerFocusNodes = List.generate(4, (_) => FocusNode());
    _nameController = TextEditingController();
    _nameFocusNode = FocusNode();

    // Pre-fill code from deep link if valid.
    if (_isValidInitialCode(widget.initialCode)) {
      _hasInitialCode = true;
      final code = widget.initialCode!.toUpperCase();
      for (var i = 0; i < 4; i++) {
        _codeControllers[i].text = code[i];
      }
      // Only set read-only when there's no error (fresh deep link arrival).
      if (widget.errorMessage == null) {
        _codeReadOnly = true;
      }
      // Focus the name field instead of the first code field.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nameFocusNode.requestFocus();
      });
    }

    for (final controller in _codeControllers) {
      controller.addListener(_onChanged);
    }
    _nameController.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant _JoinFormView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorMessage != null && _codeReadOnly) {
      setState(() => _codeReadOnly = false);
    }
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
            Semantics(
              header: true,
              child: Text(
                _hasInitialCode ? 'Join via Link' : 'Enter Room Code',
                style: RackUpTypography.displaySm.copyWith(
                  color: RackUpColors.textPrimary,
                ),
                textScaler: ClampedTextScaler.of(context, TextRole.display),
                textAlign: TextAlign.center,
              ),
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
                    width: RackUpSpacing.minTapTarget,
                    child: Semantics(
                      label: 'Room code digit ${i + 1} of 4',
                      textField: true,
                      readOnly: _codeReadOnly,
                      excludeSemantics: true,
                      child: _CodeCharField(
                        controller: _codeControllers[i],
                        focusNode: _codeFocusNodes[i],
                        keyListenerFocusNode: _keyListenerFocusNodes[i],
                        readOnly: _codeReadOnly,
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
                  ),
                );
              }),
            ),
            if (widget.errorMessage != null) ...[
              const SizedBox(height: RackUpSpacing.spaceMd),
              Semantics(
                liveRegion: true,
                child: Text(
                  widget.errorMessage!,
                  style: RackUpTypography.caption.copyWith(
                    color: RackUpColors.missedRed,
                  ),
                  textScaler: ClampedTextScaler.of(context, TextRole.body),
                  textAlign: TextAlign.center,
                ),
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
                labelText: 'Display name',
                labelStyle: RackUpTypography.body.copyWith(
                  color: RackUpColors.textSecondary,
                ),
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
                label: 'Join room',
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
    this.readOnly = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode keyListenerFocusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;
  final bool readOnly;

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
        readOnly: readOnly,
        maxLength: 1,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.characters,
        style: RackUpTypography.displaySm.copyWith(
          color: readOnly
              ? RackUpColors.textSecondary
              : RackUpColors.textPrimary,
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
    return Center(
      child: Semantics(
        liveRegion: true,
        label: 'Joining room',
        excludeSemantics: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: RackUpColors.streakGold),
            const SizedBox(height: RackUpSpacing.spaceMd),
            Text(
              'Joining room...',
              style: RackUpTypography.body,
              textScaler: ClampedTextScaler.of(context, TextRole.body),
            ),
          ],
        ),
      ),
    );
  }
}

