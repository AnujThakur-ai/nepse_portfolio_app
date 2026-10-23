import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/app_providers.dart';
import 'services/storage_service.dart';
import 'views/dashboard_view.dart';
import 'views/onboarding_view.dart';
import 'views/security_lock_view.dart';

void main() {
  runApp(const ProviderScope(child: NepseApp()));
}

class NepseApp extends ConsumerStatefulWidget {
  const NepseApp({super.key});

  @override
  ConsumerState<NepseApp> createState() => _NepseAppState();
}

class _NepseAppState extends ConsumerState<NepseApp> {
  bool _startupReady = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final settings = await StorageService.loadSettings();
    ref.read(settingsProvider.notifier).updateSettings(settings);
    final shouldLock = settings.isPinSecurityEnabled && settings.pinHash.isNotEmpty;
    ref.read(securityLockProvider.notifier).setLocked(shouldLock);
    setState(() {
      _startupReady = true;
    });
  }

  void _handleOnboardingComplete() {
    final settings = ref.read(settingsProvider);
    final shouldLock = settings.isPinSecurityEnabled && settings.pinHash.isNotEmpty;
    ref.read(securityLockProvider.notifier).setLocked(shouldLock);
    setState(() {
      _startupReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    if (!_startupReady) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: 'NEPSE Portfolio Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1D4ED8),
      ),
      home: SecurityLockView(
        child: settings.hasCompletedOnboarding
            ? const DashboardView()
            : OnboardingView(onComplete: _handleOnboardingComplete),
      ),
    );
  }
}
