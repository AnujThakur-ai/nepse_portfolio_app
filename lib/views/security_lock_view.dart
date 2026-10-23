import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    // Attempt biometric unlock on start if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricUnlock();
    });
  }

  Future<void> _tryBiometricUnlock() async {
    final settings = ref.read(settingsProvider);
    if (settings.isBiometricEnabled) {
      final success = await SecurityService.authenticateBiometric();
      if (success && mounted) {
        HapticFeedback.mediumImpact();
        ref.read(appUnlockedProvider.notifier).setUnlocked(true);
      }
    }
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      HapticFeedback.lightImpact();
      setState(() {
        _enteredPin += digit;
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_enteredPin.isNotEmpty) {
      HapticFeedback.selectionClick();
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _verifyPin() {
    final settings = ref.read(settingsProvider);
    final isValid = SecurityService.verifyPin(_enteredPin, settings.pinHash);

    if (isValid) {
      HapticFeedback.mediumImpact();
      ref.read(appUnlockedProvider.notifier).setUnlocked(true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _errorMessage = 'Incorrect PIN. Please try again.';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final isUnlocked = ref.watch(appUnlockedProvider);

    // If PIN security is disabled or already unlocked, display child app
    final securityEnabled =
        settings.isPinSecurityEnabled || settings.isBiometricEnabled;
    if (!securityEnabled ||
        isUnlocked ||
        (settings.isPinSecurityEnabled &&
            settings.pinHash.isEmpty &&
            !settings.isBiometricEnabled)) {
      return widget.child;
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.primary.withAlpha(16),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Icon(
                            Icons.show_chart_rounded,
                            size: 36,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Welcome back',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          settings.pinHash.isEmpty
                              ? 'Verify your identity to open your portfolio'
                              : 'Enter your 4-digit PIN to continue',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (settings.pinHash.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              final isFilled = index < _enteredPin.length;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                ),
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isFilled
                                      ? theme.colorScheme.primary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isFilled
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.outlineVariant,
                                    width: 1.6,
                                  ),
                                ),
                              );
                            }),
                          ),
                        const SizedBox(height: 18),
                        if (_errorMessage != null)
                          Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else
                          const SizedBox(height: 18),
                        if (settings.pinHash.isNotEmpty)
                          Column(
                            children: [
                              _buildKeypadRow(['1', '2', '3'], theme),
                              const SizedBox(height: 10),
                              _buildKeypadRow(['4', '5', '6'], theme),
                              const SizedBox(height: 10),
                              _buildKeypadRow(['7', '8', '9'], theme),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  if (settings.isBiometricEnabled)
                                    IconButton.filledTonal(
                                      tooltip: 'Unlock with biometrics',
                                      icon: const Icon(
                                        Icons.fingerprint_rounded,
                                      ),
                                      onPressed: _tryBiometricUnlock,
                                    )
                                  else
                                    const SizedBox(width: 48, height: 48),
                                  _buildKeypadButton('0', theme),
                                  IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(Icons.backspace_outlined),
                                    onPressed: _onDelete,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        if (settings.pinHash.isEmpty &&
                            settings.isBiometricEnabled)
                          FilledButton.icon(
                            onPressed: _tryBiometricUnlock,
                            icon: const Icon(Icons.fingerprint_rounded),
                            label: const Text('Unlock with biometrics'),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: 15,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Your access stays on this device',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildKeypadButton(d, theme)).toList(),
    );
  }

  Widget _buildKeypadButton(String digit, ThemeData theme) {
    return InkWell(
      onTap: () => _onKeyPress(digit),
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.surface,
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            digit,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
