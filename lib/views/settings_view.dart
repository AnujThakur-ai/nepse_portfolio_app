import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../providers/app_providers.dart';
import '../services/security_service.dart';
import '../services/storage_service.dart';
import '../theme/app_themes.dart';
import 'onboarding_view.dart';

class SettingsView extends ConsumerStatefulWidget {
  const SettingsView({super.key});

  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView> {
  final _pinController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _toggleBiometrics(bool enabled) async {
    if (enabled && !await SecurityService.canCheckBiometrics()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric unlock is not available on this device.'),
          ),
        );
      }
      return;
    }
    await ref.read(settingsProvider.notifier).toggleBiometrics(enabled);
    if (enabled) {
      ref.read(appUnlockedProvider.notifier).setUnlocked(true);
    }
  }

  void _showSetPinDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set App Security PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter a 4-digit PIN to lock your portfolio and trade logs offline.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '4-Digit PIN',
                  hintText: '••••',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _pinController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final pin = _pinController.text.trim();
                if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Enter exactly 4 digits.')),
                  );
                  return;
                }
                final hash = SecurityService.hashPin(pin);
                await ref.read(settingsProvider.notifier).setPin(hash);
                if (!mounted || !context.mounted) return;
                ref.read(appUnlockedProvider.notifier).setUnlocked(true);
                _pinController.clear();
                Navigator.pop(context);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Security PIN successfully set!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              child: const Text('Set PIN'),
            ),
          ],
        );
      },
    );
  }

  void _exportTradesCsv(ThemeData theme) {
    final trades = ref.read(tradesProvider);
    final csv = StorageService.exportTradesCsv(trades);

    _showExportResultDialog('Trades CSV Export', csv, 'csv');
  }

  void _exportPnlStatement(ThemeData theme) {
    final trades = ref.read(tradesProvider);
    final statement = StorageService.exportPnlStatement(trades);

    _showExportResultDialog('Financial PnL Statement', statement, 'statement');
  }

  Future<void> _exportJsonBackup(ThemeData theme) async {
    final backup = await StorageService.exportFullJsonBackup();
    _showExportResultDialog('Encrypted Full JSON Backup', backup, 'backup');
  }

  void _showRestoreDialog(ThemeData theme) {
    final restoreController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore Database from Backup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Paste your exported backup code below to restore trades, reminders, settings, and watchlist.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: restoreController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Paste backup string here...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final code = restoreController.text.trim();
                if (code.isNotEmpty) {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final success = await StorageService.restoreFullJsonBackup(
                    code,
                  );
                  if (mounted) {
                    navigator.pop();
                    if (success) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Database successfully restored!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Invalid backup data format'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );
  }

  void _showExportResultDialog(String title, String content, String type) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(
                content,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: content));
                HapticFeedback.mediumImpact();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title copied to clipboard!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy to Clipboard'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final currentThemeIndex = ref.watch(themeIndexProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings & Customization')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        children: [
          // Section: Theme Studio (11 Themes)
          _buildSectionHeader('11 BUILT-IN THEMES (NEPSE PALETTES)', theme),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: List.generate(AppThemes.allThemes.length, (index) {
                  final t = AppThemes.allThemes[index];
                  final isSelected = currentThemeIndex == index;

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      ref.read(themeIndexProvider.notifier).setTheme(index);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          // Color Swatches
                          Row(
                            children: [
                              _buildColorCircle(t.primary),
                              const SizedBox(width: 4),
                              _buildColorCircle(t.accent),
                              const SizedBox(width: 4),
                              _buildColorCircle(t.background),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                ),
                                Text(
                                  t.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurface
                                        .withAlpha(153),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section: Display & Layout Engine
          _buildSectionHeader('DATA DISPLAY MODES', theme),
          Card(
            child: RadioGroup<DataDisplayMode>(
              groupValue: settings.displayMode,
              onChanged: (val) {
                if (val != null) {
                  ref.read(settingsProvider.notifier).setDisplayMode(val);
                }
              },
              child: const Column(
                children: [
                  RadioListTile<DataDisplayMode>(
                    title: Text(
                      'Digital Telemetry Cards',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Crisp numerical telemetry grid with live gain indicators',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: DataDisplayMode.telemetryCards,
                  ),
                  RadioListTile<DataDisplayMode>(
                    title: Text(
                      'Interactive fl_chart Graphs',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Interactive financial charts with EMA overlays and tooltips',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: DataDisplayMode.interactiveCharts,
                  ),
                  RadioListTile<DataDisplayMode>(
                    title: Text(
                      'Analog Speedometer Gauges',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Classic analog dials for RSI, sentiment, and momentum',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: DataDisplayMode.analogGauges,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Section: Multi-Level Security
          _buildSectionHeader('SECURITY & APP LOCK', theme),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'PIN Code Protection',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    settings.isPinSecurityEnabled
                        ? 'App is locked with a secure PIN hash'
                        : 'No PIN set. Tap to configure PIN lock',
                    style: const TextStyle(fontSize: 11),
                  ),
                  value: settings.isPinSecurityEnabled,
                  onChanged: (val) {
                    if (val) {
                      _showSetPinDialog(theme);
                    } else {
                      ref.read(settingsProvider.notifier).setPin('');
                    }
                  },
                ),
                SwitchListTile(
                  title: const Text(
                    'Biometric Authentication',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Unlock app using device Fingerprint or Face ID',
                    style: TextStyle(fontSize: 11),
                  ),
                  value: settings.isBiometricEnabled,
                  onChanged: _toggleBiometrics,
                ),
                if (settings.isPinSecurityEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.lock_clock_outlined,
                      color: Colors.amber,
                    ),
                    title: const Text(
                      'Lock App Now',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Immediately trigger the PIN lock screen',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      ref.read(appUnlockedProvider.notifier).lock();
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section: Granular Notification Preferences
          _buildSectionHeader('GRANULAR NOTIFICATIONS', theme),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Price Alerts & Circuits',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: settings.notifyPriceAlerts,
                  onChanged: (val) => ref
                      .read(settingsProvider.notifier)
                      .updateNotificationPref(priceAlerts: val),
                ),
                SwitchListTile(
                  title: const Text(
                    'MACD & RSI Signal Alerts',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: settings.notifyMacdSignals,
                  onChanged: (val) => ref
                      .read(settingsProvider.notifier)
                      .updateNotificationPref(macdSignals: val),
                ),
                SwitchListTile(
                  title: const Text(
                    'ML Target Sell Date Reminders',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: settings.notifySellDateReminders,
                  onChanged: (val) => ref
                      .read(settingsProvider.notifier)
                      .updateNotificationPref(sellDateReminders: val),
                ),
                SwitchListTile(
                  title: const Text(
                    'Portfolio PnL Milestones',
                    style: TextStyle(fontSize: 13),
                  ),
                  value: settings.notifyPnlMilestones,
                  onChanged: (val) => ref
                      .read(settingsProvider.notifier)
                      .updateNotificationPref(pnlMilestones: val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section: Export & Backup Center
          _buildSectionHeader('EXPORT & BACKUP CENTER', theme),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: Row(
                    children: [
                      const Text(
                        'Financial PnL Statement',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withAlpha(38),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Recommended',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text(
                    'Full printable trade statement with commission & CGT breakdown',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () => _exportPnlStatement(theme),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.table_chart_outlined),
                  title: const Text(
                    'Export Trades CSV',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Universal spreadsheet format for Excel, Google Sheets, or Tax Audits',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () => _exportTradesCsv(theme),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_download_outlined),
                  title: const Text(
                    'Export Full Encrypted JSON Backup',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Port all trades, reminders, settings, and receipts offline',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () => _exportJsonBackup(theme),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore),
                  title: const Text(
                    'Restore Database from Backup',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Paste an existing backup string to recover your entire database',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () => _showRestoreDialog(theme),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Onboarding Tour Replay
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OnboardingView()),
              );
            },
            icon: const Icon(Icons.school_outlined),
            label: const Text('REPLAY FIRST-TIME ONBOARDING TOUR'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildColorCircle(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 1),
      ),
    );
  }
}
