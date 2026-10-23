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

PIN and biometric access are optional. PINs are stored as salted SHA-256 hashes; biometric unlock is offered only when enabled and supported by the device.
