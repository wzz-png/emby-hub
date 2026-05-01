import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/player/player_manager.dart';
import '../../../core/player/player_backend.dart';
import '../../../core/player/player_state.dart';
import '../../../core/providers.dart';
import '../../../core/utils/duration_extensions.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/glass_sheet.dart';

/// 视频播放器页面
class VideoPlayerPage extends ConsumerStatefulWidget {
  const VideoPlayerPage({
    super.key,
    required this.itemId,
    this.title = '',
    this.subtitle,
    this.startPositionTicks = 0,
    this.mediaSourceId,
  });

  final String itemId;
  final String title;
  final String? subtitle;
  final int startPositionTicks;
  final String? mediaSourceId;

  Duration? get startPosition =>
      startPositionTicks > 0
          ? Duration(microseconds: startPositionTicks ~/ 10)
          : null;

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  late final PlayerManager _player;
  Timer? _hideTimer;
  Timer? _progressTimer;
  bool _controlsVisible = true;
  bool _isSeeking = false;
  double _seekPosition = 0;

  @override
  void initState() {
    super.initState();
    _player = ref.read(playerManagerProvider);

    // 隐藏系统 UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);

    _startPlayback();
    _startHideTimer();
  }

  Future<void> _startPlayback() async {
    final repo = ref.read(embyRepositoryProvider);
    try {
      final info = await repo.getPlaybackInfo(widget.itemId);
      if (info.mediaSources.isEmpty) return;

      // 优先使用指定的 mediaSourceId，否则取第一个
      final source = widget.mediaSourceId != null
          ? info.mediaSources.firstWhere(
              (s) => s.id == widget.mediaSourceId,
              orElse: () => info.mediaSources.first,
            )
          : info.mediaSources.first;
      final url = repo.getDirectStreamUrl(widget.itemId, source.id);

      await _player.open(url);
      await repo.reportPlaybackStart(widget.itemId);

      // 恢复播放位置
      if (widget.startPosition != null) {
        await _player.seek(widget.startPosition!);
      }

      // 定时上报进度
      _progressTimer = Timer.periodic(
        AppConstants.playbackReportInterval,
        (_) => _reportProgress(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('播放失败: $e')),
        );
      }
    }
  }

  void _reportProgress() {
    final state = _player.state;
    if (!state.isPlaying && !state.isBuffering) return;

    final repo = ref.read(embyRepositoryProvider);
    repo.reportPlaybackProgress(
      widget.itemId,
      positionTicks: state.position.toEmbyTicks(),
      isPaused: !state.isPlaying,
    );
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(AppConstants.controlsAutoHideDelay, () {
      if (mounted && _player.state.isPlaying) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _startHideTimer();
  }

  void _toggleControls() {
    if (_controlsVisible) {
      setState(() => _controlsVisible = false);
    } else {
      _showControls();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _progressTimer?.cancel();

    // 上报停止
    final state = _player.state;
    ref.read(embyRepositoryProvider).reportPlaybackStopped(
          widget.itemId,
          positionTicks: state.position.toEmbyTicks(),
        );

    // 恢复系统 UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        // 双击快进/快退
        onDoubleTapDown: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.localPosition.dx < width / 3) {
            _player.seekRelative(const Duration(seconds: -10));
          } else if (details.localPosition.dx > width * 2 / 3) {
            _player.seekRelative(const Duration(seconds: 10));
          } else {
            _player.playOrPause();
          }
          _showControls();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 视频画面 — 由当前引擎后端提供渲染 Widget
            _player.backend.buildVideoWidget(fill: Colors.black),

            // 控件叠加层
            StreamBuilder<PlayerState>(
              stream: _player.stateStream,
              initialData: _player.state,
              builder: (context, snapshot) {
                final state = snapshot.data ?? const PlayerState();
                return AnimatedOpacity(
                  opacity: _controlsVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: _controlsVisible
                      ? _buildControls(context, state)
                      : const SizedBox.expand(),
                );
              },
            ),

            // 缓冲指示器
            StreamBuilder<PlayerState>(
              stream: _player.stateStream,
              initialData: _player.state,
              builder: (context, snapshot) {
                if (snapshot.data?.isBuffering ?? false) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, PlayerState state) {
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: SafeArea(
        child: Column(
          children: [
            // 顶栏
            _buildTopBar(context, state),

            const Spacer(),

            // 中心播放/暂停
            _buildCenterControls(state),

            const Spacer(),

            // 底栏（进度条 + 控件）
            _buildBottomBar(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, PlayerState state) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title.isNotEmpty ? widget.title : '播放中',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null)
                      Text(
                        widget.subtitle!,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // 字幕轨道
              IconButton(
                icon: const Icon(Icons.subtitles_rounded,
                    color: Colors.white70, size: 22),
                onPressed: () => _showTrackSelector(isSubtitle: true),
              ),
              // 音频轨道
              IconButton(
                icon: const Icon(Icons.audiotrack_rounded,
                    color: Colors.white70, size: 22),
                onPressed: () => _showTrackSelector(isSubtitle: false),
              ),
              // 播放器内核
              IconButton(
                icon: const Icon(Icons.settings_rounded,
                    color: Colors.white70, size: 22),
                onPressed: _showEngineSelector,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterControls(PlayerState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 快退 10s
        IconButton(
          iconSize: 36,
          icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
          onPressed: () =>
              _player.seekRelative(const Duration(seconds: -10)),
        ),
        const SizedBox(width: 32),
        // 播放/暂停
        GestureDetector(
          onTap: () {
            _player.playOrPause();
            _showControls();
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              state.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 32),
        // 快进 10s
        IconButton(
          iconSize: 36,
          icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
          onPressed: () =>
              _player.seekRelative(const Duration(seconds: 10)),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, PlayerState state) {
    final position = _isSeeking
        ? Duration(milliseconds: (_seekPosition * state.duration.inMilliseconds).round())
        : state.position;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 进度条
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6),
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: Colors.white.withOpacity(0.2),
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withOpacity(0.2),
                ),
                child: Slider(
                  value: _isSeeking
                      ? _seekPosition
                      : (state.duration.inMilliseconds > 0
                          ? state.position.inMilliseconds /
                              state.duration.inMilliseconds
                          : 0.0),
                  onChangeStart: (v) {
                    setState(() {
                      _isSeeking = true;
                      _seekPosition = v;
                    });
                  },
                  onChanged: (v) {
                    setState(() => _seekPosition = v);
                  },
                  onChangeEnd: (v) {
                    final target = Duration(
                        milliseconds:
                            (v * state.duration.inMilliseconds).round());
                    _player.seek(target);
                    setState(() => _isSeeking = false);
                    _showControls();
                  },
                ),
              ),

              // 时间 + 控件
              Row(
                children: [
                  Text(
                    '${position.toDisplayString()} / ${state.duration.toDisplayString()}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                  const Spacer(),
                  // 倍速
                  GestureDetector(
                    onTap: _showSpeedSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${state.speed}x',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 比例
                  IconButton(
                    icon: const Icon(Icons.aspect_ratio_rounded,
                        color: Colors.white70, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackSelector({required bool isSubtitle}) {
    final tracks = isSubtitle
        ? _player.subtitleTracks
        : _player.audioTracks;

    GlassSheet.show(
      context: context,
      initialHeight: 0.3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSubtitle ? '字幕轨道' : '音频轨道',
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (isSubtitle)
              ListTile(
                title: const Text('关闭字幕'),
                onTap: () {
                  _player.setSubtitleTrack(-1);
                  Navigator.pop(context);
                },
              ),
            ...tracks.map((t) => ListTile(
                  title: Text(t.title),
                  subtitle: t.language != null ? Text(t.language!) : null,
                  onTap: () {
                    if (isSubtitle) {
                      _player.setSubtitleTrack(t.index);
                    } else {
                      _player.setAudioTrack(t.index);
                    }
                    Navigator.pop(context);
                  },
                )),
            if (tracks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('无可用轨道',
                    style: TextStyle(color: AppColors.onSurfaceMuted)),
              ),
          ],
        ),
      ),
    );
  }

  void _showSpeedSelector() {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0, 3.0];
    GlassSheet.show(
      context: context,
      initialHeight: 0.3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('播放速度',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: speeds.map((s) {
                final isActive = _player.state.speed == s;
                return GlassButton(
                  isPrimary: isActive,
                  onPressed: () {
                    _player.setSpeed(s);
                    Navigator.pop(context);
                    _showControls();
                  },
                  child: Text('${s}x'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showEngineSelector() {
    GlassSheet.show(
      context: context,
      initialHeight: 0.35,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('播放器内核',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ...PlayerEngine.values.map((engine) {
              final isActive = _player.currentEngine == engine;
              final isAvailable = engine.isAvailableOnCurrentPlatform;
              return Opacity(
                opacity: isAvailable ? 1.0 : 0.45,
                child: ListTile(
                  leading: Icon(
                    isActive ? Icons.check_circle : Icons.radio_button_off,
                    color: isActive ? AppColors.primary : AppColors.onSurfaceMuted,
                  ),
                  title: Text(engine.displayName),
                  subtitle: Text(
                    isAvailable
                        ? engine.description
                        : '${engine.description} (不支持当前平台)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: isAvailable
                      ? () async {
                          Navigator.pop(context);
                          if (!isActive) {
                            await _player.switchEngine(engine);
                            ref.read(currentEngineProvider.notifier).state = engine;
                            setState(() {});
                            _startPlayback();
                          }
                        }
                      : null,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
