import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// 毛玻璃顶栏
///
/// 半透明应用栏，滚动时透明度动态增加。
/// 通过监听 [ScrollController] 的 offset 来实现渐进模糊效果。
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.scrollOffset = 0.0,
    this.maxBlurSigma = 40.0,
    this.height = 56.0,
  });

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;

  /// 当前滚动偏移量，用于计算模糊强度
  final double scrollOffset;

  /// 最大模糊强度
  final double maxBlurSigma;

  /// 栏高度
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    // 滚动 0→100 px 时，模糊从 0 → maxBlurSigma
    final progress = (scrollOffset / 100.0).clamp(0.0, 1.0);
    final sigma = maxBlurSigma * progress;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tintColor = isDark ? AppColors.glassTint : AppColors.lightGlassTint;
    final tintOpacity = (isDark
            ? AppColors.glassTintOpacity
            : AppColors.lightGlassTintOpacity) *
        progress;

    final topPadding = MediaQuery.of(context).padding.top;

    return ClipRect(
      child: RepaintBoundary(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(
            height: height + topPadding,
            padding: EdgeInsets.only(top: topPadding),
            decoration: BoxDecoration(
              color: tintColor.withOpacity(tintOpacity),
              border: Border(
                bottom: BorderSide(
                  color: (isDark ? AppColors.glassStroke : AppColors.lightGlassStroke)
                      .withOpacity(progress * 0.5),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                if (leading != null) leading!
                else const SizedBox(width: 16),
                if (title != null)
                  Expanded(
                    child: DefaultTextStyle(
                      style: Theme.of(context).textTheme.titleLarge!,
                      child: title!,
                    ),
                  ),
                if (actions != null) ...actions!,
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
