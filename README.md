# NEPSE Portfolio Analyzer

Standalone Flutter application for tracking NEPSE trades, portfolio performance, watchlists, reminders, and technical indicators. User data is stored locally on device.

## Run

```sh
flutter pub get
flutter run
```

## Validate

```sh
flutter analyze
flutter test
```

PIN and biometric access are optional. New PINs use salted PBKDF2-HMAC-SHA256 hashes; PINs saved by older versions remain verifiable. When PIN or biometric security is enabled, the app locks again when it leaves the foreground. Android blocks screenshots and screen recordings, and iOS covers the app-switcher snapshot. iOS does not provide an app API to block user-initiated screenshots.
