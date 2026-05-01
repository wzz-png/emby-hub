import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// 骨架屏加载占位
///
/// 渐变闪烁效果的加载占位组件。
class ShimmerLoading extends StatefulWidget {
  const ShimmerLoading({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.child,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final Widget? child;

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? AppColors.surfaceDim : AppColors.lightSurfaceDim;
    final highlightColor =
        isDark ? AppColors.surfaceContainer : AppColors.lightSurfaceContainer;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(1.0 + 2.0 * _controller.value, 0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}

/// 海报骨架屏
class PosterShimmer extends StatelessWidget {
  const PosterShimmer({
    super.key,
    this.width = 120,
    this.aspectRatio = 2 / 3,
  });

  final double width;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      width: width,
      height: width / aspectRatio,
      borderRadius: 12,
    );
  }
}

/// 文本行骨架屏
class TextShimmer extends StatelessWidget {
  const TextShimmer({
    super.key,
    this.width = 120,
    this.height = 14,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      width: width,
      height: height,
      borderRadius: height / 2,
    );
  }
}
