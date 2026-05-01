import 'package:flutter/material.dart';

import '../../core/theme/glass/glass_effect.dart';

/// 毛玻璃内容卡片
///
/// 带上边缘高亮线的毛玻璃容器，适用于展示媒体信息、
/// 设置项分组等内容区块。
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.blurSigma = 40.0,
    this.borderRadius = 20.0,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final double blurSigma;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    Widget card = GlassEffect(
      blurSigma: blurSigma,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      child: SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    );

    if (onTap != null) {
      card = _ScaleOnTap(
        onTap: onTap!,
        child: card,
      );
    }

    return card;
  }
}

/// 按压缩放动画封装
class _ScaleOnTap extends StatefulWidget {
  const _ScaleOnTap({
    required this.child,
    required this.onTap,
  });

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_ScaleOnTap> createState() => _ScaleOnTapState();
}

class _ScaleOnTapState extends State<_ScaleOnTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
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
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
