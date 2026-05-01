import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'colors.dart';
import 'typography.dart';

/// Emby Hub 主题配置
class AppTheme {
  AppTheme._();

  // ── 暗色主题（主） ──────────────────────────────────────

  static ThemeData get dark {
    final textTheme = AppTypography.textTheme(
      AppColors.onSurface,
      AppColors.onSurfaceMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surface,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        error: AppColors.destructive,
        onSurface: AppColors.onSurface,
        onPrimary: AppColors.onPrimary,
        surfaceContainerHighest: AppColors.surfaceContainer,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.onSurfaceMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.onSurfaceMuted),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: AppColors.onSurfaceMuted,
          fontSize: 12,
        ),
        indicatorColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDim,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.onSurface,
        size: 24,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.06),
        thickness: 0.5,
      ),
      splashFactory: InkSparkle.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: AppColors.primary.withOpacity(0.1),
    );
  }

  // ── 亮色主题 ──────────────────────────────────────────

  static ThemeData get light {
    final textTheme = AppTypography.textTheme(
      AppColors.lightOnSurface,
      AppColors.lightOnSurfaceMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightSurface,
      colorScheme: const ColorScheme.light(
        surface: AppColors.lightSurface,
        primary: AppColors.primary,
        secondary: AppColors.primaryLight,
        error: AppColors.destructive,
        onSurface: AppColors.lightOnSurface,
        onPrimary: AppColors.onPrimary,
        surfaceContainerHighest: AppColors.lightSurfaceContainer,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: AppColors.lightOnSurface),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.lightOnSurfaceMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurfaceDim,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightOnSurface,
        size: 24,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.black.withOpacity(0.06),
        thickness: 0.5,
      ),
      splashFactory: InkSparkle.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: AppColors.primary.withOpacity(0.1),
    );
  }
}
