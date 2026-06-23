import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 图片处理：裁成正方形 PNG 字节。
/// 对应 iOS MGImage.swift 的 squareImage。
class ImageUtils {
  /// [aspectFill] true=居中裁切填满；false=完整显示可能留边
  static Future<Uint8List> squareImageBytes(
    Uint8List sourceBytes, {
    required Size size,
    required bool aspectFill,
  }) async {
    // ui 前缀：使用 dart:ui 底层绘图 API，不依赖 Widget
    final codec = await ui.instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final width = image.width.toDouble();
    final height = image.height.toDouble();

    Rect cropRect;
    Offset drawOrigin = Offset.zero;
    double? scale;

    if (height >= width) {
      if (aspectFill) {
        cropRect = Rect.fromLTWH(0, (height - width) / 2, width, width);
      } else {
        cropRect = Rect.fromLTWH(0, 0, width, height);
        scale = size.height / height;
        drawOrigin = Offset((height - width) / 2 * scale, 0);
      }
    } else {
      if (aspectFill) {
        cropRect = Rect.fromLTWH((width - height) / 2, 0, height, height);
      } else {
        cropRect = Rect.fromLTWH(0, 0, width, height);
        scale = size.width / width;
        drawOrigin = Offset(0, (width - height) / 2 * scale);
      }
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    if (aspectFill) {
      canvas.drawImageRect(
        image,
        cropRect,
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
    } else {
      canvas.scale(scale!);
      canvas.drawImageRect(image, cropRect, cropRect.shift(drawOrigin), paint);
    }

    final picture = recorder.endRecording();
    final output = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await output.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    output.dispose();
    return byteData!.buffer.asUint8List();
  }

  /// 写入系统临时目录，供 FFmpeg 读取
  static Future<File> writeTempImage(Uint8List bytes, String name) async {
    final file = File('${Directory.systemTemp.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
