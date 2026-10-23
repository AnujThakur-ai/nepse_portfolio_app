import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/security_service.dart';

class SecurityLockView extends ConsumerStatefulWidget {
  final Widget child;

  const SecurityLockView({super.key, required this.child});

  @override
  ConsumerState<SecurityLockView> createState() => _SecurityLockViewState();
}

class _SecurityLockViewState extends ConsumerState<SecurityLockView> {
  String _enteredPin = '';
  String? _errorMessage;

  Future<void> _tryBiometricUnlock() async {
    final settings = ref.read(settingsProvider);
    if (!settings.isBiometricEnabled) {
      return;
    }

    final success = await SecurityService.authenticateBiometric();
    if (success && mounted) {
      ref.read(securityLockProvider.notifier).setLocked(false);
      setState(() {
        _enteredPin = '';
        _errorMessage = null;
      });
    }
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length >= 4) {
      return;
    }

    setState(() {
      _enteredPin += digit;
      _errorMessage = null;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onDelete() {
    if (_enteredPin.isEmpty) return;
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  void _verifyPin() {
    final settings = ref.read(settingsProvider);
    final isValid = SecurityService.verifyPin(_enteredPin, settings.pinHash);

    if (isValid) {
      ref.read(securityLockProvider.notifier).setLocked(false);
      setState(() {
        _enteredPin = '';
        _errorMessage = null;
      });
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN. Please try again.';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isLocked = ref.watch(securityLockProvider);

    if (!settings.isPinSecurityEnabled || !isLocked) {
      return widget.child;
    }

    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withAlpha(35),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline,
                  size: 46,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'APP LOCKED',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your 4-digit PIN to continue',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(180),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: filled
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withAlpha(80),
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 1.2,
                      ),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 18),
              Container(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Column(
                  children: [
                    _buildKeypadRow(['1', '2', '3'], theme),
                    const SizedBox(height: 14),
                    _buildKeypadRow(['4', '5', '6'], theme),
                    const SizedBox(height: 14),
                    _buildKeypadRow(['7', '8', '9'], theme),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (settings.isBiometricEnabled)
                          IconButton(
                            onPressed: _tryBiometricUnlock,
                            icon: Icon(
                              Icons.fingerprint,
                              color: theme.colorScheme.primary,
                              size: 28,
                            ),
                          )
                        else
                          const SizedBox(width: 48, height: 48),
                        _buildKeypadButton('0', theme),
                        IconButton(
                          onPressed: _onDelete,
                          icon: const Icon(Icons.backspace_outlined),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((digit) => _buildKeypadButton(digit, theme)).toList(),
    );
  }

  Widget _buildKeypadButton(String digit, ThemeData theme) {
    return InkWell(
      onTap: () => _onKeyPress(digit),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(
            color: theme.colorScheme.primary.withAlpha(90),
          ),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
