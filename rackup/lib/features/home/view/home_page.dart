import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_spacing.dart';
import 'package:rackup/core/theme/rackup_typography.dart';

/// The app's home screen with Create Room and Join Room actions.
class HomePage extends StatelessWidget {
  /// Creates a [HomePage].
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: RackUpSpacing.spaceXl,
          ),
          child: Column(
            children: [
              const Spacer(flex: 2),
              const Text(
                'Turn pool night into chaos',
                style: RackUpTypography.displayLg,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: RackUpSpacing.spaceLg),
              Text(
                'Grab friends. Find a pool table. Let the chaos begin.',
                style: RackUpTypography.body.copyWith(
                  color: RackUpColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: RackUpSpacing.primaryButtonHeight,
                child: _PrimaryButton(
                  label: 'Create Room',
                  onPressed: () => context.push('/create'),
                ),
              ),
              const SizedBox(height: RackUpSpacing.spaceMd),
              SizedBox(
                width: double.infinity,
                height: RackUpSpacing.primaryButtonHeight,
                child: _SecondaryButton(
                  label: 'Join Room',
                  onPressed: () => context.push('/join'),
                ),
              ),
              const SizedBox(height: RackUpSpacing.spaceXl),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: RackUpColors.madeGreen,
      borderRadius: BorderRadius.circular(RackUpSpacing.spaceSm),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(RackUpSpacing.spaceSm),
        child: Center(
          child: Semantics(
            button: true,
            label: '$label button',
            child: Text(
              label,
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

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: RackUpColors.textPrimary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(RackUpSpacing.spaceSm),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(RackUpSpacing.spaceSm),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(RackUpSpacing.spaceSm),
          child: Center(
            child: Semantics(
              button: true,
              label: '$label button',
              child: Text(
                label,
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
    );
  }
}
