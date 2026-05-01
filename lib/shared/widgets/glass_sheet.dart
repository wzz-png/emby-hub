import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// 毛玻璃底部弹窗
///
/// 可拖拽的底部弹窗，带毛玻璃背景和拖拽把手。
class GlassSheet extends StatelessWidget {
  const GlassSheet({
    super.key,
    required this.child,
    this.blurSigma = 40.0,
    this.maxHeight = 0.85,
    this.initialHeight = 0.5,
    this.showHandle = true,
  });

  final Widget child;
  final double blurSigma;
  final double maxHeight;
  final double initialHeight;
  final bool showHandle;

  /// 显示毛玻璃底部弹窗
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double maxHeight = 0.85,
    double initialHeight = 0.5,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => GlassSheet(
        maxHeight: maxHeight,
        initialHeight: initialHeight,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tintColor = isDark ? AppColors.glassTint : AppColors.lightGlassTint;
    final tintOpacity = isDark
        ? AppColors.glassTintOpacity
        : AppColors.lightGlassTintOpacity;

    return DraggableScrollableSheet(
      maxChildSize: maxHeight,
      initialChildSize: initialHeight,
      minChildSize: 0.2,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: RepaintBoundary(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                decoration: BoxDecoration(
                  color: tintColor.withOpacity(tintOpacity),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.glassHighlight
                          : AppColors.lightGlassStroke,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    if (showHandle) _buildHandle(isDark),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHandle(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.2)
              : Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
