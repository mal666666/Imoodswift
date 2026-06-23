import 'package:flutter/material.dart';

/// 颜色与设计令牌 + 全局 ThemeData。
/// 页面里尽量用 AppTheme.xxx，不要硬编码 Color(0xFF...)。
class AppTheme {
  static const background = Color(0xFF0C101C);
  static const panel = Color(0xFF182234);
  static const panelAlt = Color(0xFF1F2C42);
  static const accent = Color(0xFF50E8D1);
  static const accentWarm = Color(0xFFFF6E7A);
  static const textPrimary = Color(0xFFF0F5FF);
  static const textSecondary = Color(0xFFA4B1D1);

  /// 四种乐器格子的背景色：鼓 / 贝斯 / 吉他 / MIDI
  static const instrumentColors = [
    Color(0xFFFF5F80),
    Color(0xFFFFA150),
    Color(0xFF5AB4FF),
    Color(0xFF59E7CC),
  ];

  /// 返回 MaterialApp 使用的 ThemeData
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentWarm,
        surface: panel,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        inactiveTrackColor: panelAlt,
        thumbColor: textPrimary,
        // withValues(alpha: x) 是 Flutter 3.27+ 设置透明度的新写法
        overlayColor: accent.withValues(alpha: 0.12),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: panelAlt,
        contentTextStyle: const TextStyle(color: textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
