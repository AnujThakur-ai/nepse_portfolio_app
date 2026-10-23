import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  static final LocalAuthentication _auth = LocalAuthentication();
  static const int _pinHashIterations = 100000;

  /// Derives a salted, deliberately slow hash for a 4- or 6-digit PIN.
  static String hashPin(String pin) {
    if (!RegExp(r'^\d{4}(\d{2})?$').hasMatch(pin)) {
      throw const FormatException('PIN must contain 4 or 6 digits.');
    }

    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final encodedSalt = _encodeHex(salt);
    final derivedKey = _pbkdf2(pin, salt);
    return [
      'pbkdf2-sha256',
      '$_pinHashIterations',
      encodedSalt,
      _encodeHex(derivedKey),
    ].join(r'$');
  }

  /// Verifies entered PIN against stored hash
  static bool verifyPin(String enteredPin, String storedHash) {
    if (!RegExp(r'^\d{4}(\d{2})?$').hasMatch(enteredPin) ||
        storedHash.isEmpty) {
      return false;
    }

    final parts = storedHash.split(r'$');
    if (parts.length == 4 &&
        parts[0] == 'pbkdf2-sha256' &&
        int.tryParse(parts[1]) == _pinHashIterations) {
      try {
        final salt = _decodeHex(parts[2]);
        final actual = _encodeHex(_pbkdf2(enteredPin, salt));
        return _constantTimeEquals(actual, parts[3]);
      } on FormatException {
        return false;
      }
    }

    // Continue to accept PINs saved by versions that used the fixed-salt hash.
    const legacySalt = 'nepse_analyzer_salt_#2083!';
    final legacyHash = sha256.convert(utf8.encode(enteredPin + legacySalt));
    return _constantTimeEquals(legacyHash.toString(), storedHash);
  }

  static List<int> _pbkdf2(String pin, List<int> salt) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    final firstBlock = Uint8List(salt.length + 4)
      ..setRange(0, salt.length, salt);
    ByteData.sublistView(firstBlock).setUint32(salt.length, 1, Endian.big);

    var current = hmac.convert(firstBlock).bytes;
    final derivedKey = Uint8List.fromList(current);
    for (var iteration = 1; iteration < _pinHashIterations; iteration++) {
      current = hmac.convert(current).bytes;
      for (var index = 0; index < derivedKey.length; index++) {
        derivedKey[index] ^= current[index];
      }
    }
    return derivedKey;
  }

  static String _encodeHex(List<int> bytes) =>
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  static List<int> _decodeHex(String value) {
    if (value.isEmpty ||
        value.length.isOdd ||
        !RegExp(r'^[0-9a-f]+$').hasMatch(value)) {
      throw const FormatException('Invalid hexadecimal value.');
    }
    return List<int>.generate(
      value.length ~/ 2,
      (index) =>
          int.parse(value.substring(index * 2, index * 2 + 2), radix: 16),
    );
  }

  static bool _constantTimeEquals(String first, String second) {
    var difference = first.length ^ second.length;
    final length = min(first.length, second.length);
    for (var index = 0; index < length; index++) {
      difference |= first.codeUnitAt(index) ^ second.codeUnitAt(index);
    }
    return difference == 0;
  }

  /// Checks if device supports biometric authentication
  static Future<bool> canCheckBiometrics() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported && canCheck;
    } on PlatformException {
      return false;
    }
  }

  /// Triggers biometric prompt (Fingerprint / Face ID)
  static Future<bool> authenticateBiometric({
    String reason = 'Authenticate to access NEPSE Portfolio Analyzer',
  }) async {
    try {
      final canAuth = await canCheckBiometrics();
      if (!canAuth) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    }
  }
}
