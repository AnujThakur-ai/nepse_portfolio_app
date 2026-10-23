import 'package:flutter/material.dart';

class ThemeConfig {
  final String name;
  final String description;
  final Color primary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color cardBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color positiveColor; // Bullish
  final Color negativeColor; // Bearish
  final bool isDark;
  final ThemeData themeData;

  const ThemeConfig({
    required this.name,
    required this.description,
    required this.primary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.cardBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.positiveColor,
    required this.negativeColor,
    required this.isDark,
    required this.themeData,
  });
}

class AppThemes {
  static final List<ThemeConfig> allThemes = [
    // 1. NEPSE Standard Classic Dark
    _buildTheme(
      index: 0,
      name: 'NEPSE Classic Dark',
      description:
          'Default market theme with neon cyber cyan and emerald accents',
      primary: const Color(0xFF06B6D4), // Cyan neon
      accent: const Color(0xFF10B981), // Emerald
      background: const Color(0xFF0F172A), // Slate 900
      surface: const Color(0xFF1E293B), // Slate 800
      cardBackground: const Color(0xFF1E293B),
      textPrimary: const Color(0xFFF8FAFC),
      textSecondary: const Color(0xFF94A3B8),
      positiveColor: const Color(0xFF10B981),
      negativeColor: const Color(0xFFEF4444),
      isDark: true,
    ),

    // 2. Cyberpunk Neon Green/Purple
    _buildTheme(
      index: 1,
      name: 'Cyberpunk Neon',
      description:
          'Radioactive violet and electric lime green for high-octane trading',
      primary: const Color(0xFF00FF66), // Electric Lime
      accent: const Color(0xFFA855F7), // Neon Purple
      background: const Color(0xFF090014), // Deep void
      surface: const Color(0xFF19002E),
      cardBackground: const Color(0xFF22003D),
      textPrimary: const Color(0xFF00FFCC),
      textSecondary: const Color(0xFFC084FC),
      positiveColor: const Color(0xFF00FF66),
      negativeColor: const Color(0xFFFF0055),
      isDark: true,
    ),

    // 3. Midnight OLED Pitch Black
    _buildTheme(
      index: 2,
      name: 'Midnight OLED',
      description:
          'Zero battery drain pure pitch-black with crisp sapphire telemetry',
      primary: const Color(0xFF3B82F6), // Sapphire Blue
      accent: const Color(0xFF60A5FA),
      background: const Color(0xFF000000), // Pure Black
      surface: const Color(0xFF111111),
      cardBackground: const Color(0xFF141416),
      textPrimary: const Color(0xFFFFFFFF),
      textSecondary: const Color(0xFF888888),
      positiveColor: const Color(0xFF22C55E),
      negativeColor: const Color(0xFFF43F5E),
      isDark: true,
    ),

    // 4. Nordic Ice Blue
    _buildTheme(
      index: 3,
      name: 'Nordic Ice Blue',
      description: 'Calm arctic navy with glacier cyan highlights and frosty glass cards',
      primary: const Color(0xFF38BDF8), // Glacier sky
      accent: const Color(0xFF818CF8), // Indigo
      background: const Color(0xFF081426), // Arctic Navy
      surface: const Color(0xFF0F2342),
      cardBackground: const Color(0xFF162D50),
      textPrimary: const Color(0xFFE0F2FE),
      textSecondary: const Color(0xFF7DD3FC),
      positiveColor: const Color(0xFF34D399),
      negativeColor: const Color(0xFFFB7185),
      isDark: true,
    ),

    // 5. Emerald Bull Market Green
    _buildTheme(
      index: 4,
      name: 'Emerald Bull Market',
      description: 'Radiant jade green celebrating unstoppable NEPSE bull runs',
      primary: const Color(0xFF10B981), // Emerald
      accent: const Color(0xFFF59E0B), // Gold
      background: const Color(0xFF041E15), // Deep Forest
      surface: const Color(0xFF063324),
      cardBackground: const Color(0xFF0A4432),
      textPrimary: const Color(0xFFECFDF5),
      textSecondary: const Color(0xFF6EE7B7),
      positiveColor: const Color(0xFF34D399),
      negativeColor: const Color(0xFFF87171),
      isDark: true,
    ),

    // 6. Crimson Bear Market Red
    _buildTheme(
      index: 5,
      name: 'Crimson Bear Market',
      description: 'Deep ruby and fiery burgundy for vigilant risk management',
      primary: const Color(0xFFEF4444), // Ruby Red
      accent: const Color(0xFFF97316), // Orange
      background: const Color(0xFF1A0707), // Deep Wine
      surface: const Color(0xFF2E0D0D),
      cardBackground: const Color(0xFF3E1212),
      textPrimary: const Color(0xFFFEF2F2),
      textSecondary: const Color(0xFFFCA5A5),
      positiveColor: const Color(0xFF10B981),
      negativeColor: const Color(0xFFEF4444),
      isDark: true,
    ),

    // 7. Solar Flare Amber
    _buildTheme(
      index: 6,
      name: 'Solar Flare Amber',
      description:
          'Molten gold and cosmic amber telemetry for maximum readability',
      primary: const Color(0xFFF59E0B), // Molten Amber
      accent: const Color(0xFFFB923C), // Warm Orange
      background: const Color(0xFF17120B),
      surface: const Color(0xFF291E12),
      cardBackground: const Color(0xFF362818),
      textPrimary: const Color(0xFFFEF3C7),
      textSecondary: const Color(0xFFFCD34D),
      positiveColor: const Color(0xFF4ADE80),
      negativeColor: const Color(0xFFF87171),
      isDark: true,
    ),

    // 8. Monochrome Slate Minimalist
    _buildTheme(
      index: 7,
      name: 'Monochrome Slate',
      description: 'Neutral titanium and zinc tones for a clean, distraction-free cockpit',
      primary: const Color(0xFFE4E4E7), // Zinc Light
      accent: const Color(0xFFA1A1AA),
      background: const Color(0xFF121214),
      surface: const Color(0xFF1C1C21),
      cardBackground: const Color(0xFF25252C),
      textPrimary: const Color(0xFFFAFAFA),
      textSecondary: const Color(0xFFA1A1AA),
      positiveColor: const Color(0xFF22C55E),
      negativeColor: const Color(0xFFEF4444),
      isDark: true,
    ),

    // 9. Material Design 3 Light
    _buildTheme(
      index: 8,
      name: 'Material 3 Light',
      description: 'Crisp alpine white with sharp royal blue for bright daylight viewing',
      primary: const Color(0xFF2563EB), // Royal Blue
      accent: const Color(0xFF0D9488), // Teal
      background: const Color(0xFFF8FAFC), // Alpine White
      surface: const Color(0xFFFFFFFF),
      cardBackground: const Color(0xFFFFFFFF),
      textPrimary: const Color(0xFF0F172A),
      textSecondary: const Color(0xFF475569),
      positiveColor: const Color(0xFF16A34A),
      negativeColor: const Color(0xFFDC2626),
      isDark: false,
    ),

    // 10. Retro Terminal Amber/Phosphor
    _buildTheme(
      index: 9,
      name: 'Retro CRT Terminal',
      description:
          'Classic 1980s stock exchange Bloomberg terminal phosphor glow',
      primary: const Color(0xFFFFB000), // Amber CRT Phosphor
      accent: const Color(0xFF33FF33), // Green Phosphor
      background: const Color(0xFF080C08), // Dark Monitor Glass
      surface: const Color(0xFF101710),
      cardBackground: const Color(0xFF142014),
      textPrimary: const Color(0xFFFFB000),
      textSecondary: const Color(0xFFCC8C00),
      positiveColor: const Color(0xFF33FF33),
      negativeColor: const Color(0xFFFF3333),
      isDark: true,
    ),

    // 11. Alpine Portfolio Light
    _buildTheme(
      index: 10,
      name: 'Alpine Portfolio Light',
      description: 'Airy portfolio cards with confident blue and teal accents',
      primary: const Color(0xFF315CE8),
      accent: const Color(0xFF0B9B88),
      background: const Color(0xFFF3F6FC),
      surface: const Color(0xFFFFFFFF),
      cardBackground: const Color(0xFFFFFFFF),
      textPrimary: const Color(0xFF18243A),
      textSecondary: const Color(0xFF68758B),
      positiveColor: const Color(0xFF128466),
      negativeColor: const Color(0xFFD94F62),
      isDark: false,
    ),
  ];

