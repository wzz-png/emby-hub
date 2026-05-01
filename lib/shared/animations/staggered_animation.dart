import 'package:flutter/material.dart';

import 'spring_curves.dart';

/// 列表交错入场动画
///
/// 为列表/网格中的每个子项添加渐入 + 上滑效果，
/// 各项之间有 [staggerDelay] 的延迟错开。
class StaggeredAnimation extends StatefulWidget {
  const StaggeredAnimation({
    super.key,
    required this.child,
    required this.index,
    this.staggerDelay = const Duration(milliseconds: 30),
    this.duration = const Duration(milliseconds: 400),
    this.verticalOffset = 20.0,
  });

  final Widget child;

  /// 在列表中的索引（决定延迟量）
  final int index;

  /// 相邻项之间的延迟间隔
  final Duration staggerDelay;

  /// 动画总时长
  final Duration duration;

  /// 初始垂直偏移量
  final double verticalOffset;

  @override
  State<StaggeredAnimation> createState() => _StaggeredAnimationState();
}

class _StaggeredAnimationState extends State<StaggeredAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curve = SpringCurves.defaultCurve;

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _offset = Tween<Offset>(
      begin: Offset(0, widget.verticalOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: curve));

    // 延迟启动动画
    final delay = widget.staggerDelay * widget.index;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _offset.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
