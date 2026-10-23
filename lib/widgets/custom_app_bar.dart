import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/bikram_sambat_service.dart';

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final VoidCallback onSearchTap;
  final VoidCallback onThemeTap;

  const CustomAppBar({
    super.key,
    required this.onSearchTap,
    required this.onThemeTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final nepDate = BikramSambatService.adToBs(now);
    final isMarketOpen = BikramSambatService.isNepseOpen(now);

    return AppBar(
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'NEPSE ANALYZER',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              // Live Market Indicator Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isMarketOpen
                      ? const Color(0xFF10B981).withAlpha(38)
                      : theme.colorScheme.error.withAlpha(38),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isMarketOpen
                        ? const Color(0xFF10B981)
                        : theme.colorScheme.error,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isMarketOpen
                            ? const Color(0xFF10B981)
                            : theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isMarketOpen ? 'LIVE' : 'CLOSED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isMarketOpen
                            ? const Color(0xFF10B981)
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${nepDate.formatBs()} • ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} AD',
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withAlpha(166),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, size: 22),
          tooltip: 'Search NEPSE Tickers',
          onPressed: onSearchTap,
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 22),
          tooltip: 'Settings, 10 Themes & Backups',
          onPressed: onThemeTap,
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
