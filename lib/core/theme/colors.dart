import 'dart:ui';

import 'package:flutter/material.dart';

/// Emby Hub 调色板 — 暗色优先的毛玻璃设计系统
class AppColors {
  AppColors._();

  // ── 暗色主题 ──────────────────────────────────────────────

  /// 最深背景，模糊底层
  static const surface = Color(0xFF0A0A0F);

  /// 卡片背景（模糊前）
  static const surfaceDim = Color(0xFF12121A);

  /// 抬升面
  static const surfaceContainer = Color(0xFF1A1A24);

  /// 毛玻璃填充色
  static const glassTint = Color(0xFF1E1E2E);

  /// 毛玻璃填充透明度
  static const double glassTintOpacity = 0.6;

  /// 毛玻璃边框色 (白色 8%)
  static Color get glassStroke => Colors.white.withOpacity(0.08);

  /// 毛玻璃高亮边（上边缘亮线）
  static Color get glassHighlight => Colors.white.withOpacity(0.12);

  // ── 强调色 ─────────────────────────────────────────────

  /// 主色调 — 紫蓝
  static const primary = Color(0xFF6C63FF);

  /// 主色浅变体 — 渐变端点
  static const primaryLight = Color(0xFFA78BFA);

  /// 主色渐变
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  // ── 文字 ────────────────────────────────────────────────

  /// 主文字
  static const onSurface = Color(0xFFE8E8ED);

  /// 次要文字 / 标注
  static const onSurfaceMuted = Color(0xFF8E8EA0);

  /// 反色文字（亮背景上）
  static const onPrimary = Color(0xFFFFFFFF);

  // ── 语义色 ──────────────────────────────────────────────

  /// 错误 / 删除
  static const destructive = Color(0xFFFF6B6B);

  /// 成功 / 完成
  static const success = Color(0xFF4ADE80);

  /// 警告
  static const warning = Color(0xFFFBBF24);

  /// 信息
  static const info = Color(0xFF60A5FA);

  // ── 亮色主题 ────────────────────────────────────────────

  static const lightSurface = Color(0xFFF8F8FC);
  static const lightSurfaceDim = Color(0xFFEFEFF5);
  static const lightSurfaceContainer = Color(0xFFE8E8F0);
  static const lightGlassTint = Color(0xFFFFFFFF);
  static const double lightGlassTintOpacity = 0.7;
  static Color get lightGlassStroke => Colors.black.withOpacity(0.06);
  static const lightOnSurface = Color(0xFF1A1A24);
  static const lightOnSurfaceMuted = Color(0xFF6E6E80);
}
