import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../config/app_theme.dart';
import '../l10n/l10n.dart';
import '../models/music_catalog.dart';
import '../services/audio_service.dart';
import '../services/composition_service.dart';
import '../utils/asset_utils.dart';
import '../utils/file_utils.dart';
import '../utils/time_utils.dart';
import '../widgets/composer_cell.dart';

/// 作曲页：4 乐器 × 5 片段选曲、混音试听、录音。
/// 对应 iOS ComposerViewController.swift。
///
/// [style] 由主页传入，决定加载哪套 MP3（流行/金属/思念/电子）。
class ComposerScreen extends StatefulWidget {
  const ComposerScreen({super.key, required this.style});

  final MusicStyle style;

  @override
  State<ComposerScreen> createState() => _ComposerScreenState();
}

/// 布局尺寸 DTO（Data Transfer Object），把计算结果从 build 里抽离
class _ComposerLayoutMetrics {
  const _ComposerLayoutMetrics({
    required this.instrumentSide,
    required this.patternWidth,
    required this.patternHeight,
    required this.contentWidth,
    required this.mixHeight,
    required this.playButtonSize,
    required this.playButtonTop,
  });

  final double instrumentSide;
  final double patternWidth;
  final double patternHeight;
  final double contentWidth;
  final double mixHeight;
  final double playButtonSize;
  final double playButtonTop;
}

class _ComposerScreenState extends State<ComposerScreen> {
  final _composition = CompositionService();
  final _player = AudioPlayer();
  final _recorder = AudioRecorder();

  /// Stream 订阅句柄；页面销毁时必须 cancel
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _playerStateSub;

  /// 当前选中的乐器行 0=鼓 1=贝斯 2=吉他 3=MIDI
  int _selectedInstrument = 0;

  /// 每个乐器选的片段 0-4；-1 表示该轨未选
  final _selectedPatterns = List<int>.filled(4, -1);

  /// 与 _selectedPatterns 对应的 assets 路径，供 FFmpeg 混音
  final _selectedAssets = List<String?>.filled(4, null);

  bool _isRecording = false;
  bool _isPlaying = false;
  bool _isMixing = false;
  bool _isFinishing = false;
  double _progress = 0;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _preparedPlaybackKey;

