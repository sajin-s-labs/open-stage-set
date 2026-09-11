import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available Monochrome Theme Modes
enum AppThemeMode {
  oledDark,
  grayscale,
  light,
}

/// Centralized Monochrome, Grayscale & OLED Dark color palette
class AppColors {
  // Pure OLED pitch black
  static const Color oledBlack = Color(0xFF000000);
  // Pure White
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Dark OLED Palette (True pitch black #000000)
  static const Color darkBackground = oledBlack;
  static const Color darkSurface = Color(0xFF0A0A0A);
  static const Color darkSurfaceVariant = Color(0xFF141414);
  static const Color darkBorder = Color(0xFF222222);
  static const Color darkDivider = Color(0xFF1C1C1C);
  static const Color darkTextPrimary = Color(0xFFEDEDED);
  static const Color darkTextSecondary = Color(0xFF7A7A7A);
  static const Color darkIcon = Color(0xFFEDEDED);

  // Grayscale Palette (Neutral slate/charcoal greys, non-pitch-black)
  static const Color grayscaleBackground = Color(0xFF1C1C1C);
  static const Color grayscaleSurface = Color(0xFF262626);
  static const Color grayscaleSurfaceVariant = Color(0xFF333333);
  static const Color grayscaleBorder = Color(0xFF3D3D3D);
  static const Color grayscaleDivider = Color(0xFF303030);
  static const Color grayscaleTextPrimary = Color(0xFFF0F0F0);
  static const Color grayscaleTextSecondary = Color(0xFFA0A0A0);
  static const Color grayscaleIcon = Color(0xFFF0F0F0);

  // Light Monochrome Palette (Clean white & neutral greys)
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFF6F6F6);
  static const Color lightSurfaceVariant = Color(0xFFEDEDED);
  static const Color lightBorder = Color(0xFFE2E2E2);
  static const Color lightDivider = Color(0xFFEEEEEE);
  static const Color lightTextPrimary = Color(0xFF121212);
  static const Color lightTextSecondary = Color(0xFF6E6E6E);
  static const Color lightIcon = Color(0xFF121212);
}

/// Global theme management and themes for Open Stage Set
class AppTheme {
  static const String _prefThemeKey = 'open_stage_set_theme_mode';

  /// Global AppThemeMode notifier to switch themes from anywhere in the app
  static final ValueNotifier<AppThemeMode> currentThemeMode =
      ValueNotifier<AppThemeMode>(AppThemeMode.light);

  /// Load persisted theme on app startup
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefThemeKey);
      if (savedMode != null) {
        currentThemeMode.value = AppThemeMode.values.firstWhere(
          (m) => m.name == savedMode,
          orElse: () => AppThemeMode.light,
        );
      }
    } catch (e) {
      debugPrint('Failed to load theme preference: $e');
    }
  }

  /// Set explicit theme mode and save to persistent storage
  static void setTheme(AppThemeMode mode) {
    currentThemeMode.value = mode;
    _saveTheme(mode);
  }

  static Future<void> _saveTheme(AppThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefThemeKey, mode.name);
    } catch (e) {
      debugPrint('Failed to save theme preference: $e');
    }
  }

  /// Cycle through available themes: OLED Dark -> Grayscale -> Light -> OLED Dark
  static void cycleTheme() {
    switch (currentThemeMode.value) {
      case AppThemeMode.oledDark:
        setTheme(AppThemeMode.grayscale);
        break;
      case AppThemeMode.grayscale:
        setTheme(AppThemeMode.light);
        break;
      case AppThemeMode.light:
        setTheme(AppThemeMode.oledDark);
        break;
    }
  }

  /// Toggle alias for compatibility
  static void toggleTheme() => cycleTheme();

  /// Check if the active theme is dark-oriented
  static bool get isDark => currentThemeMode.value != AppThemeMode.light;

  /// Get ThemeData for a specific AppThemeMode
  static ThemeData getTheme(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.oledDark:
        return darkTheme;
      case AppThemeMode.grayscale:
        return grayscaleTheme;
      case AppThemeMode.light:
        return lightTheme;
    }
  }

  /// Pure OLED Dark Theme (Monochrome pitch black #000000)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.oledBlack,
      canvasColor: AppColors.oledBlack,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.darkDivider,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.oledBlack,
        onSurface: AppColors.darkTextPrimary,
        primary: AppColors.pureWhite,
        onPrimary: AppColors.oledBlack,
        secondary: AppColors.darkTextSecondary,
        onSecondary: AppColors.oledBlack,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
        outline: AppColors.darkBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.oledBlack,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.oledBlack,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        iconTheme: IconThemeData(color: AppColors.pureWhite),
        actionsIconTheme: IconThemeData(color: AppColors.pureWhite),
        titleTextStyle: TextStyle(
          color: AppColors.pureWhite,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.oledBlack,
        scrimColor: Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.darkBorder, width: 0.5),
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.pureWhite,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Grayscale Theme (Neutral slate/charcoal greys, non-pitch-black)
  static ThemeData get grayscaleTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.grayscaleBackground,
      canvasColor: AppColors.grayscaleBackground,
      cardColor: AppColors.grayscaleSurface,
      dividerColor: AppColors.grayscaleDivider,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.grayscaleBackground,
        onSurface: AppColors.grayscaleTextPrimary,
        primary: AppColors.pureWhite,
        onPrimary: AppColors.grayscaleBackground,
        secondary: AppColors.grayscaleTextSecondary,
        onSecondary: AppColors.grayscaleBackground,
        surfaceContainerHighest: AppColors.grayscaleSurfaceVariant,
        outline: AppColors.grayscaleBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.grayscaleBackground,
        foregroundColor: AppColors.pureWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.grayscaleBackground,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        iconTheme: IconThemeData(color: AppColors.pureWhite),
        actionsIconTheme: IconThemeData(color: AppColors.pureWhite),
        titleTextStyle: TextStyle(
          color: AppColors.pureWhite,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.grayscaleBackground,
        scrimColor: Colors.black54,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.grayscaleBorder, width: 0.5),
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.pureWhite,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.grayscaleDivider,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Clean Light Monochrome Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      canvasColor: AppColors.lightBackground,
      cardColor: AppColors.lightSurface,
      dividerColor: AppColors.lightDivider,
      colorScheme: const ColorScheme.light(
        surface: AppColors.lightBackground,
        onSurface: AppColors.lightTextPrimary,
        primary: AppColors.oledBlack,
        onPrimary: AppColors.pureWhite,
        secondary: AppColors.lightTextSecondary,
        onSecondary: AppColors.pureWhite,
        surfaceContainerHighest: AppColors.lightSurfaceVariant,
        outline: AppColors.lightBorder,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.oledBlack,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.lightBackground,
          systemNavigationBarIconBrightness: Brightness.dark,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
        iconTheme: IconThemeData(color: AppColors.oledBlack),
        actionsIconTheme: IconThemeData(color: AppColors.oledBlack),
        titleTextStyle: TextStyle(
          color: AppColors.oledBlack,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 2.0,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.lightBackground,
        scrimColor: Colors.black26,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.lightBorder, width: 0.5),
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.oledBlack,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
