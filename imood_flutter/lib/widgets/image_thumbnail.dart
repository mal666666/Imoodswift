import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// 底部横向照片条里的单张缩略图
class ImageThumbnailCell extends StatelessWidget {
  const ImageThumbnailCell({
    super.key,
    required this.bytes,
    this.showDelete = false,
    this.onDelete,
  });

  /// 图片原始字节，Image.memory 可直接显示
  final Uint8List bytes;
  final bool showDelete;
  /// VoidCallback = void Function()，无参无返回值的回调
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        if (showDelete)
          Positioned(
            top: 0,
            right: 0,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.cancel, color: AppTheme.accentWarm, size: 20),
              onPressed: onDelete,
            ),
          ),
      ],
    );
  }
}

/// 照片条末尾的「+」按钮
class AddPhotoCell extends StatelessWidget {
  const AddPhotoCell({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panelAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: const Icon(Icons.add, color: AppTheme.accent, size: 28),
    );
  }
}
