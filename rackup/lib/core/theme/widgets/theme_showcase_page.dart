import 'package:flutter/material.dart';
import 'package:rackup/core/theme/player_identity.dart';
import 'package:rackup/core/theme/rackup_colors.dart';
import 'package:rackup/core/theme/rackup_spacing.dart';
import 'package:rackup/core/theme/rackup_typography.dart';
import 'package:rackup/core/theme/widgets/player_shape.dart';

/// Temporary theme showcase page for visual verification.
///
/// Displays all design system tokens: colors, typography, spacing,
/// player identities, and escalation tiers.
class ThemeShowcasePage extends StatelessWidget {
  const ThemeShowcasePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RackUpColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(RackUpSpacing.spaceMd),
          children: const [
            _SectionTitle('Semantic Colors'),
            _ColorRow('Canvas', RackUpColors.canvas),
            _ColorRow('Made Green', RackUpColors.madeGreen),
            _ColorRow('Missed Red', RackUpColors.missedRed),
            _ColorRow('Streak Gold', RackUpColors.streakGold),
            _ColorRow('Item Blue', RackUpColors.itemBlue),
            _ColorRow('Mission Purple', RackUpColors.missionPurple),
            _ColorRow('Text Primary', RackUpColors.textPrimary),
            _ColorRow('Text Secondary', RackUpColors.textSecondary),
            SizedBox(height: RackUpSpacing.spaceLg),
            _SectionTitle('Escalation Tiers'),
            _TierRow('Lobby', RackUpColors.tierLobby),
            _TierRow('Mild (0-30%)', RackUpColors.tierMild),
            _TierRow('Medium (30-70%)', RackUpColors.tierMedium),
            _TierRow('Spicy (70-100%)', RackUpColors.tierSpicy),
            SizedBox(height: RackUpSpacing.spaceLg),
            _SectionTitle('Typography Scale'),
            _TypographyRow(
              'display-xl',
              RackUpTypography.displayXl,
              themeStyleKey: 'displayLarge',
            ),
            _TypographyRow(
              'display-lg',
              RackUpTypography.displayLg,
              themeStyleKey: 'displayMedium',
            ),
            _TypographyRow(
              'display-md',
              RackUpTypography.displayMd,
              themeStyleKey: 'displaySmall',
            ),
            _TypographyRow(
              'display-sm',
              RackUpTypography.displaySm,
              themeStyleKey: 'headlineLarge',
            ),
            _TypographyRow(
              'heading',
              RackUpTypography.heading,
              themeStyleKey: 'headlineMedium',
            ),
            _TypographyRow(
              'body-lg',
              RackUpTypography.bodyLg,
              themeStyleKey: 'bodyLarge',
            ),
            _TypographyRow(
              'body',
              RackUpTypography.body,
              themeStyleKey: 'bodyMedium',
            ),
            _TypographyRow(
              'caption',
              RackUpTypography.caption,
              themeStyleKey: 'bodySmall',
            ),
            SizedBox(height: RackUpSpacing.spaceLg),
            _SectionTitle('Spacing Tokens'),
            _SpacingRow('space-xs', RackUpSpacing.spaceXs),
            _SpacingRow('space-sm', RackUpSpacing.spaceSm),
            _SpacingRow('space-md', RackUpSpacing.spaceMd),
            _SpacingRow('space-lg', RackUpSpacing.spaceLg),
            _SpacingRow('space-xl', RackUpSpacing.spaceXl),
            _SpacingRow('space-xxl', RackUpSpacing.spaceXxl),
            SizedBox(height: RackUpSpacing.spaceLg),
            _SectionTitle('Player Identity Slots'),
            _PlayerIdentityGrid(),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: RackUpSpacing.spaceSm),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow(this.name, this.color);
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RackUpSpacing.spaceXs),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: RackUpColors.textSecondary),
            ),
          ),
          const SizedBox(width: RackUpSpacing.spaceSm),
          Expanded(
            child: Builder(
              builder: (context) {
                final hex = color
                    .toARGB32()
                    .toRadixString(16)
                    .padLeft(8, '0')
                    .substring(2)
                    .toUpperCase();
                return Text(
                  '$name — #$hex',
                  style: Theme.of(context).textTheme.bodyMedium,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TierRow extends StatelessWidget {
  const _TierRow(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(vertical: RackUpSpacing.spaceXs),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _TypographyRow extends StatelessWidget {
  const _TypographyRow(this.token, this.style, {this.themeStyleKey});
  final String token;
  final TextStyle style;
  final String? themeStyleKey;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final resolvedStyle = switch (themeStyleKey) {
      'displayLarge' => textTheme.displayLarge,
      'displayMedium' => textTheme.displayMedium,
      'displaySmall' => textTheme.displaySmall,
      'headlineLarge' => textTheme.headlineLarge,
      'headlineMedium' => textTheme.headlineMedium,
      'bodyLarge' => textTheme.bodyLarge,
      'bodyMedium' => textTheme.bodyMedium,
      'bodySmall' => textTheme.bodySmall,
      _ => style,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RackUpSpacing.spaceXs),
      child: Text(
        '$token — ${style.fontSize?.toInt()}dp',
        style: resolvedStyle,
      ),
    );
  }
}

class _SpacingRow extends StatelessWidget {
  const _SpacingRow(this.token, this.value);
  final String token;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: RackUpSpacing.spaceXs),
      child: Row(
        children: [
          Container(
            width: value,
            height: 24,
            color: RackUpColors.itemBlue,
          ),
          const SizedBox(width: RackUpSpacing.spaceSm),
          Builder(
            builder: (context) => Text(
              '$token — ${value.toInt()}dp',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerIdentityGrid extends StatelessWidget {
  const _PlayerIdentityGrid();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: RackUpSpacing.spaceMd,
      runSpacing: RackUpSpacing.spaceMd,
      children: PlayerIdentity.slots.map((identity) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerShapeWidget(
              shape: identity.shape,
              color: identity.color,
              size: 48,
            ),
            const SizedBox(height: RackUpSpacing.spaceXs),
            Builder(
              builder: (context) => Text(
                identity.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: identity.color,
                    ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
