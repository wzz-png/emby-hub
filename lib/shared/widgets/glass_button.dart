import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// 毛玻璃按钮
///
/// 带按压缩放动画的毛玻璃风格按钮，支持图标 + 文字。
class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    this.onPressed,
    required this.child,
    this.icon,
    this.blurSigma = 20.0,
    this.borderRadius = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.isPrimary = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final IconData? icon;
  final double blurSigma;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  /// true = 使用主色渐变填充
  final bool isPrimary;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(widget.borderRadius);

    return GestureDetector(
      onTapDown: widget.onPressed != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onPressed != null
          ? (_) {
              _controller.reverse();
              widget.onPressed!();
            }
          : null,
      onTapCancel: widget.onPressed != null ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: RepaintBoundary(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blurSigma,
                sigmaY: widget.blurSigma,
              ),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: widget.isPrimary
                      ? AppColors.primaryGradient
                      : null,
                  color: widget.isPrimary
                      ? null
                      : (isDark
                              ? AppColors.glassTint
                              : AppColors.lightGlassTint)
                          .withOpacity(isDark ? 0.5 : 0.6),
                  border: widget.isPrimary
                      ? null
                      : Border.all(
                          color: isDark
                              ? AppColors.glassStroke
                              : AppColors.lightGlassStroke,
                          width: 0.5,
                        ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 18,
                        color: widget.isPrimary
                            ? Colors.white
                            : AppColors.onSurface,
                      ),
                      const SizedBox(width: 8),
                    ],
                    DefaultTextStyle(
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isPrimary
                            ? Colors.white
                            : (isDark
                                ? AppColors.onSurface
                                : AppColors.lightOnSurface),
                      ),
                      child: widget.child,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
