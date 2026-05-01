import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'spring_curves.dart';

/// iOS 风格页面转场
///
/// 新页面从底部 30% 位置上滑 + 淡入，
/// 旧页面缩放至 95% + 轻微淡出。
/// 桌面端使用交叉淡入淡出（无滑动）。
class GlassPageTransition extends CustomTransitionPage<void> {
  GlassPageTransition({
    required super.child,
    super.key,
    bool isDesktop = false,
  }) : super(
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            if (isDesktop) {
              return _desktopTransition(animation, secondaryAnimation, child);
            }
            return _mobileTransition(animation, secondaryAnimation, child);
          },
        );

  static Widget _mobileTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curve = SpringCurves.gentleCurve;

    // 新页面：上滑 + 淡入
    final slideIn = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: curve));

    final fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // 旧页面：缩小 + 淡出
    final scaleOut = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: curve),
    );

    final fadeOut = Tween<double>(begin: 1.0, end: 0.6).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: fadeOut,
      child: ScaleTransition(
        scale: scaleOut,
        child: SlideTransition(
          position: slideIn,
          child: FadeTransition(
            opacity: fadeIn,
            child: child,
          ),
        ),
      ),
    );
  }

  static Widget _desktopTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 桌面端：仅交叉淡入淡出
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
      child: child,
    );
  }
}

/// 用于 GoRouter 的页面构建器辅助函数
CustomTransitionPage<void> buildGlassPage({
  required Widget child,
  bool isDesktop = false,
  LocalKey? key,
}) {
  return GlassPageTransition(
    key: key,
    isDesktop: isDesktop,
    child: child,
  );
}