  @override
  void initState() {
    super.initState();
    // unawaited：启动异步但不等待，避免 initState 不能 async 的限制
    unawaited(AudioService.ensurePlayback());

    // just_audio 通过 Stream 推送播放进度，listen 注册监听
    _positionSub = _player.positionStream.listen((position) {
      final total = _player.duration ?? Duration.zero;
      if (!mounted || total.inMilliseconds <= 0) return;
      setState(() {
        _position = position;
        _progress = position.inMilliseconds / total.inMilliseconds;
      });
    });
    _durationSub = _player.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() {
        _duration = duration ?? Duration.zero;
      });
    });
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() => _isPlaying = state.playing);
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playerStateSub?.cancel();
    unawaited(_player.stop());
    _player.dispose();
    _recorder.dispose();
    super.dispose();
  }

  /// 按屏幕宽高计算格子尺寸（对齐 iOS layoutMetrics(for:)）
  _ComposerLayoutMetrics _layoutMetrics(
    double width,
    double height,
    bool isPad,
  ) {
    const panelPadding = 10.0;
    const instrumentGap = 10.0;
    const patternGap = 8.0;
    final contentWidth = math.max(0.0, width - panelPadding * 2);

    final instrumentByWidth = ((contentWidth - instrumentGap) / 2).clamp(
      isPad ? 120.0 : 96.0,
      isPad ? 360.0 : double.infinity,
    );
    final instrumentByHeight = ((height - (isPad ? 240 : 190)) / 2).clamp(
      isPad ? 120.0 : 96.0,
      double.infinity,
    );
    final instrumentMax = isPad ? 360.0 : contentWidth;
    final instrumentSide = [
      instrumentByWidth,
      instrumentByHeight,
      instrumentMax,
    ].reduce((a, b) => a < b ? a : b);
    final patternWidth = ((contentWidth - patternGap * 4) / 5).clamp(
      44.0,
      isPad ? 190.0 : double.infinity,
    );
    final patternHeight = isPad
        ? 120.0
        : (patternWidth * 1.05).clamp(72.0, 120.0);
    final mixHeight =
        panelPadding * 2 +
        instrumentSide * 2 +
        instrumentGap +
        10 +
        patternHeight;
    final playButtonSize = isPad
        ? (instrumentSide * 0.62).clamp(180.0, 230.0)
        : (contentWidth * 0.33).clamp(108.0, 160.0);
    final playButtonTop = (instrumentSide - playButtonSize / 2 + 15).clamp(
      40.0,
      double.infinity,
    );

    return _ComposerLayoutMetrics(
      instrumentSide: instrumentSide,
      patternWidth: patternWidth,
      patternHeight: patternHeight,
      contentWidth: contentWidth,
      mixHeight: mixHeight,
      playButtonSize: playButtonSize,
      playButtonTop: playButtonTop,
    );
  }

  String _playbackKey(List<String> assets) => assets.join('\n');

  void _startPlayback() {
    // just_audio 的 play() 会等到播放结束/暂停后才完成，所以这里只启动播放，不 await。
    unawaited(_player.play());
  }

  /// 中央大播放钮：播放中则暂停；已有合成结果则继续播放；否则先混音再播放。
  Future<void> _toggleMainPlayback() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }

    // whereType<String>() 过滤掉 null，只保留 String
    final assets = _selectedAssets.whereType<String>().toList();
    if (assets.isEmpty) {
      _showToast(L10n.t('composer_toast_select_segments'));
      return;
    }

    final playbackKey = _playbackKey(assets);
    if (_preparedPlaybackKey == playbackKey) {
      await AudioService.ensurePlayback();
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      _startPlayback();
      return;
    }

    await _mixAndPlay(assets, playbackKey);
  }

  /// 混音所有已选轨并播放；只有真正需要 FFmpeg 混音时才显示 loading。
  Future<void> _mixAndPlay(List<String> assets, String playbackKey) async {
    final shouldShowLoading = assets.length > 1;
    if (shouldShowLoading) {
      setState(() => _isMixing = true);
    }
    _preparedPlaybackKey = null;

    try {
      await AudioService.ensurePlayback();
      if (assets.length == 1) {
        await _playAsset(assets.first);
        if (mounted) setState(() => _preparedPlaybackKey = playbackKey);
        return;
      }
      final output = await _composition.mixAudioTracks(assets);
      if (output == null) {
        _showToast(L10n.t('composer_toast_select_segments'));
        return;
      }
      await _playFile(output);
      if (mounted) setState(() => _preparedPlaybackKey = playbackKey);
    } finally {
      if (mounted && shouldShowLoading) setState(() => _isMixing = false);
    }
  }

  /// 播放打包在 app 里的 MP3（assets/...）
  Future<void> _playAsset(String assetPath) async {
    if (!await AssetUtils.exists(assetPath)) {
      _showToast('音频资源缺失');
      return;
    }
    await AudioService.ensurePlayback();
    await _player.stop();
    await _player.setAsset(assetPath);
    _startPlayback();
  }

  /// 播放沙盒里的 m4a 文件（混音结果）
  Future<void> _playFile(String path) async {
    await AudioService.ensurePlayback();
    await _player.stop();
    await _player.setFilePath(path);
    _startPlayback();
  }

  /// 点击片段 0-4：选中并试听；再次点击同一格则取消
  Future<void> _togglePattern(int patternIndex) async {
    if (_isMixing || _isFinishing) return;

    if (_selectedPatterns[_selectedInstrument] == patternIndex) {
      setState(() {
        _selectedPatterns[_selectedInstrument] = -1;
        _selectedAssets[_selectedInstrument] = null;
        _preparedPlaybackKey = null;
      });
      await _player.pause();
      return;
    }

    final assetPath = MusicCatalog.assetPath(
      widget.style, // 通过 State.widget 访问 StatefulWidget 上的字段
      _selectedInstrument,
      patternIndex,
    );
    setState(() {
      _selectedPatterns[_selectedInstrument] = patternIndex;
      _selectedAssets[_selectedInstrument] = assetPath;
      _preparedPlaybackKey = null;
    });
    await _playAsset(assetPath);
  }

  /// 麦克风录音开关
  Future<void> _toggleRecording() async {
    if (_isMixing || _isFinishing) return;

    if (_isRecording) {
      await _recorder.stop();
      await AudioService.ensurePlayback();
      setState(() => _isRecording = false);
      return;
    }

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      _showToast(L10n.t('composer_toast_recorder_init_failed'));
      return;
    }

    await AudioService.ensurePlayAndRecord();
    final path = await FileUtils.recorderPath();
    await FileUtils.clearIfExists(path);
    final canRecord = await _recorder.hasPermission();
    if (!canRecord) {
      _showToast(L10n.t('composer_toast_recorder_init_failed'));
      return;
    }

    _composition.recorderStartTime = _player.position;
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        numChannels: 2,
      ),
      path: path,
    );
    setState(() => _isRecording = true);
  }

  Future<void> _stopPlaybackAndRecording() async {
    await _player.stop();
    if (_isRecording) {
      await _recorder.stop();
      if (mounted) setState(() => _isRecording = false);
    }
  }

  /// 取消：清空 audio/recorder，pop(false) 告诉主页未保存音乐
  Future<void> _cancel() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    await _stopPlaybackAndRecording();
    await FileUtils.clearIfExists(await FileUtils.audioPath());
    await FileUtils.clearIfExists(await FileUtils.recorderPath());
    _preparedPlaybackKey = null;

    if (!mounted) return;
    _showToast(L10n.t('composer_toast_cancelled'));
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.of(context).pop(false);
  }

  /// 保存：混音写入 audio.m4a，pop(true) 告诉主页音乐已就绪
  Future<void> _save() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    await _stopPlaybackAndRecording();

    final assets = _selectedAssets.whereType<String>().toList();
    if (assets.isNotEmpty) {
      setState(() => _isMixing = true);
      final output = await _composition
          .mixAudioTracks(assets)
          .catchError((_) => null);
      if (mounted) setState(() => _isMixing = false);
      if (output == null) {
        if (mounted) {
          setState(() => _isFinishing = false);
          _showToast(L10n.t('composer_toast_save_failed'));
        }
        return;
      }
      _preparedPlaybackKey = _playbackKey(assets);
    } else {
      // 当前没有选择音乐片段时，避免保留上一次试听/保存留下的旧 audio.m4a。
      await FileUtils.clearIfExists(await FileUtils.audioPath());
      _preparedPlaybackKey = null;
    }

    if (!mounted) return;
    _showToast(L10n.t('composer_toast_saved'));
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.of(context).pop(true);
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _instrumentCell(int index, _ComposerLayoutMetrics metrics) {
    final selected = _selectedInstrument == index;
    return SizedBox(
      width: metrics.instrumentSide,
      height: metrics.instrumentSide,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: _isMixing || _isFinishing
              ? null
              : () => setState(() => _selectedInstrument = index),
          child: ComposerCell(
            title: L10n.t(MusicCatalog.instrumentKeys[index]),
            subtitle: _selectedPatterns[index] >= 0
                ? '${_selectedPatterns[index] + 1}'
                : null,
            backgroundColor: AppTheme.instrumentColors[index],
            largeTitle: true,
            selected: selected,
          ),
        ),
      ),
    );
  }

  Widget _patternCell(int index, _ComposerLayoutMetrics metrics) {
    final color = AppTheme.instrumentColors[_selectedInstrument].withValues(
      alpha: 0.82,
    );
    final selected = _selectedPatterns[_selectedInstrument] == index;
    return SizedBox(
      width: metrics.patternWidth,
      height: metrics.patternHeight,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(5),
          onTap: () => _togglePattern(index),
          child: ComposerCell(
            title: '${index + 1}',
            backgroundColor: color,
            selected: selected,
          ),
        ),
      ),
    );
  }

  /// 上半区：2×2 乐器 + 悬浮播放钮 + 单行 5 片段
  Widget _buildMixPanel(_ComposerLayoutMetrics metrics) {
    const instrumentGap = 10.0;
    const patternGap = 8.0;
    final instrumentRowWidth = metrics.instrumentSide * 2 + instrumentGap;
    final patternRowWidth = metrics.patternWidth * 5 + patternGap * 4;

    return SizedBox(
      height: metrics.mixHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: double.infinity,
            height: metrics.mixHeight,
            decoration: BoxDecoration(
              color: AppTheme.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.panelAlt),
            ),
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: instrumentRowWidth,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _instrumentCell(0, metrics),
                              const SizedBox(width: instrumentGap),
                              _instrumentCell(1, metrics),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SizedBox(
                          width: instrumentRowWidth,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _instrumentCell(2, metrics),
                              const SizedBox(width: instrumentGap),
                              _instrumentCell(3, metrics),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: patternRowWidth,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < 5; i++) ...[
                          _patternCell(i, metrics),
                          if (i < 4) const SizedBox(width: patternGap),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Positioned：在 Stack 里绝对定位；只占用按钮大小，不挡四角格子点击
          Positioned(
            top: metrics.playButtonTop,
            child: Material(
              color: AppTheme.panelAlt.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _isMixing || _isFinishing ? null : _toggleMainPlayback,
                child: SizedBox(
                  width: metrics.playButtonSize,
                  height: metrics.playButtonSize,
                  child: _isMixing
                      ? const Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppTheme.textPrimary,
                          ),
                        )
                      : Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 56,
                          color: AppTheme.textPrimary,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isPad = size.shortestSide >= 600;
    final horizontalInset = isPad ? 24.0 : 0.0;
    final topInset = isPad ? 24.0 : 20.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const progressRowHeight = 28.0;
            const progressGap = 24.0;
            const bottomBarHeight = 50.0;
            const bottomGap = 16.0;
            const verticalSafetyBuffer = 24.0;
            final availablePanelHeight = math.max(
              250.0,
              constraints.maxHeight -
                  topInset -
                  progressRowHeight -
                  progressGap -
                  bottomBarHeight -
                  bottomGap -
                  verticalSafetyBuffer,
            );
            final availablePanelWidth = math.max(
              0.0,
              constraints.maxWidth - horizontalInset * 2,
            );
            final metrics = _layoutMetrics(
              availablePanelWidth,
              availablePanelHeight,
              isPad,
            );

            return Column(
              children: [
                SizedBox(height: topInset),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _buildMixPanel(metrics),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalInset + (isPad ? 20 : 10),
                    0,
                    horizontalInset + (isPad ? 20 : 10),
                    0,
                  ),
                  child: SizedBox(
                    height: progressRowHeight,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            TimeUtils.formatSeconds(
                              _position.inMilliseconds / 1000.0,
                            ),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _progress.clamp(0, 1),
                            onChanged: null, // null = 只展示进度，不可拖动
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            TimeUtils.formatSeconds(
                              _duration.inMilliseconds / 1000.0,
                            ),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: progressGap),
                // 底部：左关闭、中录音、右保存（对齐 iOS 布局）
                SizedBox(
                  width: double.infinity,
                  height: bottomBarHeight,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: horizontalInset + (isPad ? 24 : 50),
                        child: _RoundIconButton(
                          icon: Icons.close,
                          onTap: _isMixing || _isFinishing ? null : _cancel,
                        ),
                      ),
                      _RoundIconButton(
                        icon: _isRecording ? Icons.stop : Icons.mic,
                        highlight: _isRecording,
                        highlightColor: AppTheme.accentWarm,
                        onTap: _isMixing || _isFinishing
                            ? null
                            : _toggleRecording,
                        size: 50,
                      ),
                      Positioned(
                        right: horizontalInset + (isPad ? 24 : 50),
                        child: _RoundIconButton(
                          icon: Icons.file_download_rounded,
                          onTap: _isMixing || _isFinishing ? null : _save,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: bottomGap),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 底部圆形图标按钮（私有组件，仅本文件使用）
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.highlight = false,
    this.highlightColor = AppTheme.accent,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool highlight;
  final Color highlightColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null
          ? AppTheme.panelAlt.withValues(alpha: 0.55)
          : AppTheme.panelAlt,
      shape: CircleBorder(
        side: BorderSide(color: highlight ? highlightColor : AppTheme.accent),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            icon,
            size: highlight ? 22 : 20,
            color: highlight ? highlightColor : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
