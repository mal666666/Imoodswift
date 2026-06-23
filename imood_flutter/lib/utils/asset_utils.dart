import 'package:flutter/services.dart';

/// 检查 pubspec.yaml 里注册的 asset 是否真实打包进 app
class AssetUtils {
  static Future<bool> exists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
