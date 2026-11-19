import 'package:flutter/material.dart';

import 'tokens.dart';

/// A style pinned to the bundled body font. Component styles (buttons, chips, nav labels)
/// do not inherit the theme's font, and without one Flutter web downloads Roboto.
TextStyle _ui(TextStyle s) => s.copyWith(fontFamily: AppTokens.body);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: AppTokens.violet,
    onPrimary: Colors.white,
    secondary: AppTokens.cyan,
    onSecondary: AppTokens.ink,
    tertiary: AppTokens.pink,
    onTertiary: Colors.white,
    error: const Color(0xFFFF6B81),
    onError: Colors.white,
    surface: dark ? AppTokens.ink : AppTokens.paper,
    onSurface: dark ? AppTokens.text : AppTokens.inkText,
    onSurfaceVariant: dark ? AppTokens.muted : AppTokens.inkMuted,
    surfaceContainerLowest: dark ? const Color(0xFF080C18) : Colors.white,
    surfaceContainerLow: dark ? AppTokens.surface : Colors.white,
    surfaceContainer: dark ? AppTokens.surface : const Color(0xFFEEF0F7),
    surfaceContainerHigh: dark ? AppTokens.surfaceHigh : const Color(0xFFE6E9F3),
    surfaceContainerHighest: dark ? const Color(0xFF232E50) : const Color(0xFFDDE1EE),
    outline: dark ? const Color(0x33FFFFFF) : const Color(0x1F0E1326),
    outlineVariant: dark ? const Color(0x1AFFFFFF) : const Color(0x140E1326),
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, fontFamily: AppTokens.body);
  TextStyle display(TextStyle? s, double size, FontWeight w) =>
      (s ?? const TextStyle()).copyWith(fontFamily: AppTokens.display, fontSize: size, fontWeight: w, letterSpacing: -0.5, height: 1.1);

  final text = base.textTheme.copyWith(
    displayLarge: display(base.textTheme.displayLarge, 64, FontWeight.w700),
    displayMedium: display(base.textTheme.displayMedium, 48, FontWeight.w700),
    displaySmall: display(base.textTheme.displaySmall, 36, FontWeight.w700),
    headlineMedium: display(base.textTheme.headlineMedium, 28, FontWeight.w700),
    headlineSmall: display(base.textTheme.headlineSmall, 22, FontWeight.w700),
    titleLarge: display(base.textTheme.titleLarge, 20, FontWeight.w500),
    titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  );

  final field = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
    borderSide: BorderSide(color: scheme.outline),
  );

  return base.copyWith(
    textTheme: text,
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(textStyle: _ui(const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)))),
    segmentedButtonTheme: SegmentedButtonThemeData(style: SegmentedButton.styleFrom(textStyle: _ui(const TextStyle(fontWeight: FontWeight.w600)))),
    scaffoldBackgroundColor: scheme.surface,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radius),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? const Color(0x0DFFFFFF) : Colors.white,
      border: field,
      enabledBorder: field,
      focusedBorder: field.copyWith(borderSide: const BorderSide(color: AppTokens.violet, width: 1.6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: _ui(const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        side: BorderSide(color: scheme.outline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: _ui(const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: StadiumBorder(side: BorderSide(color: scheme.outline)),
      backgroundColor: dark ? const Color(0x0DFFFFFF) : Colors.white,
      selectedColor: AppTokens.violet.withValues(alpha: 0.25),
      labelStyle: _ui(TextStyle(color: scheme.onSurface, fontWeight: FontWeight.w500)),
      side: BorderSide(color: scheme.outline),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xE60B1020) : const Color(0xF2FFFFFF),
      indicatorColor: AppTokens.violet.withValues(alpha: 0.22),
      labelTextStyle: WidgetStatePropertyAll(_ui(TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface))),
      height: 68,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: AppTokens.violet.withValues(alpha: 0.22),
      selectedLabelTextStyle: _ui(TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface)),
      unselectedLabelTextStyle: _ui(TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? AppTokens.surfaceHigh : AppTokens.inkText,
      contentTextStyle: _ui(const TextStyle(color: Colors.white)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
    }),
  );
}
