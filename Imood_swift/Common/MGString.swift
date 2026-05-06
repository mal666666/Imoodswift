//
//  MGString.swift
//  Imood_swift
//
//  Created by Mac on 2020/6/15.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation

//时分秒
extension String{
    static func customTimeWithSecond(sec: Float) -> String{
        guard sec > 0 else {
            return "00:00"
        }
        let h = Int(sec/3600)
        let m = Int(sec.truncatingRemainder(dividingBy: 3600)/60)
        let s = Int(sec.truncatingRemainder(dividingBy: 60))
        if h>0 {
            return String.init(format: "%.2d:%.2d:%.2d",h,m,s)
        }
        return String.init(format: "%.2d:%.2d",m,s)
    }
}

enum L10n {
    private static let values: [String: [String: String]] = [
        "common_notice": [
            "zh-Hans": "提示", "zh-Hant": "提示", "en": "Notice", "ja": "お知らせ",
            "ko": "안내", "fr": "Information", "de": "Hinweis", "es": "Aviso"
        ],
        "common_cancel": [
            "zh-Hans": "取消", "zh-Hant": "取消", "en": "Cancel", "ja": "キャンセル",
            "ko": "취소", "fr": "Annuler", "de": "Abbrechen", "es": "Cancelar"
        ],
        "style_pop": [
            "zh-Hans": "流行", "zh-Hant": "流行", "en": "Pop", "ja": "ポップ",
            "ko": "팝", "fr": "Pop", "de": "Pop", "es": "Pop"
        ],
        "style_metal": [
            "zh-Hans": "金属", "zh-Hant": "金屬", "en": "Metal", "ja": "メタル",
            "ko": "메탈", "fr": "Metal", "de": "Metal", "es": "Metal"
        ],
        "style_nostalgia": [
            "zh-Hans": "思念", "zh-Hant": "思念", "en": "Nostalgia", "ja": "ノスタルジア",
            "ko": "노스탤지어", "fr": "Nostalgie", "de": "Nostalgie", "es": "Nostalgia"
        ],
        "style_electronic": [
            "zh-Hans": "电子", "zh-Hant": "電子", "en": "Electronic", "ja": "エレクトロ",
            "ko": "일렉트로닉", "fr": "Electronique", "de": "Elektronisch", "es": "Electronica"
        ],
        "home_pick_style_message": [
            "zh-Hans": "请选择音乐风格", "zh-Hant": "請選擇音樂風格", "en": "Please choose a music style",
            "ja": "音楽スタイルを選択してください", "ko": "음악 스타일을 선택하세요", "fr": "Veuillez choisir un style musical",
            "de": "Bitte waehlen Sie einen Musikstil", "es": "Elige un estilo musical"
        ],
        "home_loading_composing": [
            "zh-Hans": "正在合成视频...", "zh-Hant": "正在合成影片...", "en": "Composing video...",
            "ja": "動画を合成中...", "ko": "동영상 합성 중...", "fr": "Composition de la video...",
            "de": "Video wird zusammengesetzt...", "es": "Componiendo video..."
        ],
        "home_toast_add_photos": [
            "zh-Hans": "请添加照片", "zh-Hant": "請新增照片", "en": "Please add photos",
            "ja": "写真を追加してください", "ko": "사진을 추가해 주세요", "fr": "Ajoutez des photos",
            "de": "Bitte Fotos hinzufuegen", "es": "Agrega fotos"
        ],
        "home_toast_compose_failed_retry": [
            "zh-Hans": "合成失败，请重试", "zh-Hant": "合成失敗，請重試", "en": "Composition failed. Please try again.",
            "ja": "合成に失敗しました。もう一度お試しください。", "ko": "합성에 실패했습니다. 다시 시도해 주세요.",
            "fr": "Echec de la composition. Reessayez.", "de": "Zusammenfuegen fehlgeschlagen. Bitte erneut versuchen.",
            "es": "La composicion fallo. Intentalo de nuevo."
        ],
        "home_export": [
            "zh-Hans": "导出", "zh-Hant": "匯出", "en": "Export", "ja": "書き出し",
            "ko": "내보내기", "fr": "Exporter", "de": "Exportieren", "es": "Exportar"
        ],
        "home_toast_export_success": [
            "zh-Hans": "导出成功", "zh-Hant": "匯出成功", "en": "Export successful",
            "ja": "書き出しが完了しました", "ko": "내보내기 성공", "fr": "Export reussi",
            "de": "Export erfolgreich", "es": "Exportacion exitosa"
        ],
        "composer_toast_select_segments": [
            "zh-Hans": "请先选择音乐片段", "zh-Hant": "請先選擇音樂片段", "en": "Please select music clips first",
            "ja": "先に音楽クリップを選択してください", "ko": "먼저 음악 클립을 선택해 주세요", "fr": "Selectionnez d'abord des extraits musicaux",
            "de": "Bitte zuerst Musikclips auswaehlen", "es": "Selecciona primero clips de musica"
        ],
        "composer_toast_cancelled": [
            "zh-Hans": "音乐取消", "zh-Hant": "音樂已取消", "en": "Music canceled", "ja": "音楽をキャンセルしました",
            "ko": "음악이 취소되었습니다", "fr": "Musique annulee", "de": "Musik abgebrochen", "es": "Musica cancelada"
        ],
        "composer_toast_saved": [
            "zh-Hans": "音乐保存", "zh-Hant": "音樂已儲存", "en": "Music saved", "ja": "音楽を保存しました",
            "ko": "음악이 저장되었습니다", "fr": "Musique enregistree", "de": "Musik gespeichert", "es": "Musica guardada"
        ],
        "composer_toast_recorder_init_failed": [
            "zh-Hans": "录音初始化失败", "zh-Hant": "錄音初始化失敗", "en": "Recorder initialization failed",
            "ja": "録音の初期化に失敗しました", "ko": "녹음 초기화에 실패했습니다", "fr": "Echec d'initialisation de l'enregistreur",
            "de": "Recorder-Initialisierung fehlgeschlagen", "es": "Fallo al inicializar la grabadora"
        ],
        "instrument_drum": [
            "zh-Hans": "鼓组", "zh-Hant": "鼓組", "en": "DRUM", "ja": "ドラム",
            "ko": "드럼", "fr": "BATTERIE", "de": "DRUMS", "es": "BATERIA"
        ],
        "instrument_bass": [
            "zh-Hans": "贝斯", "zh-Hant": "貝斯", "en": "BASS", "ja": "ベース",
            "ko": "베이스", "fr": "BASSE", "de": "BASS", "es": "BAJO"
        ],
        "instrument_guitar": [
            "zh-Hans": "吉他", "zh-Hant": "吉他", "en": "GUITAR", "ja": "ギター",
            "ko": "기타", "fr": "GUITARE", "de": "GITARRE", "es": "GUITARRA"
        ],
        "instrument_midi": [
            "zh-Hans": "MIDI", "zh-Hant": "MIDI", "en": "MIDI", "ja": "MIDI",
            "ko": "MIDI", "fr": "MIDI", "de": "MIDI", "es": "MIDI"
        ]
    ]
    
    static func t(_ key: String) -> String {
        let language = currentLanguageCode()
        return values[key]?[language] ?? values[key]?["en"] ?? key
    }
    
    private static func currentLanguageCode() -> String {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? "en"
        
        if preferred.hasPrefix("zh-hans") || preferred.hasPrefix("zh-cn") || preferred.hasPrefix("zh-sg") {
            return "zh-Hans"
        }
        if preferred.hasPrefix("zh-hant") || preferred.hasPrefix("zh-tw") || preferred.hasPrefix("zh-hk") || preferred.hasPrefix("zh-mo") {
            return "zh-Hant"
        }
        if preferred.hasPrefix("ja") { return "ja" }
        if preferred.hasPrefix("ko") { return "ko" }
        if preferred.hasPrefix("fr") { return "fr" }
        if preferred.hasPrefix("de") { return "de" }
        if preferred.hasPrefix("es") { return "es" }
        return "en"
    }
}
