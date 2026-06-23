# Imood Flutter 架构手册（学习 & 维护）

> 从架构师视角梳理本项目：每一层的职责、关键属性/方法含义、依赖关系、以及后期改动的安全边界。

---

## 1. 架构总览

```
┌─────────────────────────────────────────────────────────┐
│  Presentation  表现层                                    │
│  screens/ + widgets/                                     │
│  负责：UI、用户交互、页面状态                               │
└───────────────────────┬─────────────────────────────────┘
                        │ 调用
┌───────────────────────▼─────────────────────────────────┐
│  Domain / Model  领域层                                  │
│  models/ + l10n/ + config/                               │
│  负责：业务常量、曲目目录、文案、主题（无平台依赖）            │
└───────────────────────┬─────────────────────────────────┘
                        │ 调用
┌───────────────────────▼─────────────────────────────────┐
│  Service  服务层                                         │
│  services/                                               │
│  负责：音视频合成、音频会话、与原生能力打交道                   │
└───────────────────────┬─────────────────────────────────┘
                        │ 调用
┌───────────────────────▼─────────────────────────────────┐
│  Utils  工具层                                           │
│  utils/                                                  │
│  负责：图片处理、文件路径、资源检测、时间格式化                 │
└───────────────────────┬─────────────────────────────────┘
                        │ 依赖
┌───────────────────────▼─────────────────────────────────┐
│  Platform  平台 & 第三方                                  │
│  FFmpeg / just_audio / image_picker / video_player …     │
└─────────────────────────────────────────────────────────┘
```

**设计原则（维护时记住）：**

| 原则 | 含义 |
|------|------|
| 单向依赖 | `screens` → `services` → `utils`，不要反向 import |
| 无 UI 的服务 | `CompositionService` 不出现 `BuildContext` / `Widget` |
| 配置集中 | 改视频分辨率、时长、文件名 → 只改 `AppConfig` |
| 资源与逻辑分离 | 曲目名在 `MusicCatalog`，MP3 在 `assets/audio/` |

---

## 2. Flutter 核心概念（读本项目的钥匙）

### 2.1 Widget 树

Flutter 一切皆 Widget。两类常用：

| 类型 | 特点 | 本项目例子 |
|------|------|-----------|
| `StatelessWidget` | 无内部可变状态，靠外部参数重建 | `ImoodApp`, `ComposerCell`, `LoadingOverlay` |
| `StatefulWidget` | 有 `State`，可 `setState()` 触发重绘 | `HomeScreen`, `ComposerScreen` |

### 2.2 State 与 setState

```dart
setState(() {
  _isPlaying = true;  // 修改状态
});
// setState 之后 build() 会重新执行，UI 更新
```

**规则：** 只在 `State` 类里改 `_` 开头的字段，改完包在 `setState` 里。

### 2.3 async / Future

IO 操作（选图、FFmpeg、播放）都是异步：

```dart
Future<void> _pickPhotos() async {
  final files = await _picker.pickMultiImage();
  setState(() { ... });
}
```

### 2.4 Stream 订阅（作曲页进度条）

```dart
_player.positionStream.listen((position) { ... });
```

**维护要点：** `initState` 里订阅，`dispose` 里 `_positionSub?.cancel()`，防内存泄漏。

---

## 3. 入口 `lib/main.dart`

| 符号 | 类型 | 职责 |
|------|------|------|
| `main()` | 函数 | 程序入口；`ensureInitialized()` 必须在 runApp 前调用 |
| `ImoodApp` | StatelessWidget | 根组件，配置全局 `Theme` 和首页 |
| `MaterialApp` | Flutter 框架 | 提供路由、主题、Scaffold 等 Material 能力 |
| `home: HomeScreen()` | 属性 | 应用打开后的第一个页面 |

---

## 4. 配置层 `lib/config/`

### `AppConfig` — 业务常量（对应 Swift `MGBase`）

| 属性 | 含义 |
|------|------|
| `videoSize` | 输出视频分辨率 1280×1280 |
| `outputFps` | 帧率 24 |
| `minDuration` / `maxDuration` / `defaultDuration` | 视频时长滑块范围 10–30s，默认 20s |
| `maxPhotos` | 最多选 9 张照片 |
| `photoMov` | 中间产物：纯图片幻灯片视频 |
| `audioName` | 中间产物：混音后的 m4a |
| `videoName` | 最终产物：带音视频 mov |
| `recorderName` | 用户录音文件 |

### `AppTheme` — 视觉设计令牌

| 属性 | 用途 |
|------|------|
| `background`, `panel`, `panelAlt` | 背景 / 卡片色 |
| `accent`, `accentWarm` | 主强调色 / 录音警告色 |
| `textPrimary`, `textSecondary` | 主/次文字色 |
| `instrumentColors[0..3]` | 鼓、贝斯、吉他、MIDI 四格颜色 |
| `dark()` | 返回全局 `ThemeData`，在 `main.dart` 注入 |

