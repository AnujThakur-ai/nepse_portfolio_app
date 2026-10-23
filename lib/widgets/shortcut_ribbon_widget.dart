import 'package:flutter/material.dart';

class ShortcutActionItem {
  final String id;
  final String label;
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;

  const ShortcutActionItem({
    required this.id,
    required this.label,
    required this.icon,
    this.color,
    required this.onTap,
  });
}

class ShortcutRibbonWidget extends StatelessWidget {
  final List<ShortcutActionItem> actions;

  const ShortcutRibbonWidget({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 78,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = actions[index];
          final btnColor = item.color ?? theme.colorScheme.primary;

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(14),
              child: Ink(
                width: 110,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: btnColor.withAlpha(51), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: btnColor.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: btnColor.withAlpha(38),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(item.icon, size: 18, color: btnColor),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
