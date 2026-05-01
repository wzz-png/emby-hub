import 'package:flutter/physics.dart';
import 'package:flutter/material.dart';

/// iOS 风格弹簧曲线定义
///
/// 所有动画均使用弹簧物理驱动，避免线性/贝塞尔曲线，
/// 确保交互感受与 iOS 原生一致。
class SpringCurves {
  SpringCurves._();

  /// 通用弹簧 — 列表项、卡片
  static const defaultSpring = SpringDescription(
    mass: 1.0,
    stiffness: 300.0,
    damping: 25.0,
  );

  /// 快速弹簧 — 按钮、开关、即时反馈
  static const snappySpring = SpringDescription(
    mass: 1.0,
    stiffness: 500.0,
    damping: 30.0,
  );

  /// 柔和弹簧 — 页面转场、弹窗展开
  static const gentleSpring = SpringDescription(
    mass: 1.0,
    stiffness: 180.0,
    damping: 22.0,
  );

  /// 将 SpringDescription 转换为 Curve（近似）
  ///
  /// Flutter 的 [Curves] 系统不直接支持弹簧，
  /// 这里用 [SpringSimulation] 参数生成等效曲线。
  static Curve get defaultCurve => _SpringCurve(defaultSpring);
  static Curve get snappyCurve => _SpringCurve(snappySpring);
  static Curve get gentleCurve => _SpringCurve(gentleSpring);
}

/// 基于 SpringSimulation 的自定义 Curve
class _SpringCurve extends Curve {
  _SpringCurve(this.spring);

  final SpringDescription spring;

  @override
  double transformInternal(double t) {
    final simulation = SpringSimulation(spring, 0.0, 1.0, 0.0);
    return simulation.x(t * _estimateDuration());
  }

  /// 估算弹簧到达平衡所需时间（归一化为 1.0）
  double _estimateDuration() {
    final simulation = SpringSimulation(spring, 0.0, 1.0, 0.0);
    double t = 0.0;
    while (!simulation.isDone(t) && t < 5.0) {
      t += 0.001;
    }
    return t;
  }
}
