import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// 毛玻璃底部导航栏
///
/// 浮于内容之上的毛玻璃底栏，包含 Safe Area 适配。
class GlassBottomBar extends StatelessWidget {
  const GlassBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.blurSigma = 40.0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassBottomBarItem> items;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tintColor = isDark ? AppColors.glassTint : AppColors.lightGlassTint;
    final tintOpacity = isDark
        ? AppColors.glassTintOpacity
        : AppColors.lightGlassTintOpacity;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: RepaintBoundary(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            decoration: BoxDecoration(
              color: tintColor.withOpacity(tintOpacity),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? AppColors.glassStroke
                      : AppColors.lightGlassStroke,
                  width: 0.5,
                ),
              ),
            ),
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;
                  return _BottomBarButton(
                    icon: item.icon,
                    activeIcon: item.activeIcon,
                    label: item.label,
                    isSelected: isSelected,
                    onTap: () => onTap(index),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GlassBottomBarItem {
  const GlassBottomBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
}

class _BottomBarButton extends StatelessWidget {
  const _BottomBarButton({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.onSurfaceMuted;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? (activeIcon ?? icon) : icon,
                key: ValueKey(isSelected),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
