import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Manages a persistent anonymous device identifier.
///
/// Generates a UUID v4 on first launch and persists it locally via
/// [SharedPreferences]. The raw UUID never leaves the device — use
/// [getHashedDeviceId] for any server communication.
class DeviceIdentityService {
  /// Creates a [DeviceIdentityService] backed by [prefs].
  DeviceIdentityService({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const _key = 'device_id';

  String? _deviceId;

  /// Initializes the service by loading or generating the device ID.
  ///
  /// Must be called before [getDeviceId] or [getHashedDeviceId].
  Future<void> init() async {
    _deviceId = _prefs.getString(_key);
    if (_deviceId == null) {
      final newId = const Uuid().v4();
      final saved = await _prefs.setString(_key, newId);
      if (!saved) {
        throw StateError(
          'Failed to persist device ID to SharedPreferences',
        );
      }
      _deviceId = newId;
    }
  }

  /// Returns the raw local UUID. For local use only — never transmit this.
  ///
  /// Throws [StateError] if [init] has not been called.
  String getDeviceId() {
    final id = _deviceId;
    if (id == null) {
      throw StateError(
        'DeviceIdentityService.init() must be called before getDeviceId()',
      );
    }
    return id;
  }

  /// Returns the SHA-256 hex digest of the device UUID.
  ///
  /// Use this for all server communication (NFR10).
  String getHashedDeviceId() {
    final id = getDeviceId();
    return sha256.convert(utf8.encode(id)).toString();
  }
}
