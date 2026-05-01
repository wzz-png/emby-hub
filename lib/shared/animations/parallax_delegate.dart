import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// 视差滚动委托
///
/// 为 SliverPersistentHeader 提供视差效果，
/// 背景图以内容滚动速度的 [parallaxFactor] 倍移动。
class ParallaxDelegate extends SliverPersistentHeaderDelegate {
  ParallaxDelegate({
    required this.maxExtent,
    required this.minExtent,
    required this.builder,
    this.parallaxFactor = 0.5,
  });

  @override
  final double maxExtent;

  @override
  final double minExtent;

  /// 构建头部内容，接收 shrinkOffset 和 overlapsContent
  final Widget Function(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) builder;

  /// 视差因子 (0.0 = 无移动, 1.0 = 同速)
  final double parallaxFactor;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = shrinkOffset / (maxExtent - minExtent);
    final parallaxOffset = shrinkOffset * parallaxFactor;

    return SizedBox(
      height: maxExtent - shrinkOffset,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 视差偏移的背景
            Transform.translate(
              offset: Offset(0, parallaxOffset),
              child: builder(context, shrinkOffset, overlapsContent),
            ),
            // 底部渐变遮罩
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: maxExtent * 0.6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Theme.of(context).scaffoldBackgroundColor,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant ParallaxDelegate oldDelegate) {
    return maxExtent != oldDelegate.maxExtent ||
        minExtent != oldDelegate.minExtent ||
        parallaxFactor != oldDelegate.parallaxFactor;
  }
}
