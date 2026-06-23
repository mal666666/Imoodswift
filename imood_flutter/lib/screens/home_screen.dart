import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_player/video_player.dart';

import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../l10n/l10n.dart';
import '../models/music_catalog.dart';
import '../screens/composer_screen.dart';
import '../services/audio_service.dart';
import '../services/composition_service.dart';
import '../utils/file_utils.dart';
import '../utils/image_utils.dart';
import '../widgets/image_thumbnail.dart';
import '../widgets/loading_overlay.dart';

/// 主页：选照片、设时长、选音乐、合成预览、导出。
/// 对应 iOS ViewController.swift。
///
/// StatefulWidget = 有可变状态的页面；State 类名约定为 _XxxState（下划线表示库内私有）。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  final _composition = CompositionService();

  /// 缩略图条显示用（已 aspectFill 裁切）
  final _rawImages = <Uint8List>[];

  /// 送给 FFmpeg 合成用（1280 正方形，aspectFill: false）
  final _squareImages = <Uint8List>[];

  /// ? 表示可空：未初始化时为 null
  VideoPlayerController? _player;
  bool _isPlaying = false;
  bool _isComposing = false;
  bool _isPreparingPhotos = false;

  /// true = 照片/时长/音乐变了，下次播放需重新走 FFmpeg
  bool _needMix = true;
  double _duration = AppConfig.defaultDuration;

  /// 长按某张缩略图后，显示删除按钮的索引
  int? _deleteIndex;

  /// 点击缩略图时在大预览区显示的静态图
  Uint8List? _previewImage;

  /// 页面销毁时释放视频控制器，防止内存泄漏
  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  /// 根据 _rawImages 重新生成 _squareImages，并标记需要重新合成
  Future<void> _refreshPreparedImages() async {
    _needMix = true;
    _squareImages
      ..clear() // .. 级联调用：对同一对象连续操作
      ..addAll(
        // Future.wait：等多张图并行处理完
        await Future.wait(
          _rawImages.map(
            (bytes) => ImageUtils.squareImageBytes(
              bytes,
              size: AppConfig.videoSize,
              aspectFill: false,
            ),
          ),
        ),
      );
  }

  /// 从相册多选图片
  Future<void> _pickPhotos() async {
    if (_isPreparingPhotos) return;

    final status = await Permission.photos.request();
    if (!status.isGranted && !status.isLimited) {
      _showToast('需要相册权限才能选择照片');
      return;
    }

    final remaining = AppConfig.maxPhotos - _rawImages.length;
    if (remaining <= 0) return;

    final files = await _picker.pickMultiImage(limit: remaining);
    if (files.isEmpty) return;

    setState(() => _isPreparingPhotos = true);

    try {
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final squared = await ImageUtils.squareImageBytes(
          bytes,
          size: AppConfig.videoSize,
          aspectFill: true,
        );
        _rawImages.add(squared);
      }
      await _refreshPreparedImages();
      if (mounted) setState(() {});
    } finally {
      if (mounted) {
        setState(() => _isPreparingPhotos = false);
      }
    }
  }

  /// 弹出风格选择对话框，进入作曲页 ComposerScreen
  Future<void> _showStylePicker() async {
    final styles = [
      (
        style: MusicStyle.pop,
        title: L10n.t('style_pop'),
        subtitle: 'POP',
        icon: Icons.graphic_eq_rounded,
        color: const Color(0xFF50E8D1),
      ),
      (
        style: MusicStyle.metal,
        title: L10n.t('style_metal'),
        subtitle: 'METAL',
        icon: Icons.album_rounded,
        color: const Color(0xFFFF8C72),
      ),
      (
        style: MusicStyle.nostalgia,
        title: L10n.t('style_nostalgia'),
        subtitle: 'MEMORY',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFFFFC85A),
      ),
      (
        style: MusicStyle.electronic,
        title: L10n.t('style_electronic'),
        subtitle: 'ELECTRO',
        icon: Icons.bolt_rounded,
        color: const Color(0xFF7AA8FF),
      ),
    ];
    final scrollController = ScrollController();

    try {
      await showDialog<void>(
        context: context,
        builder: (context) {
          final screenSize = MediaQuery.sizeOf(context);
          final isCompactHeight = screenSize.height < 780;
          final dialogMaxHeight = math.min(screenSize.height - 48, 560.0);
          final titleSize = isCompactHeight ? 22.0 : 24.0;
          final messageSize = isCompactHeight ? 13.0 : 14.0;
          final tileTitleSize = isCompactHeight ? 18.0 : 19.0;
          final tileVerticalPadding = isCompactHeight ? 12.0 : 14.0;
          final tileIconSize = isCompactHeight ? 18.0 : 20.0;
          final tileBadgeSize = isCompactHeight ? 34.0 : 38.0;

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: dialogMaxHeight,
              ),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  isCompactHeight ? 18 : 20,
                  16,
                  10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.panel,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.panelAlt.withValues(alpha: 0.95),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.24),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: isCompactHeight ? 42 : 46,
                      height: isCompactHeight ? 42 : 46,
                      decoration: BoxDecoration(
                        color: AppTheme.panelAlt,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(
                        Icons.library_music_rounded,
                        color: AppTheme.accent,
                        size: isCompactHeight ? 22 : 24,
                      ),
                    ),
                    SizedBox(height: isCompactHeight ? 12 : 14),
                    Text(
                      L10n.t('common_notice'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: isCompactHeight ? 6 : 8),
                    Text(
                      L10n.t('home_pick_style_message'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: messageSize,
                        height: 1.35,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    SizedBox(height: isCompactHeight ? 12 : 16),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final useTwoColumns = constraints.maxWidth >= 300;
                          final tileWidth = useTwoColumns
                              ? (constraints.maxWidth - 20) / 2
                              : constraints.maxWidth - 8;

                          return Scrollbar(
                            controller: scrollController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            radius: const Radius.circular(999),
                            thickness: 6,
                            child: SingleChildScrollView(
                              controller: scrollController,
                              padding: const EdgeInsets.only(
                                right: 8,
                                bottom: 8,
                              ),
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: styles.map((item) {
                                  return SizedBox(
                                    width: tileWidth,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () async {
                                        Navigator.pop(context);
                                        // push 打开新页面；<bool> 表示返回时可能带回 true/false
                                        final saved =
                                            await Navigator.of(
                                              context,
                                            ).push<bool>(
                                              MaterialPageRoute(
                                                fullscreenDialog: true,
                                                builder: (_) => ComposerScreen(
                                                  style: item.style,
                                                ),
                                              ),
                                            );
                                        if (saved == true) {
                                          setState(() => _needMix = true);
                                        }
                                      },
                                      child: Ink(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: tileVerticalPadding,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.panelAlt,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                          border: Border.all(
                                            color: item.color.withValues(
                                              alpha: 0.38,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: tileBadgeSize,
                                              height: tileBadgeSize,
                                              decoration: BoxDecoration(
                                                color: item.color.withValues(
                                                  alpha: 0.14,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                item.icon,
                                                color: item.color,
                                                size: tileIconSize,
                                              ),
                                            ),
                                            SizedBox(
                                              height: isCompactHeight ? 8 : 10,
                                            ),
                                            Text(
                                              item.title,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: tileTitleSize,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.subtitle,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: item.color.withValues(
                                                  alpha: 0.88,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      child: Text(L10n.t('common_cancel')),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      scrollController.dispose();
    }
  }

  /// 大预览区播放/暂停：必要时先 FFmpeg 合成再播 video.mov
  Future<void> _togglePlay() async {
    if (_isComposing) return;

    if (_squareImages.isEmpty) {
      _showToast(L10n.t('home_toast_add_photos'));
      return;
    }

    if (_isPlaying) {
      await _player?.pause();
      setState(() {
        _isPlaying = false;
        _previewImage = null;
      });
      return;
    }

    setState(() => _isPlaying = true);

    if (_needMix) {
      setState(() => _isComposing = true);
      try {
        await _composition.writeImagesToVideo(
          images: _squareImages,
          duration: _duration,
          fps: AppConfig.outputFps,
        );
        final url = await _composition.composeFinalVideo(
          videoDurationSeconds: _duration,
        );
        if (url == null) {
          throw StateError('compose failed');
        }
        await _player?.dispose();
        await AudioService.ensurePlayback();
        _player = VideoPlayerController.file(
          await FileUtils.documentFile(AppConfig.videoName),
        );
        await _player!.initialize();
        _player!.addListener(_onPlaybackUpdate);
        await _player!.play();
        setState(() {
          _needMix = false;
          _previewImage = null;
        });
      } catch (_) {
        _showToast(L10n.t('home_toast_compose_failed_retry'));
        setState(() {
          _isPlaying = false;
          _previewImage = null;
        });
      } finally {
        setState(() => _isComposing = false);
      }
    } else {
      await _player?.play();
    }
  }

  /// VideoPlayerController 状态变化回调：播完自动回到开头
  void _onPlaybackUpdate() {
    final controller = _player;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.position >= controller.value.duration) {
      controller.seekTo(Duration.zero);
      controller.pause();
      // mounted：State 是否还在 Widget 树上，异步回调里必须先判断
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _previewImage = null;
        });
      }
    }
  }

  /// 把沙盒里的 video.mov 保存到系统相册
  Future<void> _exportVideo() async {
    final path = await FileUtils.videoPath();
    if (await FileUtils.fileSize(path) == 0) {
      _showToast(L10n.t('home_toast_compose_failed_retry'));
      return;
    }

    final status = await Permission.photos.request();
    if (!status.isGranted && !status.isLimited) {
      _showToast('需要相册权限才能导出视频');
      return;
    }

    await Gal.putVideo(path);
    _showToast(L10n.t('home_toast_export_success'));
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _removePhoto(int index) {
    _rawImages.removeAt(index);
    _refreshPreparedImages().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final horizontalInset = 0.0;
    // MediaQuery：读取屏幕尺寸；shortestSide>=600 通常视为平板
    final isPad = MediaQuery.sizeOf(context).shortestSide >= 600;
    final previewTopInset = isPad ? 20.0 : 8.0;
    final photoStripHeight = isPad ? 92.0 : 80.0;
    final musicButtonSize = isPad ? 42.0 : 35.0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Imood'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _exportVideo,
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.panelAlt,
                foregroundColor: AppTheme.textPrimary,
                minimumSize: const Size(0, 34),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: const BorderSide(color: AppTheme.accent),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              child: Text(L10n.t('home_export')),
            ),
          ),
        ],
      ),
      // Stack 可以把多个组件“叠”在一起；这里用于把加载遮罩盖在主界面上方。
      body: Stack(
        children: [
          // LayoutBuilder 可以拿到 body 当前的可用宽高，适合做响应式布局。
          LayoutBuilder(
            builder: (context, constraints) {
              const previewToStripGap = 8.0;
              const stripToControlsGap = 40.0;
              const sliderMinTouchHeight = 48.0;
              final controlsHeight = math.max(
                musicButtonSize,
                sliderMinTouchHeight,
              );
              final reservedHeight =
                  previewTopInset +
                  previewToStripGap +
                  photoStripHeight +
                  stripToControlsGap +
                  controlsHeight;
              final availablePreviewWidth = math.max(
                0.0,
                constraints.maxWidth - horizontalInset * 2,
              );
              final availablePreviewHeight = math.max(
                160.0,
                constraints.maxHeight - reservedHeight,
              );
              final previewSize = math.min(
                availablePreviewWidth,
                availablePreviewHeight,
              );

              return SingleChildScrollView(
                child: Column(
                  // Column 按从上到下的顺序排列页面主体内容。
                  children: [
                    // --- 上方 1:1 预览区 ---
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalInset, // 左边距
                        previewTopInset, // 平板顶部留白更大，手机留白较小
                        horizontalInset, // 右边距
                        0, // 底部不额外留白
                      ),
                      child: Center(
                        child: SizedBox.square(
                          // 正方形边长取“可用宽度”和“可用高度”的较小值，避免小窗口溢出。
                          dimension: previewSize,
                          child: ClipRRect(
                            // ClipRRect 用来把内部视频/图片裁剪成圆角。
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              // StackFit.expand 让内部每一层尽量铺满整个预览区域。
                              fit: StackFit.expand,
                              children: [
                                // 预览区默认背景，避免视频或图片还没加载时出现空白。
                                Container(color: AppTheme.panelAlt),
                                // 条件渲染：播放器存在、已初始化、正在播放，并且没有选中静态预览图时，才显示视频。
                                if (_player != null &&
                                    _player!.value.isInitialized &&
                                    _isPlaying &&
                                    _previewImage == null)
                                  VideoPlayer(_player!),
                                // 如果用户点选了某张照片，则用这张图片覆盖视频预览。
                                if (_previewImage != null)
                                  Image.memory(
                                    _previewImage!,
                                    fit: BoxFit.cover,
                                  ),
                                // 视频未播放，或者当前显示的是静态图片时，显示播放按钮。
                                if (!_isPlaying || _previewImage != null)
                                  Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      // InkWell 提供点击水波纹效果；点击后切换播放/暂停。
                                      onTap: _togglePlay,
                                      child: Center(
                                        child: Icon(
                                          Icons.play_circle_fill,
                                          size: 72,
                                          color: AppTheme.textPrimary
                                              .withValues(alpha: 0.92),
                                        ),
                                      ),
                                    ),
                                  ),
                                // 视频播放中时放一层透明点击区域，点击预览区即可暂停。
                                if (_isPlaying && _previewImage == null)
                                  GestureDetector(
                                    onTap: _togglePlay,
                                    // translucent 表示透明区域也能响应点击。
                                    behavior: HitTestBehavior.translucent,
                                    child: const SizedBox.expand(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: previewToStripGap),
                    // --- 横向照片条 ---
                    SizedBox(
                      height: photoStripHeight,
                      child: ListView.separated(
                        // 横向滚动列表，用来展示已选照片缩略图。
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalInset + 5,
                        ),
                        // 多加 1 个 item，用来放最后的“添加照片”按钮。
                        itemCount: _rawImages.length + 1,
                        // 每个缩略图之间的间距。
                        separatorBuilder: (_, _) => const SizedBox(width: 5),
                        itemBuilder: (context, index) {
                          // 当 index 等于照片数量时，说明走到了最后一个格子：显示添加按钮。
                          if (index == _rawImages.length) {
                            return GestureDetector(
                              onTap: _pickPhotos,
                              child: const SizedBox(
                                width: 70,
                                height: 70,
                                child: AddPhotoCell(),
                              ),
                            );
                          }

                          return GestureDetector(
                            onTap: () {
                              // 点击某张缩略图时，先暂停视频，再把这张图设为上方预览图。
                              _player?.pause();
                              setState(() {
                                // setState 会通知 Flutter：状态变了，需要重新构建界面。
                                _isPlaying = false;
                                _previewImage = _rawImages[index];
                              });
                            },
                            onLongPress: () {
                              // 长按缩略图后，记录当前要显示删除按钮的图片下标。
                              setState(() => _deleteIndex = index);
                              // 删除按钮只临时显示 3 秒，之后自动隐藏。
                              Future.delayed(const Duration(seconds: 3), () {
                                // mounted 用来确认当前页面还在树上，避免页面销毁后继续 setState。
                                if (mounted && _deleteIndex == index) {
                                  setState(() => _deleteIndex = null);
                                }
                              });
                            },
                            child: SizedBox(
                              width: 70,
                              height: 70,
                              child: ImageThumbnailCell(
                                bytes: _rawImages[index],
                                // 只有被长按的那一张才显示删除角标。
                                showDelete: _deleteIndex == index,
                                onDelete: () {
                                  // 点击删除角标后移除照片，并清空删除状态。
                                  _removePhoto(index);
                                  setState(() => _deleteIndex = null);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: stripToControlsGap),
                    // --- 音乐按钮 + 时长滑块 ---
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalInset + 10,
                      ),
                      child: Row(
                        children: [
                          // 左侧音乐按钮：点击后弹出风格/音乐选择器。
                          Material(
                            color: AppTheme.panelAlt,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: _showStylePicker,
                              child: Container(
                                width: musicButtonSize,
                                height: musicButtonSize,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.accent),
                                ),
                                child: const Icon(
                                  Icons.library_music,
                                  color: AppTheme.accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            // Expanded 让 Slider 占满 Row 中剩余的横向空间。
                            child: Slider(
                              min: AppConfig.minDuration,
                              max: AppConfig.maxDuration,
                              value: _duration,
                              onChanged: (value) {
                                setState(() {
                                  // 滑动时更新目标视频时长。
                                  _duration = value;
                                  // 时长改变后，之前合成的视频不再匹配，需要重新合成。
                                  _needMix = true;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 50,
                            child: Text(
                              // round() 把滑块的 double 数值四舍五入成整数秒显示。
                              '${_duration.round()}s',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // 正在处理图片或合成视频时，在页面最上方覆盖 LoadingOverlay。
          if (_isPreparingPhotos || _isComposing)
            LoadingOverlay(
              message: L10n.t(
                _isPreparingPhotos
                    ? 'home_loading_preparing_photos'
                    : 'home_loading_composing',
              ),
            ),
        ],
      ),
    );
  }
}
