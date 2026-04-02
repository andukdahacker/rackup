/// Controls UI event rendering delays based on cascade profile for dramatic pacing.
///
/// Maps cascade profile strings from the server to timing durations.
/// The controller delays UI event rendering so streak milestones and
/// future special events get appropriate dramatic pacing.
class CascadeTiming {
  const CascadeTiming._();

  /// Returns the delay duration for a given cascade profile.
  static Duration delayFor(String cascadeProfile) {
    return switch (cascadeProfile) {
      'routine' => Duration.zero,
      'streak_milestone' => const Duration(milliseconds: 500),
      'triple_points' => const Duration(milliseconds: 500),
      // Future profiles with placeholder durations.
      'item_punishment' => const Duration(milliseconds: 1000),
      'spicy' => const Duration(milliseconds: 1200),
      'record_this' => const Duration(milliseconds: 1500),
      _ => Duration.zero,
    };
  }

  /// Whether the profile requires a delay before UI event rendering.
  static bool hasDelay(String cascadeProfile) {
    return delayFor(cascadeProfile) > Duration.zero;
  }
}
