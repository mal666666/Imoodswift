import 'dart:ui';

/// 应用级常量。全部用 static const，不需要创建实例即可访问。
/// 对应 iOS 项目的 MGBase.swift。
class AppConfig {
  /// 输出视频宽高（逻辑像素，FFmpeg 合成时使用）
  static const videoSize = Size(1280, 1280);
  static const outputFps = 24;
  static const minDuration = 10.0;
  static const maxDuration = 30.0;
  static const defaultDuration = 20.0;
  static const maxPhotos = 9;

  /// 沙盒 Documents 目录下的中间/最终文件名
  static const photoMov = 'photo.mov'; // 纯图片幻灯片
  static const audioName = 'audio.m4a'; // 混音后的背景音乐
  static const videoName = 'video.mov'; // 最终可导出的视频
  static const recorderName = 'recoder.m4a'; // 用户录音
}
