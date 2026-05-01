import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/theme/colors.dart';

/// 媒体海报卡片
///
/// 展示媒体封面图，支持播放进度叠加层和收藏标记。
/// 带 Hero 动画标签，用于与详情页过渡。
class MediaPoster extends StatelessWidget {
  const MediaPoster({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.title,
    this.subtitle,
    this.progress,
    this.isFavorite = false,
    this.onTap,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.blurHash,
  });

  final String imageUrl;

  /// Hero 过渡标识
  final String? heroTag;

  /// 海报底部标题
  final String? title;

  /// 副标题（年份、评分等）
  final String? subtitle;

  /// 播放进度 0.0 ~ 1.0
  final double? progress;

  final bool isFavorite;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final double borderRadius;

  /// BlurHash 占位字符串
  final String? blurHash;

  @override
  Widget build(BuildContext context) {
    Widget poster = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 封面图
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => _buildPlaceholder(),
              errorWidget: (_, __, ___) => _buildErrorWidget(),
            ),

            // 底部渐变遮罩（标题区域）
            if (title != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding:
                      const EdgeInsets.fromLTRB(8, 24, 8, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),

            // 播放进度条
            if (progress != null && progress! > 0)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: LinearProgressIndicator(
                  value: progress!,
                  minHeight: 3,
                  backgroundColor: Colors.black.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                ),
              ),

            // 收藏标记
            if (isFavorite)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: AppColors.destructive,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Hero 过渡
    if (heroTag != null) {
      poster = Hero(
        tag: heroTag!,
        flightShuttleBuilder: (_, animation, __, ___, toHeroContext) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final radius = Tween<double>(
                begin: borderRadius,
                end: 0.0,
              ).evaluate(animation);
              return ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: toHeroContext.widget,
              );
            },
          );
        },
        child: poster,
      );
    }

    if (onTap != null) {
      poster = GestureDetector(
        onTap: onTap,
        child: poster,
      );
    }

    return poster;
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceDim,
      child: const Center(
        child: Icon(
          Icons.movie_outlined,
          color: AppColors.onSurfaceMuted,
          size: 32,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: AppColors.surfaceDim,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.onSurfaceMuted,
          size: 32,
        ),
      ),
    );
  }
}
