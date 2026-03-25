import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rackup/core/services/device_identity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DeviceIdentityService', () {
    late SharedPreferences prefs;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<DeviceIdentityService> createService({
      Map<String, Object>? initialValues,
    }) async {
      if (initialValues != null) {
        SharedPreferences.setMockInitialValues(initialValues);
      }
      prefs = await SharedPreferences.getInstance();
      final service = DeviceIdentityService(prefs: prefs);
      await service.init();
      return service;
    }

    test('generates UUID v4 on first call when no stored ID exists', () async {
      final service = await createService();
      final id = service.getDeviceId();

      expect(id, isNotEmpty);
      // UUID v4 format: xxxxxxxx-xxxx-4xxx-[89ab]xxx-xxxxxxxxxxxx
      final uuidV4Pattern = RegExp(
        '^[0-9a-f]{8}-[0-9a-f]{4}'
        '-4[0-9a-f]{3}-[89ab][0-9a-f]{3}'
        r'-[0-9a-f]{12}$',
      );
      expect(
        uuidV4Pattern.hasMatch(id),
        isTrue,
        reason: 'Should be a valid UUID v4',
      );
    });

    test('returns same ID on subsequent calls (persistence)', () async {
      final service1 = await createService();
      final firstId = service1.getDeviceId();

      // Simulate app restart — create new service with same prefs values
      final service2 = await createService(
        initialValues: {'device_id': firstId},
      );
      final secondId = service2.getDeviceId();

      expect(secondId, equals(firstId));
    });

    test('getHashedDeviceId returns valid SHA-256 hex string (64 chars)',
        () async {
      final service = await createService();
      final hashed = service.getHashedDeviceId();

      expect(hashed.length, equals(64));
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(hashed), isTrue);
    });

    test('hash is deterministic (same input produces same hash)', () async {
      final service = await createService();
      final hash1 = service.getHashedDeviceId();
      final hash2 = service.getHashedDeviceId();

      expect(hash1, equals(hash2));

      // Verify against manual SHA-256 computation
      final id = service.getDeviceId();
      final expected = sha256.convert(utf8.encode(id)).toString();
      expect(hash1, equals(expected));
    });
  });
}
