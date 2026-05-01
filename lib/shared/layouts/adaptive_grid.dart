import 'package:flutter/material.dart';

/// 自适应网格布局
///
/// 根据屏幕宽度自动计算列数和子项宽度。
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 140,
    this.maxItemWidth = 200,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
    this.childAspectRatio = 2 / 3,
    this.padding = const EdgeInsets.all(16),
  });

  final List<Widget> children;
  final double minItemWidth;
  final double maxItemWidth;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth -
            (padding as EdgeInsets).horizontal;
        final columns = (availableWidth / minItemWidth).floor().clamp(2, 6);

        return GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: children.length,
          itemBuilder: (context, index) => children[index],
        );
      },
    );
  }
}

/// Sliver 版本的自适应网格
class SliverAdaptiveGrid extends StatelessWidget {
  const SliverAdaptiveGrid({
    super.key,
    required this.delegate,
    this.minItemWidth = 140,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
    this.childAspectRatio = 2 / 3,
  });

  final SliverChildDelegate delegate;
  final double minItemWidth;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final columns = (width / minItemWidth).floor().clamp(2, 6);

    return SliverGrid(
      delegate: delegate,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
    );
  }
}
