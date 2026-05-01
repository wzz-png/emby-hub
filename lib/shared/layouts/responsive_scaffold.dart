import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../widgets/glass_bottom_bar.dart';

/// 响应式布局断点
class Breakpoints {
  Breakpoints._();

  /// 手机
  static const double compact = 600;

  /// 平板竖屏 / 小窗口
  static const double medium = 840;
}

/// 自适应脚手架
///
/// 根据屏幕宽度自动在以下布局之间切换：
/// - compact (< 600dp): 底部导航
/// - medium (600-840dp): 折叠侧栏（仅图标）
/// - expanded (> 840dp): 完整侧栏
class ResponsiveScaffold extends StatelessWidget {
  const ResponsiveScaffold({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.floatingWidget,
  });

  /// 当前显示的内容区域
  final Widget body;

  /// 当前选中的导航索引
  final int currentIndex;

  /// 导航项点击回调
  final ValueChanged<int> onDestinationSelected;

  /// 导航目标列表
  final List<NavigationDestination> destinations;

  /// 浮于底栏上方的 Widget（如迷你播放器）
  final Widget? floatingWidget;

  bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
       defaultTargetPlatform == TargetPlatform.macOS ||
       defaultTargetPlatform == TargetPlatform.linux);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    if (width >= Breakpoints.medium || _isDesktop) {
      return _buildDesktopLayout(context, width);
    }
    return _buildMobileLayout(context);
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: Stack(
        children: [
          body,
          // 迷你播放器
          if (floatingWidget != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 56 + MediaQuery.of(context).padding.bottom,
              child: floatingWidget!,
            ),
        ],
      ),
      bottomNavigationBar: GlassBottomBar(
        currentIndex: currentIndex,
        onTap: onDestinationSelected,
        items: destinations
            .map((d) => GlassBottomBarItem(
                  icon: (d.icon as Icon).icon!,
                  activeIcon: d.selectedIcon != null
                      ? (d.selectedIcon as Icon).icon
                      : null,
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, double width) {
    final isExpanded = width >= Breakpoints.medium + 200;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        children: [
          // 侧栏
          _DesktopSidebar(
            currentIndex: currentIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: destinations,
            isExpanded: isExpanded,
          ),
          // 分隔线
          VerticalDivider(
            width: 0.5,
            thickness: 0.5,
            color: Theme.of(context).dividerTheme.color,
          ),
          // 内容区
          Expanded(
            child: Column(
              children: [
                Expanded(child: body),
                if (floatingWidget != null) floatingWidget!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 桌面侧栏
class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.isExpanded,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      width: isExpanded ? 240 : 72,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo / 应用名
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFFA78BFA)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Emby Hub',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 导航项
            ...List.generate(destinations.length, (index) {
              final dest = destinations[index];
              final isSelected = index == currentIndex;

              return _SidebarItem(
                icon: (dest.icon as Icon).icon!,
                activeIcon: dest.selectedIcon != null
                    ? (dest.selectedIcon as Icon).icon
                    : null,
                label: dest.label,
                isSelected: isSelected,
                isExpanded: isExpanded,
                onTap: () => onDestinationSelected(index),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  final IconData icon;
  final IconData? activeIcon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? const Color(0xFF6C63FF)
        : const Color(0xFF8E8EA0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isExpanded ? 12 : 0,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF6C63FF).withOpacity(0.12)
                : _hovering
                    ? Colors.white.withOpacity(0.04)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: widget.isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                widget.isSelected
                    ? (widget.activeIcon ?? widget.icon)
                    : widget.icon,
                color: color,
                size: 22,
              ),
              if (widget.isExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight:
                          widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