  static ThemeConfig getTheme(int index) {
    if (index < 0 || index >= allThemes.length) {
      return allThemes[0];
    }
    return allThemes[index];
  }

  static ThemeConfig _buildTheme({
    required int index,
    required String name,
    required String description,
    required Color primary,
    required Color accent,
    required Color background,
    required Color surface,
    required Color cardBackground,
    required Color textPrimary,
    required Color textSecondary,
    required Color positiveColor,
    required Color negativeColor,
    required bool isDark,
  }) {
    final baseColorScheme = isDark
        ? ColorScheme.dark(
            primary: primary,
            secondary: accent,
            surface: surface,
            error: negativeColor,
            onPrimary: isDark ? Colors.black : Colors.white,
            onSecondary: Colors.black,
            onSurface: textPrimary,
          )
        : ColorScheme.light(
            primary: primary,
            secondary: accent,
            surface: surface,
            error: negativeColor,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: textPrimary,
          );

    final themeData = ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: baseColorScheme,
      cardColor: cardBackground,
      canvasColor: background,
      dialogTheme: DialogThemeData(backgroundColor: surface),
      dividerColor: textSecondary.withAlpha(51),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shadowColor: Colors.black.withAlpha(77),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primary.withAlpha(38), width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withAlpha(51),
        secondarySelectedColor: primary,
        labelStyle: TextStyle(color: textPrimary, fontSize: 12),
        secondaryLabelStyle: TextStyle(color: primary, fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: primary.withAlpha(51)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: isDark && primary != const Color(0xFFE4E4E7)
              ? Colors.black
              : Colors.white,
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: textSecondary.withAlpha(179), fontSize: 14),
        labelStyle: TextStyle(color: textSecondary, fontSize: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textSecondary.withAlpha(51)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: negativeColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: negativeColor, width: 2),
        ),
      ),
    );

    return ThemeConfig(
      name: name,
      description: description,
      primary: primary,
      accent: accent,
      background: background,
      surface: surface,
      cardBackground: cardBackground,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      positiveColor: positiveColor,
      negativeColor: negativeColor,
      isDark: isDark,
      themeData: themeData,
    );
  }
}
