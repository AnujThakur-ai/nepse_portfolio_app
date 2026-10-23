import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _notifyPrice = true;
  bool _notifyMacd = true;
  bool _notifySell = true;
  bool _notifyPnl = true;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    await ref
        .read(settingsProvider.notifier)
        .updateNotificationPref(
          priceAlerts: _notifyPrice,
          macdSignals: _notifyMacd,
          sellDateReminders: _notifySell,
          pnlMilestones: _notifyPnl,
        );
    await ref.read(settingsProvider.notifier).completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_currentPage + 1} of 4',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text('Skip Tour'),
                  ),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  // Step 1: Welcome & Offline Engine
                  _buildTourStep(
                    icon: Icons.account_balance,
                    iconColor: theme.colorScheme.primary,
                    title: 'NEPSE Portfolio & Trading Analyzer',
                    subtitle: 'A 100% offline-first, free-of-cost cockpit engineered specifically for Nepal Stock Exchange (NEPSE) traders and investors.',
                    featureBullets: [
                      'Accurate NEPSE Broker Slab & SEBON Fee calculations',
                      'Capital Gains Tax (CGT) rules for short-term and long-term holds',
                      'Local offline storage and portable JSON backup',
                    ],
                    theme: theme,
                  ),

                  // Step 2: Technical indicators and rule-based estimates.
                  _buildTourStep(
                    icon: Icons.psychology,
                    iconColor: const Color(0xFF10B981),
                    title: 'Technical Indicators & Holding Estimates',
                    subtitle: 'Review on-device technical indicators and rule-based holding period estimates. These are informational estimates, not predictions from a trained model.',
                    featureBullets: [
                      'MACD (12, 26, 9) histogram & bullish/bearish crossovers',
                      'RSI 14-period Wilder smoothing with analog gauges',
                      'Rule-based holding period and target date estimates',
                    ],
                    theme: theme,
                  ),

                  // Step 3: Dual Calendar (AD / BS)
                  _buildTourStep(
                    icon: Icons.calendar_month,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Native Bikram Sambat (BS) Dual Calendar',
                    subtitle: 'Effortlessly convert between Gregorian (AD) and Bikram Sambat (BS) dates for all holding targets, dividends, and AGMs.',
                    featureBullets: [
                      'Exact Nepali calendar days (Baisakh to Chaitra)',
                      'NEPSE trading hours detector (Sun-Thu 11 AM - 3 PM)',
                      'In-app reminders for target dates, dividends, and AGMs',
                    ],
                    theme: theme,
                  ),

                  // Step 4: Notification Permission Selector
                  _buildNotificationStep(theme),
                ],
              ),
            ),

            // Bottom Navigation & Dots
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dots
                  Row(
                    children: List.generate(4, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),

                  // Next / Done Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 3) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _finishOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(_currentPage == 3 ? 'GET STARTED' : 'NEXT'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTourStep({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required List<String> featureBullets,
    required ThemeData theme,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 54, color: iconColor),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withAlpha(179),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: featureBullets.map((bullet) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bullet,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Granular Notification Permissions',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose which NEPSE trading events trigger on-device notifications:',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Column(
              children: [
                CheckboxListTile(
                  title: const Text(
                    'Price Alerts & Circuit Breakers',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _notifyPrice,
                  onChanged: (val) =>
                      setState(() => _notifyPrice = val ?? true),
                ),
                CheckboxListTile(
                  title: const Text(
                    'MACD Golden Cross & RSI Signals',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _notifyMacd,
                  onChanged: (val) => setState(() => _notifyMacd = val ?? true),
                ),
                CheckboxListTile(
                  title: const Text(
                    'ML Target Sell Date Deadlines',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _notifySell,
                  onChanged: (val) => setState(() => _notifySell = val ?? true),
                ),
                CheckboxListTile(
                  title: const Text(
                    'Portfolio PnL Milestone Alerts',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _notifyPnl,
                  onChanged: (val) => setState(() => _notifyPnl = val ?? true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
