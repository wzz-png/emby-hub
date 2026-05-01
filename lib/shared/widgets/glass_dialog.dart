import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// 毛玻璃对话框
///
/// 居中模态对话框，带深度模糊背景。
class GlassDialog extends StatelessWidget {
  const GlassDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.blurSigma = 40.0,
    this.width = 320,
  });

  final String? title;
  final Widget content;
  final List<Widget>? actions;
  final double blurSigma;
  final double width;

  /// 显示毛玻璃对话框
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget content,
    List<Widget>? actions,
  }) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => GlassDialog(
        title: title,
        content: content,
        actions: actions,
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

    return Center(
      child: SizedBox(
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: RepaintBoundary(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: tintColor.withOpacity(tintOpacity),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? AppColors.glassStroke
                        : AppColors.lightGlassStroke,
                    width: 0.5,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null) ...[
                        Text(
                          title!,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                      content,
                      if (actions != null && actions!.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: actions!
                              .map((a) => Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: a,
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
