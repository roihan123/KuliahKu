import 'package:flutter/material.dart';

/// Palet warna aplikasi KuliahKu.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF2A2D43);
  static const Color primaryLight = Color(0xFFC5C8F0);
  static const Color darkSurface = Color(0xFF23243A);
  static const Color darkCard = Color(0xFF2A2D43);

  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color caution = Color(0xFFD97706);
  static const Color info = Color(0xFF3B82F6);

  static const Color taskEvent = Color(0xFFF97316);
  static const Color classEvent = Color(0xFF7C3AED);
}

/// Tema terang & gelap. Dibuat sekali (static final) agar tidak di-rebuild
/// setiap kali MaterialApp dibangun ulang.
class AppTheme {
  AppTheme._();

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? AppColors.primaryLight : AppColors.primary,
      onPrimary: isDark ? AppColors.darkSurface : Colors.white,
      secondary: Colors.blueAccent,
      surface: isDark ? AppColors.darkSurface : Colors.white,
      onSurface: isDark ? Colors.white : const Color(0xFF1F2030),
      onSurfaceVariant: isDark ? const Color(0xFFB4B6CC) : const Color(0xFF6B6B7E),
      surfaceContainerLowest: isDark ? const Color(0xFF1E1F33) : Colors.white,
      surfaceContainerLow: isDark ? AppColors.darkCard : const Color(0xFFF7F7F9),
      surfaceContainer: isDark ? const Color(0xFF30334B) : const Color(0xFFF1F1F4),
      surfaceContainerHigh: isDark ? const Color(0xFF383B55) : const Color(0xFFEAEAEE),
      surfaceContainerHighest: isDark ? const Color(0xFF41445F) : const Color(0xFFE3E3E8),
      outlineVariant: isDark ? const Color(0xFF3E4160) : const Color(0xFFE3E3E8),
    );

    final radius = BorderRadius.circular(12);
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkCard : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(scheme.outlineVariant),
        enabledBorder: border(scheme.outlineVariant),
        focusedBorder: border(scheme.primary, 1.6),
        errorBorder: border(scheme.error),
        focusedErrorBorder: border(scheme.error, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: radius),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        elevation: 3,
        height: 68,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    );
  }
}
