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
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final nepDate = BikramSambatService.adToBs(now);
    final isMarketOpen = BikramSambatService.isNepseOpen(now);

    return AppBar(
      toolbarHeight: 68,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 18,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'NEPSE',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 7),
              AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isMarketOpen
                      ? const Color(0xFF10B981).withAlpha(24)
                      : theme.colorScheme.error.withAlpha(24),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(scale: animation, child: child),
                  ),
                  child: Row(
                    key: ValueKey(isMarketOpen),
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
                      const SizedBox(width: 5),
                      Text(
                        isMarketOpen ? 'OPEN' : 'CLOSED',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.25,
                          fontWeight: FontWeight.w800,
                          color: isMarketOpen
                              ? const Color(0xFF10B981)
                              : theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '${nepDate.formatBs()} • ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} AD',
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withAlpha(145),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.primary.withAlpha(18),
            foregroundColor: theme.colorScheme.primary,
            fixedSize: const Size(40, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.search_rounded, size: 20),
          tooltip: 'Search NEPSE Tickers',
          onPressed: onSearchTap,
        ),
        IconButton(
          style: IconButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceContainerHighest
                .withAlpha(120),
            foregroundColor: theme.colorScheme.onSurface,
            fixedSize: const Size(40, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.tune_rounded, size: 20),
          tooltip: 'Settings, 10 Themes & Backups',
          onPressed: onThemeTap,
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
