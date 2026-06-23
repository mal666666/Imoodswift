import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';

/// 应用沙盒文件路径工具。
/// path_provider 提供各平台「Documents」等标准目录。
class FileUtils {
  static Future<Directory> documentsDir() async {
    return getApplicationDocumentsDirectory();
  }

  static Future<String> documentPath(String name) async {
    final dir = await documentsDir();
    return '${dir.path}/$name';
  }

  static Future<File> documentFile(String name) async {
    return File(await documentPath(name));
  }

  /// 写入新文件前先删旧文件，避免 FFmpeg 追加或冲突
  static Future<void> clearIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<int> fileSize(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      return 0;
    }
    return file.length();
  }

  static Future<bool> hasAudio(String name) async {
    return await fileSize(await documentPath(name)) > 0;
  }

  static Future<bool> hasVideo(String name) async {
    return await fileSize(await documentPath(name)) > 0;
  }

  static Future<String> photoMovPath() => documentPath(AppConfig.photoMov);
  static Future<String> audioPath() => documentPath(AppConfig.audioName);
  static Future<String> videoPath() => documentPath(AppConfig.videoName);
  static Future<String> recorderPath() => documentPath(AppConfig.recorderName);
}
