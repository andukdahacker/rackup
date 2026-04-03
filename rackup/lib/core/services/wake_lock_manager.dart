import 'dart:developer';

import 'package:wakelock_plus/wakelock_plus.dart';

/// Manages screen wake lock for active game sessions.
///
/// Wraps [WakelockPlus] to provide a testable abstraction. All calls are
/// wrapped in try/catch since `wakelock_plus` can throw on unsupported
/// platforms (e.g., web).
class WakeLockManager {
  /// Creates a [WakeLockManager].
  ///
  /// For testing, pass a custom [enableFn] and [disableFn].
  WakeLockManager({
    Future<void> Function()? enableFn,
    Future<void> Function()? disableFn,
  })  : _enableFn = enableFn ?? WakelockPlus.enable,
        _disableFn = disableFn ?? WakelockPlus.disable;

  final Future<void> Function() _enableFn;
  final Future<void> Function() _disableFn;

  /// Enables the screen wake lock.
  Future<void> enable() async {
    try {
      await _enableFn();
    } on Exception catch (e) {
      log('WakeLockManager.enable() failed: $e', name: 'WakeLockManager');
    }
  }

  /// Disables the screen wake lock.
  Future<void> disable() async {
    try {
      await _disableFn();
    } on Exception catch (e) {
      log('WakeLockManager.disable() failed: $e', name: 'WakeLockManager');
    }
  }
}
