import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rackup/core/data/punishment_deck.dart';
import 'package:rackup/core/protocol/actions.dart' as protocol;
import 'package:rackup/core/protocol/messages.dart';
import 'package:rackup/core/theme/clamped_text_scaler.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_spacing.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/core/websocket/web_socket_cubit.dart';
import 'package:rackup/core/websocket/web_socket_state.dart';
import 'package:rackup/features/lobby/bloc/room_bloc.dart';
import 'package:rackup/features/lobby/bloc/room_event.dart';

/// Punishment input widget for the pre-game lobby.
///
/// States: Empty (rotating placeholder), Focused (blue border), Filled (text),
/// Submitted (read-only with checkmark).
class PunishmentInput extends StatefulWidget {
  /// Creates a [PunishmentInput].
  const PunishmentInput({super.key});

  @override
  State<PunishmentInput> createState() => PunishmentInputState();
}

/// Visible for testing state access.
class PunishmentInputState extends State<PunishmentInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _submitted = false;
  bool _hasSentWritingStatus = false;
  int _placeholderIndex = 0;
  Timer? _placeholderTimer;

  static const _placeholderExamples = [
    'Do your best impression of someone here',
    "Text the 3rd person in your contacts 'I love you'",
    'Speak in an accent until your next turn',
    'Let the group pick your next drink order',
  ];

  static const _maxLength = 140;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _startPlaceholderRotation();
  }

  void _startPlaceholderRotation() {
    _placeholderTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        if (_controller.text.isEmpty && !_focusNode.hasFocus && mounted) {
          setState(() {
            _placeholderIndex =
                (_placeholderIndex + 1) % _placeholderExamples.length;
          });
        }
      },
    );
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  void _onTextChanged(String value) {
    if (!_hasSentWritingStatus && value.isNotEmpty) {
      _hasSentWritingStatus = true;
      context.read<WebSocketCubit>().sendMessage(Message(
        action: protocol.Actions.lobbyPlayerStatusChanged,
        payload: const <String, dynamic>{'status': 'writing'},
      ));
    }
    setState(() {});
  }

  void _onRandom() {
    final punishment = randomPunishment();
    _controller.text = punishment;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: punishment.length),
    );
    _onTextChanged(punishment);
  }

  void _onSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // Only mark submitted if WebSocket is connected.
    final wsState = context.read<WebSocketCubit>().state;
    if (wsState is! WebSocketConnected) return;

    context.read<RoomBloc>().add(PunishmentSubmitted(text: text));
    setState(() {
      _submitted = true;
    });
    _focusNode.unfocus();
  }

  @override
  void dispose() {
    _placeholderTimer?.cancel();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Text field row with optional random button.
        Stack(
          alignment: Alignment.centerRight,
          children: [
            Semantics(
              label: 'Enter a custom punishment',
              textField: true,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                readOnly: _submitted,
                maxLength: _maxLength,
                onChanged: _onTextChanged,
                style: RackUpTypography.caption.copyWith(
                  color: _submitted
                      ? RackUpColors.textSecondary
                      : RackUpColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: _placeholderExamples[_placeholderIndex],
                  hintStyle: RackUpTypography.caption.copyWith(
                    color: RackUpColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: RackUpColors.canvas,
                  counterText: _submitted
                      ? ''
                      : '${_controller.text.length}/$_maxLength',
                  counterStyle: RackUpTypography.caption.copyWith(
                    color: RackUpColors.textSecondary,
                    fontSize: 12,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(
                    RackUpSpacing.spaceMd,
                    RackUpSpacing.spaceSm,
                    RackUpSpacing.spaceXl + RackUpSpacing.spaceMd,
                    RackUpSpacing.spaceSm,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(RackUpSpacing.spaceSm),
                    borderSide: BorderSide(
                      color: _submitted
                          ? RackUpColors.madeGreen
                          : RackUpColors.textSecondary.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(RackUpSpacing.spaceSm),
                    borderSide: const BorderSide(
                      color: RackUpColors.itemBlue,
                      width: 2,
                    ),
                  ),
                  suffixIcon: _submitted
                      ? const Icon(
                          Icons.check_circle,
                          color: RackUpColors.madeGreen,
                          semanticLabel: 'Punishment submitted',
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: RackUpSpacing.spaceSm),
        // Action buttons row.
        if (!_submitted)
          Row(
            children: [
              // Random button.
              Semantics(
                button: true,
                label: 'Generate random punishment',
                child: SizedBox(
                  height: RackUpSpacing.minTapTarget,
                  child: TextButton.icon(
                    onPressed: _onRandom,
                    icon: const Icon(
                      Icons.casino,
                      color: RackUpColors.missionPurple,
                      size: 18,
                    ),
                    label: Text(
                      'Random',
                      style: RackUpTypography.caption.copyWith(
                        color: RackUpColors.missionPurple,
                        fontWeight: FontWeight.w600,
                      ),
                      textScaler:
                          ClampedTextScaler.of(context, TextRole.body),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Submit button — visible when text is non-empty.
              if (_controller.text.trim().isNotEmpty)
                Semantics(
                  button: true,
                  label: 'Submit punishment',
                  child: SizedBox(
                    height: RackUpSpacing.minTapTarget,
                    child: ElevatedButton(
                      onPressed: _onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RackUpColors.madeGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(RackUpSpacing.spaceSm),
                        ),
                      ),
                      child: Text(
                        'Submit',
                        style: RackUpTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textScaler:
                            ClampedTextScaler.of(context, TextRole.body),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
