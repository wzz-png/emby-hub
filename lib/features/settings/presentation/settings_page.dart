import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../../core/theme/colors.dart';
import '../../../core/providers.dart';
import '../../../core/player/player_backend.dart';
import '../../auth/providers.dart';

/// 设置页面
///
/// 服务器管理 / 播放器内核选择 / 外观主题 / 缓存管理
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentEngine = ref.watch(currentEngineProvider);
    final isAuth = ref.watch(isAuthenticatedProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 服务器
            _buildSection(context, '服务器', [
              _SettingsItem(
                Icons.dns_rounded,
                '当前服务器',
                value: isAuth
                    ? authState.serverInfo?.serverName ?? '已连接'
                    : '未连接',
                valueColor: isAuth ? AppColors.success : AppColors.onSurfaceMuted,
                onTap: () {},
              ),
              _SettingsItem(
                Icons.info_outline_rounded,
                '服务器版本',
                value: isAuth
                    ? 'Emby ${authState.serverInfo?.version ?? ''}'
                    : '-',
                onTap: null,
              ),
            ]),
            const SizedBox(height: 16),

            // 播放器内核
            _buildSectionHeader(context, '播放器内核'),
            const SizedBox(height: 8),
            ...PlayerEngine.values.map((engine) {
              final isSelected = engine == currentEngine;
              final isAvailable = engine.isAvailableOnCurrentPlatform;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Opacity(
                  opacity: isAvailable ? 1.0 : 0.45,
                  child: GlassCard(
                    onTap: isAvailable ? () => _switchEngine(engine) : null,
                    child: Row(
                      children: [
                        // 引擎图标
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.15)
                                : AppColors.surfaceDim,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _engineIcon(engine),
                            size: 20,
                            color:
                                isSelected ? AppColors.primary : AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                engine.displayName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      isSelected ? FontWeight.w600 : FontWeight.w400,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.onSurface,
                                ),
                              ),
                              Text(
                                isAvailable
                                    ? engine.description
                                    : '${engine.description} (不支持当前平台)',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.onSurfaceMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),

            // 播放设置
            _buildSection(context, '播放', [
              _SettingsItem(
                Icons.high_quality_rounded,
                '默认画质',
                value: '原始画质',
                onTap: () => _showQualitySelector(),
              ),
              _SettingsItem(
                Icons.subtitles_rounded,
                '默认字幕语言',
                value: '中文',
                onTap: () {},
              ),
              _SettingsItem(
                Icons.audiotrack_rounded,
                '默认音频语言',
                value: '中文',
                onTap: () {},
              ),
              _SettingsItem(
                Icons.speed_rounded,
                '默认播放速度',
                value: '1.0x',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 16),

            // 外观
            _buildSection(context, '外观', [
              _SettingsItem(
                Icons.dark_mode_rounded,
                '主题模式',
                value: '深色',
                onTap: () => _showThemeSelector(),
              ),
              _SettingsItem(
                Icons.color_lens_rounded,
                '强调色',
                value: '紫蓝',
                trailing: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                ),
                onTap: () {},
              ),
              _SettingsItem(
                Icons.blur_on_rounded,
                '毛玻璃效果',
                value: '开启',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 16),

            // 存储
            _buildSection(context, '存储与缓存', [
              _SettingsItem(
                Icons.cleaning_services_rounded,
                '清除图片缓存',
                value: null,
                onTap: () => _clearImageCache(),
              ),
              _SettingsItem(
                Icons.delete_outline_rounded,
                '清除搜索历史',
                value: null,
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 16),

            // 关于
            _buildSection(context, '关于', [
              _SettingsItem(
                Icons.info_outline_rounded,
                '版本',
                value: '1.0.0 (build 1)',
                onTap: null,
              ),
              _SettingsItem(
                Icons.code_rounded,
                '开源协议',
                value: 'MIT',
                onTap: () {},
              ),
              _SettingsItem(
                Icons.bug_report_outlined,
                '反馈问题',
                value: null,
                onTap: () {},
              ),
            ]),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
          ],
        ),
      ),
    );
  }

  IconData _engineIcon(PlayerEngine engine) {
    switch (engine) {
      case PlayerEngine.mpv:
        return Icons.smart_display_rounded;
      case PlayerEngine.mdk:
        return Icons.memory_rounded;
      case PlayerEngine.vlc:
        return Icons.ondemand_video_rounded;
    }
  }

  Future<void> _switchEngine(PlayerEngine engine) async {
    ref.read(currentEngineProvider.notifier).state = engine;
    try {
      await ref.read(playerManagerProvider).switchEngine(engine);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已切换到 ${engine.displayName}'),
            backgroundColor: AppColors.surfaceContainer,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('切换失败: $e'),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showQualitySelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final options = [
          ('原始画质', 'DirectPlay，最佳画质'),
          ('4K (2160p)', '最高 80Mbps'),
          ('1080p', '最高 20Mbps'),
          ('720p', '最高 8Mbps'),
          ('480p', '最高 4Mbps'),
          ('360p', '低带宽模式'),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '默认画质',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...options.map((opt) => ListTile(
                    title: Text(opt.$1),
                    subtitle: Text(
                      opt.$2,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    trailing: opt.$1 == '原始画质'
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () => Navigator.pop(ctx),
                  )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '主题模式',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.dark_mode_rounded),
                title: const Text('深色'),
                trailing: const Icon(Icons.check, color: AppColors.primary),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.light_mode_rounded),
                title: const Text('浅色'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.settings_brightness_rounded),
                title: const Text('跟随系统'),
                onTap: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _clearImageCache() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('清除图片缓存'),
        content: const Text('这将清除所有已缓存的图片，下次浏览时需要重新下载。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: PaintingBinding.instance.imageCache.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('缓存已清除'),
                  backgroundColor: AppColors.surfaceContainer,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text(
              '清除',
              style: TextStyle(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceMuted,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<_SettingsItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, title),
        const SizedBox(height: 8),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: List.generate(items.length, (index) {
              final item = items[index];
              return Column(
                children: [
                  InkWell(
                    onTap: item.onTap,
                    borderRadius: index == 0
                        ? const BorderRadius.vertical(
                            top: Radius.circular(16))
                        : index == items.length - 1
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(16))
                            : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(item.icon, size: 20, color: AppColors.onSurface),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          if (item.trailing != null) item.trailing!,
                          if (item.value != null) ...[
                            Text(
                              item.value!,
                              style: TextStyle(
                                color: item.valueColor ?? AppColors.onSurfaceMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                          if (item.onTap != null) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: AppColors.onSurfaceMuted,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (index < items.length - 1)
                    Divider(
                      height: 0.5,
                      indent: 48,
                      color: Colors.white.withOpacity(0.06),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _SettingsItem {
  const _SettingsItem(
    this.icon,
    this.label, {
    this.value,
    this.valueColor,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String? value;
  final Color? valueColor;
  final Widget? trailing;
  final VoidCallback? onTap;
}
