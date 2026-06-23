# Imood Flutter

原 iOS Swift 项目 [Imood_swift](../Imood_swift) 的 Flutter 跨平台移植版。

## 功能

- 选择最多 9 张照片，预览与删除
- 调节视频时长（10–30 秒）
- 四种音乐风格：流行、金属、思念、电子
- 四种乐器 × 五种片段，可混音试听
- 麦克风录音叠加到最终视频
- 照片合成幻灯片视频 + 音乐 + 录音，一键播放
- 导出视频到系统相册

## 运行

```bash
cd imood_flutter
flutter pub get
flutter run
```

## 音频资源

请将原 iOS 工程 Bundle 中的 MP3 文件复制到对应目录（文件名需与 Swift 版一致）：

| 风格 | 目录 | 示例文件名 |
|------|------|-----------|
| 流行 | `assets/audio/pop/` | `LX-鼓1.mp3`, `LX-贝斯1.mp3` |
| 金属 | `assets/audio/metal/` | `JS-鼓1.mp3`, `JS-贝斯1.mp3` |
| 思念 | `assets/audio/nostalgia/` | `SN-鼓1.mp3`, `SN-贝斯1.mp3` |
| 电子 | `assets/audio/electronic/` | `DZ-鼓1.mp3`, `DZ-贝斯1.mp3` |

完整曲目列表见 `lib/models/music_catalog.dart`。

## 项目结构

```
lib/
  config/          # 主题与常量
  l10n/            # 多语言文案
  models/          # 音乐风格与曲目目录
  screens/         # 主页、作曲页
  services/        # FFmpeg 音视频合成
  utils/           # 图片处理、文件、时间格式化
  widgets/         # 通用 UI 组件
```

## 依赖说明

- **ffmpeg_kit_flutter_new**：图片转视频、音轨混音、最终导出
- **image_picker**：相册选图
- **video_player / just_audio**：视频与音频播放
- **record**：录音
- **gal**：保存视频到相册

## 与 Swift 版的对应关系

| Swift | Flutter |
|-------|---------|
| `ViewController` | `HomeScreen` |
| `ComposerViewController` | `ComposerScreen` |
| `Composition` | `CompositionService` |
| `MGBase` | `AppConfig` + `AppTheme` |
| `L10n` | `lib/l10n/l10n.dart` |
