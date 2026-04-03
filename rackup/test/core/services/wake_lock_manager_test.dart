import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/services/wake_lock_manager.dart';

void main() {
  group('WakeLockManager', () {
    test('enable calls enableFn', () async {
      var called = false;
      final manager = WakeLockManager(
        enableFn: () async => called = true,
        disableFn: () async {},
      );

      await manager.enable();

      expect(called, isTrue);
    });

    test('disable calls disableFn', () async {
      var called = false;
      final manager = WakeLockManager(
        enableFn: () async {},
        disableFn: () async => called = true,
      );

      await manager.disable();

      expect(called, isTrue);
    });

    test('enable catches exceptions without crashing', () async {
      final manager = WakeLockManager(
        enableFn: () async => throw Exception('unsupported platform'),
        disableFn: () async {},
      );

      // Should not throw
      await manager.enable();
    });

    test('disable catches exceptions without crashing', () async {
      final manager = WakeLockManager(
        enableFn: () async {},
        disableFn: () async => throw Exception('unsupported platform'),
      );

      // Should not throw
      await manager.disable();
    });
  });
}
