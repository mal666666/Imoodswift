import 'dart:ui';

/// 简易国际化。L10n.t('key') 根据系统语言返回文案。
/// 对应 iOS MGString.swift 里的 L10n enum。
class L10n {
  /// 静态常量 Map：key → { 语言码 → 文案 }
  static const _values = <String, Map<String, String>>{
    'common_notice': {'zh-Hans': '提示', 'zh-Hant': '提示', 'en': 'Notice'},
    'common_cancel': {'zh-Hans': '取消', 'zh-Hant': '取消', 'en': 'Cancel'},
    'style_pop': {'zh-Hans': '流行', 'zh-Hant': '流行', 'en': 'Pop'},
    'style_metal': {'zh-Hans': '金属', 'zh-Hant': '金屬', 'en': 'Metal'},
    'style_nostalgia': {'zh-Hans': '思念', 'zh-Hant': '思念', 'en': 'Nostalgia'},
    'style_electronic': {'zh-Hans': '电子', 'zh-Hant': '電子', 'en': 'Electronic'},
    'home_pick_style_message': {
      'zh-Hans': '请选择音乐风格',
      'zh-Hant': '請選擇音樂風格',
      'en': 'Please choose a music style',
    },
    'home_loading_composing': {
      'zh-Hans': '正在合成视频...',
      'zh-Hant': '正在合成影片...',
      'en': 'Composing video...',
    },
    'home_loading_preparing_photos': {
      'zh-Hans': '正在处理照片...',
      'zh-Hant': '正在處理照片...',
      'en': 'Preparing photos...',
    },
    'home_toast_add_photos': {
      'zh-Hans': '请添加照片',
      'zh-Hant': '請新增照片',
      'en': 'Please add photos',
    },
    'home_toast_compose_failed_retry': {
      'zh-Hans': '合成失败，请重试',
      'zh-Hant': '合成失敗，請重試',
      'en': 'Composition failed. Please try again.',
    },
    'home_export': {'zh-Hans': '导出', 'zh-Hant': '匯出', 'en': 'Export'},
    'home_toast_export_success': {
      'zh-Hans': '导出成功',
      'zh-Hant': '匯出成功',
      'en': 'Export successful',
    },
    'composer_toast_select_segments': {
      'zh-Hans': '请先选择音乐片段',
      'zh-Hant': '請先選擇音樂片段',
      'en': 'Please select music clips first',
    },
    'composer_toast_cancelled': {
      'zh-Hans': '音乐取消',
      'zh-Hant': '音樂已取消',
      'en': 'Music canceled',
    },
    'composer_toast_saved': {
      'zh-Hans': '音乐保存',
      'zh-Hant': '音樂已儲存',
      'en': 'Music saved',
    },
    'composer_toast_save_failed': {
      'zh-Hans': '音乐保存失败',
      'zh-Hant': '音樂儲存失敗',
      'en': 'Failed to save music',
    },
    'composer_toast_recorder_init_failed': {
      'zh-Hans': '录音初始化失败',
      'zh-Hant': '錄音初始化失敗',
      'en': 'Recorder initialization failed',
    },
    'instrument_drum': {'zh-Hans': '鼓组', 'zh-Hant': '鼓組', 'en': 'DRUM'},
    'instrument_bass': {'zh-Hans': '贝斯', 'zh-Hant': '貝斯', 'en': 'BASS'},
    'instrument_guitar': {'zh-Hans': '吉他', 'zh-Hant': '吉他', 'en': 'GUITAR'},
    'instrument_midi': {'zh-Hans': 'MIDI', 'zh-Hant': 'MIDI', 'en': 'MIDI'},
  };

  static String t(String key) {
    final language = _currentLanguageCode();
    // ?? 空合并：左边 null 则用右边
    return _values[key]?[language] ?? _values[key]?['en'] ?? key;
  }

  static String _currentLanguageCode() {
    final locale = PlatformDispatcher.instance.locale;
    final language = locale.languageCode.toLowerCase();
    final script = locale.scriptCode?.toLowerCase();

    if (language == 'zh') {
      if (script == 'hant' ||
          locale.countryCode?.toUpperCase() == 'TW' ||
          locale.countryCode?.toUpperCase() == 'HK') {
        return 'zh-Hant';
      }
      return 'zh-Hans';
    }
    return 'en';
  }
}