**维护：** 换肤只改这一文件 + 必要时 `ThemeData` 扩展。

---

## 5. 领域模型 `lib/models/music_catalog.dart`

### `MusicStyle` 枚举

四种音乐风格：`pop | metal | nostalgia | electronic`

### `MusicStyleX` 扩展

|  getter | 含义 |
|---------|------|
| `key` | 字符串标识，如 `"pop"` |
| `assetFolder` | Flutter assets 路径，如 `assets/audio/pop` |

### `MusicCatalog` 类

| 成员 | 含义 |
|------|------|
| `instrumentKeys` | 4 个乐器的 i18n key |
| `_popTracks` 等 | 4×5 曲目文件名（不含扩展名） |
| `tracksFor(style)` | 按风格返回 4×5 二维列表 |
| `assetPath(style, instrumentIndex, patternIndex)` | 完整 asset 路径，如 `assets/audio/pop/LX-鼓1.mp3` |

**维护：** 新增曲目 → 改 `_xxxTracks` + 放入对应 `assets/audio/` 目录 + `flutter pub get` 后全量重启。

---

## 6. 国际化 `lib/l10n/l10n.dart`

| 方法 | 含义 |
|------|------|
| `L10n.t('home_export')` | 按系统语言取文案，fallback 到英文 |
| `_currentLanguageCode()` | 解析 `zh-Hans` / `zh-Hant` / `en` |

**维护：** 新文案加 key 到 `_values` map，页面里用 `L10n.t('key')`。

---

## 7. 服务层 `lib/services/`

### `AudioService` — 音频会话

| 方法 | 何时调用 | 作用 |
|------|----------|------|
| `ensurePlayback()` | 播放 MP3 / 视频前 | iOS 设为 playback 类别，Android 申请音频焦点 |
| `ensurePlayAndRecord()` | 开始录音前 | iOS 设为 playAndRecord + 扬声器外放 |

对应 Swift：`AVAudioSession.setCategory(.playAndRecord)` + `overrideOutputAudioPort(.speaker)`

### `CompositionService` — 媒体合成核心（对应 `Composition.swift`）

| 属性/方法 | 含义 |
|-----------|------|
| `recorderStartTime` | 录音开始时刻，用于最终合成时对齐音轨 |
| `writeImagesToVideo(...)` | 多图 → `photo.mov`（FFmpeg concat + H.264） |
| `mixAudioTracks(assetPaths)` | 多 MP3 asset → 混音 → `audio.m4a` |
| `composeFinalVideo(videoDurationSeconds:)` | `photo.mov` + `audio.m4a` + 可选录音 → `video.mov` |

**数据流：**

```
照片 → writeImagesToVideo → photo.mov
选曲 → mixAudioTracks     → audio.m4a
录音 → recoder.m4a
三者 → composeFinalVideo  → video.mov → 导出相册
```

---

## 8. 工具层 `lib/utils/`

| 类 | 关键 API | 职责 |
|----|----------|------|
| `ImageUtils` | `squareImageBytes(...)` | 裁切/缩放为正方形 PNG 字节 |
| `FileUtils` | `documentPath`, `clearIfExists`, `fileSize` | 应用沙盒 Documents 路径管理 |
| `TimeUtils` | `formatSeconds` | `125` → `"02:05"` |
| `AssetUtils` | `exists(assetPath)` | 播放前检查 MP3 是否打包进 app |

---

## 9. 表现层 — 主页 `HomeScreen`

### 状态字段（`_HomeScreenState`）

| 字段 | 类型 | 含义 |
|------|------|------|
| `_rawImages` | `List<Uint8List>` | 缩略图条显示用（已 aspectFill 裁切） |
| `_squareImages` | `List<Uint8List>` | 合成视频用（1280 正方形） |
| `_player` | `VideoPlayerController?` | 预览合成后的视频 |
| `_isPlaying` | `bool` | 是否正在播放 |
| `_isComposing` | `bool` | FFmpeg 合成中，显示 LoadingOverlay |
| `_needMix` | `bool` | `true` 时下次播放需重新合成 |
| `_duration` | `double` | 用户选的秒数 |
| `_deleteIndex` | `int?` | 长按后显示删除按钮的索引 |
| `_previewImage` | `Uint8List?` | 点击缩略图时大图预览 |

### 关键方法

