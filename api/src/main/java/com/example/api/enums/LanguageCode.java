package com.example.api.enums;

/**
 * 音楽の言語コード
 * ISO 639-1に準拠した言語コードと表示名を定義
 */
public enum LanguageCode {
    JAPANESE("ja", "日本語"),
    KOREAN("ko", "韓国語"),
    ENGLISH("en", "英語"),
    CHINESE("zh", "中国語"),
    SPANISH("es", "スペイン語"),
    FRENCH("fr", "フランス語"),
    GERMAN("de", "ドイツ語"),
    PORTUGUESE("pt", "ポルトガル語"),
    ITALIAN("it", "イタリア語"),
    RUSSIAN("ru", "ロシア語"),
    UNKNOWN("unknown", "不明");

    private final String code;
    private final String displayName;

    LanguageCode(String code, String displayName) {
        this.code = code;
        this.displayName = displayName;
    }

    public String getCode() {
        return code;
    }

    public String getDisplayName() {
        return displayName;
    }

    /**
     * コードから言語を取得
     *
     * @param code 言語コード（例: "ja", "ko", "en"）
     * @return 対応するLanguageCode、見つからない場合はUNKNOWN
     */
    public static LanguageCode fromCode(String code) {
        if (code == null || code.isEmpty()) {
            return UNKNOWN;
        }

        for (LanguageCode lang : values()) {
            if (lang.code.equalsIgnoreCase(code)) {
                return lang;
            }
        }

        return UNKNOWN;
    }

    /**
     * 言語が有効かどうかを判定
     *
     * @return UNKNOWNでない場合true
     */
    public boolean isValid() {
        return this != UNKNOWN;
    }

    @Override
    public String toString() {
        return displayName + " (" + code + ")";
    }
}
