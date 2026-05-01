import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../core/theme/colors.dart';
import '../../../core/providers.dart';
import '../../auth/providers.dart';

/// 个人资料页面
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAuth = ref.watch(isAuthenticatedProvider);
    final client = ref.watch(embyClientProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '我的',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 24),

            // 用户卡片
            GlassCard(
              onTap: isAuth ? null : () => context.push('/login'),
              child: Row(
                children: [
                  // 头像
                  _buildAvatar(authState, client, isAuth),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isAuth ? authState.user!.name : '未登录',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAuth
                              ? (authState.serverInfo?.serverName ??
                                  '已连接')
                              : '点击连接 Emby 服务器',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.onSurfaceMuted,
                              ),
                        ),
                        if (isAuth && authState.serverInfo != null)
                          Text(
                            'Emby ${authState.serverInfo!.version}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppColors.onSurfaceMuted,
                                      fontSize: 11,
                                    ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.onSurfaceMuted,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 播放相关
            _buildSection(context, '播放', [
              _MenuItem(
                Icons.history_rounded,
                '播放历史',
                subtitle: '继续观看上次未看完的内容',
                onTap: () {},
              ),
              _MenuItem(
                Icons.favorite_rounded,
                '我的收藏',
                iconColor: AppColors.destructive,
                onTap: () {},
              ),
              _MenuItem(
                Icons.download_rounded,
                '下载管理',
                onTap: () {},
              ),
            ]),

            const SizedBox(height: 16),

            // 设置
            _buildSection(context, '设置', [
              _MenuItem(
                Icons.dns_rounded,
                '服务器管理',
                subtitle: isAuth
                    ? client.serverUrl ?? ''
                    : '未连接',
                onTap: () => context.push('/settings'),
              ),
              _MenuItem(
                Icons.palette_rounded,
                '外观设置',
                subtitle: '主题 · 色彩 · 透明度',
                onTap: () => context.push('/settings'),
              ),
              _MenuItem(
                Icons.play_circle_outline_rounded,
                '播放设置',
                subtitle: '播放器内核 · 画质 · 字幕',
                onTap: () => context.push('/settings'),
              ),
            ]),

            const SizedBox(height: 16),

            // 其他
            _buildSection(context, '其他', [
              _MenuItem(
                Icons.info_outline_rounded,
                '关于 Emby Hub',
                subtitle: '版本 1.0.0',
                onTap: () {},
              ),
            ]),

            // 退出登录
            if (isAuth) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  icon: Icons.logout_rounded,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surfaceContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: const Text('退出登录'),
                        content: const Text('确定要退出当前账号吗？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('取消'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              ref.read(authProvider.notifier).logout();
                            },
                            child: const Text(
                              '退出',
                              style: TextStyle(color: AppColors.destructive),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    '退出登录',
                    style: TextStyle(color: AppColors.destructive),
                  ),
                ),
              ),
            ],

            SizedBox(height: MediaQuery.of(context).padding.bottom + 80),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(AuthState authState, dynamic client, bool isAuth) {
    if (isAuth &&
        authState.user!.primaryImageTag != null &&
        client.serverUrl != null) {
      final url = client.imageUrl(
        authState.user!.id,
        imageType: 'Primary',
        maxWidth: 120,
        quality: 90,
        tag: authState.user!.primaryImageTag,
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: url,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildDefaultAvatar(),
          errorWidget: (_, __, ___) => _buildDefaultAvatar(),
        ),
      );
    }
    return _buildDefaultAvatar();
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.onSurfaceMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
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
                          Icon(
                            item.icon,
                            size: 20,
                            color: item.iconColor ?? AppColors.onSurface,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: const TextStyle(fontSize: 15),
                                ),
                                if (item.subtitle != null)
                                  Text(
                                    item.subtitle!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.onSurfaceMuted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: AppColors.onSurfaceMuted,
                          ),
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

class _MenuItem {
  const _MenuItem(
    this.icon,
    this.label, {
    this.subtitle,
    this.iconColor,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? iconColor;
  final VoidCallback? onTap;
}