| 方法 | 职责 |
|------|------|
| `_pickPhotos()` | 请求相册权限 → 多选图片 → 写入 `_rawImages` |
| `_showStylePicker()` | 弹窗选风格 → 打开 `ComposerScreen` |
| `_togglePlay()` | 无图 toast；有图则合成或续播 |
| `_exportVideo()` | `Gal.putVideo` 保存到系统相册 |
| `_refreshPreparedImages()` | 同步 `_squareImages`，标记 `_needMix = true` |

---

## 10. 表现层 — 作曲页 `ComposerScreen`

### 状态字段

| 字段 | 含义 |
|------|------|
| `_selectedInstrument` | 当前选中的乐器索引 0–3 |
| `_selectedPatterns[4]` | 每个乐器选的片段 0–4，-1 表示未选 |
| `_selectedAssets[4]` | 对应 asset 路径，供混音用 |
| `_player` | `just_audio` 播放器 |
| `_recorder` | 麦克风录音 |
| `_isRecording` / `_isPlaying` / `_isMixing` | UI 状态 |
| `_progress`, `_position`, `_duration` | 进度条数据 |

### 关键方法

| 方法 | 职责 |
|------|------|
| `_layoutMetrics(...)` | 按屏幕算格子尺寸（对齐 Swift AutoLayout 逻辑） |
| `_togglePattern(i)` | 选/取消片段，并试听该 MP3 |
| `_mixAndPlay()` | 混音所有已选轨并播放 |
| `_toggleRecording()` | 录音开关，记录 `recorderStartTime` |
| `_save()` | 混音写入 `audio.m4a`，返回主页 |
| `_cancel()` | 清空 audio/recorder，放弃返回 |

### `_ComposerLayoutMetrics`（私有布局 DTO）

纯数据类，把布局计算从 `build` 中抽离，便于对照 iOS 版 `layoutMetrics(for:)` 维护。

---

## 11. 组件 `lib/widgets/`

| Widget | 属性 | 职责 |
|--------|------|------|
| `ComposerCell` | `title`, `subtitle`, `backgroundColor`, `selected` | 作曲格子的统一样式 |
| `ImageThumbnailCell` | `bytes`, `showDelete`, `onDelete` | 照片缩略图 + 删除角标 |
| `AddPhotoCell` | — | 「+」添加照片 |
| `LoadingOverlay` | `message` | 全屏半透明 loading |

**原则：** 无业务逻辑，只接收数据和回调。

---

## 12. 第三方依赖地图

| 包 | 本项目用途 |
|----|-----------|
| `image_picker` | 相册多选 |
| `video_player` | 主页预览视频 |
| `just_audio` | 作曲页试听 / 混音播放 |
| `record` | 麦克风录音 |
| `audio_session` | iOS/Android 音频路由 |
| `ffmpeg_kit_flutter_new` | 图片转视频、混音、最终合成 |
| `path_provider` | 沙盒 Documents 路径 |
| `permission_handler` | 相册、麦克风权限 |
| `gal` | 导出视频到相册 |

---

## 13. 后期维护速查

| 想改… | 去哪个文件 |
|-------|-----------|
| 新增音乐风格 | `music_catalog.dart` + `assets/audio/` + `home_screen` 风格列表 |
| 改视频分辨率/时长 | `app_config.dart` |
| 改配色 | `app_theme.dart` |
| 改合成逻辑 | `composition_service.dart` |
| 改主页 UI/交互 | `home_screen.dart` |
| 改作曲页 UI/交互 | `composer_screen.dart` |
| 改文案 | `l10n/l10n.dart` |
| iOS 权限文案 | `ios/Runner/Info.plist` |
| 最低 iOS 版本 | `ios/Podfile` + `project.pbxproj` |

---

## 14. 与 Swift 原版对照表

| Swift | Flutter |
|-------|---------|
| `ViewController` | `HomeScreen` |
| `ComposerViewController` | `ComposerScreen` |
| `Composition` | `CompositionService` |
| `MGBase` | `AppConfig` + `AppTheme` |
| `L10n` | `l10n/l10n.dart` |
| `MGImage.squareImage` | `ImageUtils.squareImageBytes` |
| `MGURL.domainPathWith` | `FileUtils.documentPath` |
| `AVPlayer` | `VideoPlayerController` / `AudioPlayer` |
| `AVAudioSession` | `AudioService` |
| `Resouce/流行/` 等 | `assets/audio/pop/` 等 |

---

## 15. 推荐学习路径

1. 读 `main.dart` → 理解 Widget 树入口  
2. 读 `home_screen.dart` → 理解 StatefulWidget + async  
3. 读 `composer_screen.dart` → 理解 Stream + 复杂布局  
4. 读 `composition_service.dart` → 理解服务层与平台能力  
5. 对照 Swift 同名文件，加深「跨平台移植」直觉  

---

*本文档随项目演进更新。改架构前先更新此文件。*
