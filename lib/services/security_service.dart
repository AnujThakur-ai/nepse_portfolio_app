import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Hashes a 4-digit or 6-digit PIN using SHA-256 with a salt
  static String hashPin(String pin) {
    const salt = 'nepse_analyzer_salt_#2083!';
    final bytes = utf8.encode(pin + salt);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies entered PIN against stored hash
  static bool verifyPin(String enteredPin, String storedHash) {
    if (enteredPin.isEmpty || storedHash.isEmpty) return false;
    final enteredHash = hashPin(enteredPin);
    return enteredHash == storedHash;
  }

  /// Checks if device supports biometric authentication
  static Future<bool> canCheckBiometrics() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported && canCheck;
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
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
    } on PlatformException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }
}
