import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// 作曲页格子 UI（纯展示，不含点击逻辑）。
/// 点击由父组件 ComposerScreen 的 InkWell 处理。
class ComposerCell extends StatelessWidget {
  const ComposerCell({
    super.key,
    required this.title,
    this.subtitle,
    required this.backgroundColor,
    this.largeTitle = false,
    this.selected = false,
  });

  final String title;
  final String? subtitle;
  final Color backgroundColor;
  final bool largeTitle;
  /// true 时显示更粗的白色边框，表示选中
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: selected
              ? AppTheme.textPrimary
              : Colors.white.withValues(alpha: 0.12),
          width: selected ? 2 : 1,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: largeTitle ? 30 : 24,
              fontWeight: FontWeight.bold,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          // 条件渲染：subtitle 有值才显示下方小字（已选片段编号）
          if (subtitle != null && subtitle!.isNotEmpty)
            Positioned(
              bottom: 12,
              child: Text(
                subtitle!,
                style: TextStyle(
                  color: AppTheme.textPrimary.withValues(alpha: 0.88),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
