import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Emby Hub 字体系统
///
/// iOS/macOS 使用系统 SF Pro，Android/Windows 使用内置 Inter。
class AppTypography {
  AppTypography._();

  static const _fontFamily = 'Inter';

  static List<String> get _fontFamilyFallback {
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
         defaultTargetPlatform == TargetPlatform.macOS)) {
      return const ['.SF Pro Display', '.SF Pro Text', 'Helvetica Neue'];
    }
    return const ['Segoe UI', 'Roboto', 'sans-serif'];
  }

  // ── Token 定义 ───────────────────────────────────────

  static TextStyle get displayLarge => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get displayMedium => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.25,
      );

  static TextStyle get titleLarge => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.3,
      );

  static TextStyle get titleMedium => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.35,
      );

  static TextStyle get bodyLarge => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
        height: 1.5,
      );

  static TextStyle get caption => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
        height: 1.4,
      );

  static TextStyle get overline => TextStyle(
        fontFamily: _fontFamily,
        fontFamilyFallback: _fontFamilyFallback,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        height: 1.5,
      );

  /// 构建 TextTheme（按 Material 3 Token 映射）
  static TextTheme textTheme(Color textColor, Color mutedColor) {
    return TextTheme(
      displayLarge: displayLarge.copyWith(color: textColor),
      displayMedium: displayMedium.copyWith(color: textColor),
      displaySmall: titleLarge.copyWith(color: textColor),
      headlineMedium: titleMedium.copyWith(color: textColor),
      titleLarge: titleLarge.copyWith(color: textColor),
      titleMedium: titleMedium.copyWith(color: textColor),
      titleSmall: bodyLarge.copyWith(
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: bodyLarge.copyWith(color: textColor),
      bodyMedium: bodyMedium.copyWith(color: textColor),
      bodySmall: caption.copyWith(color: mutedColor),
      labelLarge: bodyMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelMedium: caption.copyWith(color: mutedColor),
      labelSmall: overline.copyWith(color: mutedColor),
    );
  }
}
