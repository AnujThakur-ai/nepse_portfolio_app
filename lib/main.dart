import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/app_providers.dart';
import 'views/dashboard_view.dart';
import 'views/onboarding_view.dart';
import 'views/security_lock_view.dart';

class AiryScrollBehavior extends MaterialScrollBehavior {
  const AiryScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: NepseApp()));
}

class NepseApp extends ConsumerWidget {
  const NepseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(appStartupProvider);
    final currentTheme = ref.watch(currentThemeProvider);
    final settings = ref.watch(settingsProvider);

    if (startup.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: currentTheme.themeData,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    if (startup.hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load saved app data.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(appStartupProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'NEPSE ML Trading & Portfolio Analyzer',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AiryScrollBehavior(),
      theme: currentTheme.themeData.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.linux: ZoomPageTransitionsBuilder(),
            TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          },
        ),
      ),
      home: SecurityLockView(
        child: settings.hasCompletedOnboarding
            ? const DashboardView()
            : const OnboardingView(),
      ),
    );
  }
}
