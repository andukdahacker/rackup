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
      _deviceId = const Uuid().v4();
      await _prefs.setString(_key, _deviceId!);
    }
  }

  /// Returns the raw local UUID. For local use only — never transmit this.
  String getDeviceId() {
    assert(_deviceId != null, 'DeviceIdentityService.init() must be called');
    return _deviceId!;
  }

  /// Returns the SHA-256 hex digest of the device UUID.
  ///
  /// Use this for all server communication (NFR10).
  String getHashedDeviceId() {
    final id = getDeviceId();
    return sha256.convert(utf8.encode(id)).toString();
  }
}
