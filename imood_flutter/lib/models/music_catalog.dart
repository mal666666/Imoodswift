/// 音乐风格枚举。enum 是 Dart 的有限选项类型。
enum MusicStyle { pop, metal, nostalgia, electronic }

/// extension：给已有类型 MusicStyle 追加方法/属性，无需改 enum 本身。
extension MusicStyleX on MusicStyle {
  String get key {
    switch (this) {
      case MusicStyle.pop:
        return 'pop';
      case MusicStyle.metal:
        return 'metal';
      case MusicStyle.nostalgia:
        return 'nostalgia';
      case MusicStyle.electronic:
        return 'electronic';
    }
  }

  /// pubspec.yaml 里注册的 assets 目录路径
  String get assetFolder {
    switch (this) {
      case MusicStyle.pop:
        return 'assets/audio/pop';
      case MusicStyle.metal:
        return 'assets/audio/metal';
      case MusicStyle.nostalgia:
        return 'assets/audio/nostalgia';
      case MusicStyle.electronic:
        return 'assets/audio/electronic';
    }
  }
}

/// 曲目目录：4 种乐器 × 5 个片段的文件名。
/// 对应 iOS ComposerViewController 里的 musicLXArr 等数组。
class MusicCatalog {
  /// 乐器名称的 i18n key，用 L10n.t() 翻译后显示
  static const instrumentKeys = [
    'instrument_drum',
    'instrument_bass',
    'instrument_guitar',
    'instrument_midi',
  ];

  static const _popTracks = [
    ['LX-鼓1', 'LX-鼓2', 'LX-鼓3', 'LX-鼓4', 'LX-鼓5'],
    ['LX-贝斯1', 'LX-贝斯2', 'LX-贝斯3', 'LX-贝斯4', 'LX-贝斯5'],
    ['LX-主音吉他1', 'LX-主音吉他2', 'LX-主音吉他3', 'LX-主音吉他4', 'LX-主音吉他5'],
    ['LX-节奏吉他1', 'LX-节奏吉他2', 'LX-节奏吉他3', 'LX-节奏吉他4', 'LX-节奏吉他5'],
  ];

  static const _metalTracks = [
    ['JS-鼓1', 'JS-鼓2', 'JS-鼓3', 'JS-鼓4', 'JS-鼓5'],
    ['JS-贝斯1', 'JS-贝斯2', 'JS-贝斯3', 'JS-贝斯4', 'JS-贝斯5'],
    ['JS-主音吉他1', 'JS-主音吉他2', 'JS-主音吉他3', 'JS-主音吉他4', 'JS-主音吉他5'],
    ['JS-节奏吉他1', 'JS-节奏吉他2', 'JS-节奏吉他3', 'JS-节奏吉他4', 'JS-节奏吉他5'],
  ];

  static const _nostalgiaTracks = [
    ['SN-鼓1', 'SN-鼓2', 'SN-鼓3', 'SN-鼓4', 'SN-鼓5'],
    ['SN-贝斯1', 'SN-贝斯2', 'SN-贝斯3', 'SN-贝斯4', 'SN-贝斯5'],
    ['SN-吉他1', 'SN-吉他2', 'SN-吉他3', 'SN-吉他4', 'SN-吉他5'],
    ['SN-键盘1', 'SN-键盘2', 'SN-键盘3', 'SN-键盘4', 'SN-键盘5'],
  ];

  static const _electronicTracks = [
    ['DZ-鼓1', 'DZ-鼓2', 'DZ-鼓3', 'DZ-鼓4', 'DZ-鼓5'],
    ['DZ-贝斯1', 'DZ-贝斯2', 'DZ-贝斯3', 'DZ-贝斯4', 'DZ-贝斯5'],
    ['DZ-DJ1', 'DZ-DJ2', 'DZ-DJ3', 'DZ-DJ4', 'DZ-DJ5'],
    ['DZ-键盘1', 'DZ-键盘2', 'DZ-键盘3', 'DZ-键盘4', 'DZ-键盘5'],
  ];

  static List<List<String>> tracksFor(MusicStyle style) {
    switch (style) {
      case MusicStyle.pop:
        return _popTracks;
      case MusicStyle.metal:
        return _metalTracks;
      case MusicStyle.nostalgia:
        return _nostalgiaTracks;
      case MusicStyle.electronic:
        return _electronicTracks;
    }
  }

  /// 根据风格、乐器索引(0-3)、片段索引(0-4) 返回完整 asset 路径
  static String assetPath(MusicStyle style, int instrumentIndex, int patternIndex) {
    final name = tracksFor(style)[instrumentIndex][patternIndex];
    return '${style.assetFolder}/$name.mp3';
  }
}
