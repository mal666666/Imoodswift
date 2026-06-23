import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

import '../config/app_config.dart';
import '../utils/file_utils.dart';
import '../utils/image_utils.dart';

/// 音视频合成服务（无 UI）。
/// 对应 iOS 的 Composition.swift，通过 FFmpeg 命令行完成媒体处理。
class CompositionService {
  /// 用户按下录音键时，记录当前播放进度，最终合成时把录音对齐到这个时间点
  Duration recorderStartTime = Duration.zero;

  /// 第一步：多张图片 → 无声幻灯片 video.mov
  /// [images] PNG 字节列表；[duration] 秒；[fps] 帧率
  Future<void> writeImagesToVideo({
    required List<Uint8List> images,
    required double duration,
    required int fps,
  }) async {
    if (images.isEmpty || duration <= 0 || fps <= 0) {
      return;
    }

    final outputPath = await FileUtils.photoMovPath();
    await FileUtils.clearIfExists(outputPath);

    final tempDir = Directory('${Directory.systemTemp.path}/imood_frames');
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    await tempDir.create(recursive: true);

    final imageCount = images.length;
    // 总帧数 = 时长 × 帧率；图片按进度均匀切换（与 Swift 版逻辑一致）
    final totalFrames = (duration * fps).round().clamp(imageCount, 1 << 20);
    final frameDuration = 1 / fps;

    final frameAssignments = <int>[];
    for (var frame = 0; frame < totalFrames; frame++) {
      final progress = frame / totalFrames;
      final imageIndex = (progress * imageCount).floor().clamp(0, imageCount - 1);
      frameAssignments.add(imageIndex);
    }

    final segmentStarts = <int, int>{};
    for (var i = 0; i < frameAssignments.length; i++) {
      segmentStarts.putIfAbsent(frameAssignments[i], () => i);
    }
    segmentStarts[frameAssignments.last] = segmentStarts[frameAssignments.last] ?? 0;

    final uniqueImages = <int, File>{};
    for (var i = 0; i < imageCount; i++) {
      uniqueImages[i] = await ImageUtils.writeTempImage(
        images[i],
        'imood_img_$i.png',
      );
    }

    // FFmpeg concat 协议：按顺序拼接每段图片及其持续时间
    final concatFile = File('${tempDir.path}/concat.txt');
    final buffer = StringBuffer();
    var lastIndex = frameAssignments.first;
    var segmentStart = 0;

    void appendSegment(int imageIndex, int frameCount) {
      if (frameCount <= 0) return;
      final seconds = frameCount * frameDuration;
      buffer.writeln("file '${uniqueImages[imageIndex]!.path}'");
      buffer.writeln('duration $seconds');
    }

    for (var frame = 1; frame <= frameAssignments.length; frame++) {
      final current = frameAssignments[frame - 1];
      final isLast = frame == frameAssignments.length;
      if (current != lastIndex || isLast) {
        final endFrame = isLast ? frame : frame - 1;
        appendSegment(lastIndex, endFrame - segmentStart);
        segmentStart = frame - 1;
        lastIndex = current;
      }
    }
    buffer.writeln("file '${uniqueImages[frameAssignments.last]!.path}'");
    await concatFile.writeAsString(buffer.toString());

    final size = AppConfig.videoSize;
    final command = '-y -f concat -safe 0 -i "${concatFile.path}" '
        '-vf "scale=${size.width.toInt()}:${size.height.toInt()}:force_original_aspect_ratio=decrease,'
        'pad=${size.width.toInt()}:${size.height.toInt()}:(ow-iw)/2:(oh-ih)/2" '
        '-r $fps -c:v libx264 -pix_fmt yuv420p "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw StateError('图片合成视频失败: ${logs ?? returnCode}');
    }
  }

  /// 第二步：多个 MP3 asset 混成一条 audio.m4a
  /// [assetPaths] 如 assets/audio/pop/LX-鼓1.mp3
  Future<String?> mixAudioTracks(List<String> assetPaths) async {
    final tempFiles = <String>[];
    for (final assetPath in assetPaths) {
      // rootBundle.load：从打包进 app 的 assets 读取二进制
      final bytes = await rootBundle.load(assetPath);
      final tempFile = File(
        '${Directory.systemTemp.path}/${p.basename(assetPath)}',
      );
      await tempFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      tempFiles.add(tempFile.path);
    }

    if (tempFiles.isEmpty) {
      return null;
    }

    final outputPath = await FileUtils.audioPath();
    await FileUtils.clearIfExists(outputPath);

    // 只有一轨时直接转码，不必 amix
    if (tempFiles.length == 1) {
      final command = '-y -i "${tempFiles.first}" -c:a aac "$outputPath"';
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      if (!ReturnCode.isSuccess(returnCode)) {
        return null;
      }
      return outputPath;
    }

    final inputs = tempFiles.map((path) => '-i "$path"').join(' ');
    final mixInputs = List.generate(tempFiles.length, (i) => '[$i:a]').join('');
    final command = '-y $inputs -filter_complex '
        '"${mixInputs}amix=inputs=${tempFiles.length}:duration=longest:dropout_transition=0" '
        '-c:a aac "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      return null;
    }
    return outputPath;
  }

  /// 第三步：photo.mov + audio.m4a + 可选录音 → 最终 video.mov
  Future<String?> composeFinalVideo({
    required double videoDurationSeconds,
  }) async {
    final photoMov = await FileUtils.photoMovPath();
    if (await FileUtils.fileSize(photoMov) == 0) {
      return null;
    }

    final outputPath = await FileUtils.videoPath();
    await FileUtils.clearIfExists(outputPath);

    final audioPath = await FileUtils.audioPath();
    final recorderPath = await FileUtils.recorderPath();
    final hasAudio = await FileUtils.fileSize(audioPath) > 0;
    final hasRecorder = await FileUtils.fileSize(recorderPath) > 0;

    final durationArg = videoDurationSeconds.toStringAsFixed(2);
    var command = '-y -i "$photoMov"';

    if (hasAudio && hasRecorder) {
      final delayMs = recorderStartTime.inMilliseconds;
      command += ' -i "$audioPath" -i "$recorderPath" '
          '-filter_complex "[1:a]asetpts=PTS-STARTPTS[music];'
          '[2:a]adelay=$delayMs|$delayMs[rec];'
          '[music][rec]amix=inputs=2:duration=first:dropout_transition=0[aout]" '
          '-map 0:v -map "[aout]" -c:v libx264 -c:a aac -t $durationArg "$outputPath"';
    } else if (hasAudio) {
      command += ' -i "$audioPath" -map 0:v -map 1:a '
          '-c:v libx264 -c:a aac -t $durationArg "$outputPath"';
    } else if (hasRecorder) {
      command += ' -i "$recorderPath" -map 0:v -map 1:a '
          '-c:v libx264 -c:a aac -t $durationArg "$outputPath"';
    } else {
      command += ' -c:v libx264 -t $durationArg "$outputPath"';
    }

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      final logs = await session.getAllLogsAsString();
      throw StateError('音视频合成失败: ${logs ?? returnCode}');
    }
    return outputPath;
  }
}
