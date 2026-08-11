import 'package:flutter/material.dart';

abstract final class TrackerColors {
  static const ink = Color(0xFF24242E);
  static const paper = Color(0xFFFBFAF8);
  static const muted = Color(0xFF858590);
  static const border = Color(0xFFEBE9E5);
  static const violet = Color(0xFF7365DB);
  static const deepViolet = Color(0xFF5749BD);
  static const lavender = Color(0xFFEDEAFF);
  static const cream = Color(0xFFFFF8E9);
  static const coral = Color(0xFFE57861);
  static const mint = Color(0xFF66B897);
  static const gold = Color(0xFFB8892E);
  static const brightGold = Color(0xFFD7A940);
  static const softGold = Color(0xFFF4EAD2);
  static const graphite = Color(0xFF24231F);
  static const fog = Color(0xFFF1EFEA);
  static const darkPage = Color(0xFF17151D);
  static const darkCard = Color(0xFF24212B);
  static const darkBorder = Color(0xFF403A49);
}

abstract final class TrackerTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final colors = ColorScheme(
      brightness: brightness,
      primary: dark ? TrackerColors.brightGold : TrackerColors.gold,
      onPrimary: dark ? TrackerColors.graphite : Colors.white,
      secondary: TrackerColors.violet,
      onSecondary: Colors.white,
      error: dark ? const Color(0xFFFFA899) : const Color(0xFFB74432),
      onError: Colors.white,
      surface: dark ? TrackerColors.darkCard : Colors.white,
      onSurface: dark ? const Color(0xFFF5F1F8) : TrackerColors.ink,
    );
    final base = ThemeData(
      colorScheme: colors,
      brightness: brightness,
      useMaterial3: true,
    );
    final borderColor = dark ? TrackerColors.darkBorder : TrackerColors.border;
    return base.copyWith(
      scaffoldBackgroundColor: dark
          ? TrackerColors.darkPage
          : TrackerColors.paper,
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(
          fontFamily: 'serif',
          fontWeight: FontWeight.w700,
          letterSpacing: -2.2,
          height: .98,
        ),
        displayMedium: base.textTheme.displayMedium?.copyWith(
          fontFamily: 'serif',
          fontWeight: FontWeight.w700,
          letterSpacing: -1.5,
        ),
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontFamily: 'serif',
          fontWeight: FontWeight.w700,
          letterSpacing: -.8,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontFamily: 'serif',
          fontWeight: FontWeight.w700,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.45),
        labelSmall: base.textTheme.labelSmall?.copyWith(
          fontFamily: 'monospace',
          letterSpacing: 1.8,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: dark ? TrackerColors.darkCard : Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: borderColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF201C27) : const Color(0xFFF9F8FA),
        hintStyle: TextStyle(
          color: dark ? const Color(0xFFA9A1B1) : TrackerColors.muted,
        ),
        labelStyle: TextStyle(
          color: dark ? const Color(0xFFD7CFDC) : TrackerColors.ink,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark ? TrackerColors.brightGold : TrackerColors.violet,
            width: 1.7,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: dark ? const Color(0xFF1F1D22) : Colors.white,
        indicatorColor: dark ? const Color(0xFF4B3E23) : TrackerColors.softGold,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 10.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? (dark ? TrackerColors.brightGold : TrackerColors.gold)
                : (dark ? const Color(0xFFC7C1CC) : TrackerColors.muted),
          ),
        ),
      ),
      dividerColor: borderColor,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? const Color(0xFF332E38) : TrackerColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: base.chipTheme.copyWith(
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
