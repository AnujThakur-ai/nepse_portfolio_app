import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static String hashPin(String pin) {
    const salt = 'nepse_portfolio_salt_2026';
    final digest = sha256.convert(utf8.encode(pin + salt));
    return digest.toString();
  }

  static bool verifyPin(String enteredPin, String storedHash) {
    if (enteredPin.isEmpty || storedHash.isEmpty) {
      return false;
    }
    return hashPin(enteredPin) == storedHash;
  }

  static Future<bool> canCheckBiometrics() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return isSupported && canCheck;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticateBiometric({
    String reason = 'Authenticate to unlock the NEPSE portfolio app',
  }) async {
    try {
      final canAuth = await canCheckBiometrics();
      if (!canAuth) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
