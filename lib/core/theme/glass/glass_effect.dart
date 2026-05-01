import 'dart:ui';

import 'package:flutter/material.dart';

import '../colors.dart';

/// 毛玻璃效果基础组件
///
/// 所有毛玻璃 UI 组件的底层原语。基于 [BackdropFilter] + [ClipRRect]
/// + 半透明着色容器，提供可配置的模糊强度、着色、圆角和边框。
class GlassEffect extends StatelessWidget {
  const GlassEffect({
    super.key,
    required this.child,
    this.blurSigma = 40.0,
    this.tintColor,
    this.tintOpacity,
    this.borderRadius = 20.0,
    this.borderColor,
    this.borderWidth = 0.5,
    this.padding,
    this.margin,
    this.showHighlight = true,
  });

  final Widget child;

  /// 模糊强度（越大越模糊）
  final double blurSigma;

  /// 着色颜色（默认使用主题 glassTint）
  final Color? tintColor;

  /// 着色透明度
  final double? tintOpacity;

  /// 圆角半径
  final double borderRadius;

  /// 边框颜色
  final Color? borderColor;

  /// 边框粗细
  final double borderWidth;

  /// 内边距
  final EdgeInsetsGeometry? padding;

  /// 外边距
  final EdgeInsetsGeometry? margin;

  /// 是否显示上边缘高亮线（模拟光泽）
  final bool showHighlight;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveTint = tintColor ??
        (isDark ? AppColors.glassTint : AppColors.lightGlassTint);
    final effectiveOpacity = tintOpacity ??
        (isDark
            ? AppColors.glassTintOpacity
            : AppColors.lightGlassTintOpacity);
    final effectiveBorder = borderColor ??
        (isDark ? AppColors.glassStroke : AppColors.lightGlassStroke);

    final radius = BorderRadius.circular(borderRadius);

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: blurSigma,
              sigmaY: blurSigma,
            ),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color: effectiveTint.withOpacity(effectiveOpacity),
                borderRadius: radius,
                border: borderWidth > 0
                    ? Border.all(
                        color: effectiveBorder,
                        width: borderWidth,
                      )
                    : null,
                // 上边缘高亮线 — 模拟玻璃光泽
                gradient: showHighlight
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.02, 1.0],
                        colors: [
                          Colors.white.withOpacity(isDark ? 0.12 : 0.2),
                          effectiveTint.withOpacity(effectiveOpacity),
                          effectiveTint.withOpacity(effectiveOpacity),
                        ],
                      )
                    : null,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
