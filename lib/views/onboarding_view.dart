import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/security_service.dart';

class OnboardingView extends ConsumerStatefulWidget {
  final VoidCallback onComplete;

  const OnboardingView({super.key, required this.onComplete});

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
    final settings = ref.read(settingsProvider);
    final pinHash = settings.pinHash;

    await ref.read(settingsProvider.notifier).updateNotificationPreferences(
      priceAlerts: _notifyPrice,
      macdSignals: _notifyMacd,
      sellDateReminders: _notifySell,
      pnlMilestones: _notifyPnl,
    );

    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (pinHash.isEmpty) {
      ref.read(securityLockProvider.notifier).setLocked(false);
    }
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_currentPage + 1} of 4',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    child: const Text('Skip Tour'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildTourStep(
                    icon: Icons.account_balance,
                    iconColor: theme.colorScheme.primary,
                    title: 'NEPSE Portfolio Analyzer',
                    subtitle:
                        'Track holdings, forecast targets, and manage risk in one practical dashboard.',
                    featureBullets: const [
                      'Portfolio tracking for Nepal stock holdings',
                      'Risk-aware sell targets and portfolio metrics',
                      'Offline-first behavior with local persistence',
                    ],
                    theme: theme,
                  ),
                  _buildTourStep(
                    icon: Icons.show_chart,
                    iconColor: Colors.green,
                    title: 'Performance & Strategy',
                    subtitle:
                        'Understand portfolio gains, price movement, and trade performance over time.',
                    featureBullets: const [
                      'Real-time style portfolio summary',
                      'Holding performance and PnL insights',
                      'Quick trade and market scan workflow',
                    ],
                    theme: theme,
                  ),
                  _buildTourStep(
                    icon: Icons.calendar_month,
                    iconColor: Colors.orange,
                    title: 'Dual Calendar & Reminders',
                    subtitle:
                        'Keep investment milestones and reminders aligned with both AD and BS date systems.',
                    featureBullets: const [
                      'Reminder tracking for important deadlines',
                      'AD/BS friendly planning',
                      'Calendar-driven portfolio discipline',
                    ],
                    theme: theme,
                  ),
                  _buildSecurityStep(theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(4, (index) {
                      final active = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        width: active ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withAlpha(120),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 3) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                        return;
                      }
                      _finishOnboarding();
                    },
                    child: Text(_currentPage == 3 ? 'Get Started' : 'Next'),
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
              color: iconColor.withAlpha(40),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 52, color: iconColor),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withAlpha(180),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: featureBullets
                    .map(
                      (bullet) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                bullet,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStep(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            size: 56,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 20),
          const Text(
            'Security setup',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose how you want to protect your portfolio app.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withAlpha(180),
            ),
          ),
          const SizedBox(height: 24),
          _buildToggleRow(
            label: 'Price alerts',
            value: _notifyPrice,
            onChanged: (value) => setState(() => _notifyPrice = value),
          ),
          _buildToggleRow(
            label: 'MACD signals',
            value: _notifyMacd,
            onChanged: (value) => setState(() => _notifyMacd = value),
          ),
          _buildToggleRow(
            label: 'Sell reminders',
            value: _notifySell,
            onChanged: (value) => setState(() => _notifySell = value),
          ),
          _buildToggleRow(
            label: 'PnL milestones',
            value: _notifyPnl,
            onChanged: (value) => setState(() => _notifyPnl = value),
          ),
          const SizedBox(height: 8),
          FutureBuilder<bool>(
            future: SecurityService.canCheckBiometrics(),
            builder: (context, snapshot) {
              final supported = snapshot.data ?? false;
              if (!supported) {
                return const Text('Biometric unlock is not available on this device.');
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
