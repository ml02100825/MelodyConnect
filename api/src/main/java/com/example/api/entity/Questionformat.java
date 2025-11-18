public enum QuestionFormat {
    /**
     * リスニング問題
     */
    LISTENING("listening"),
    
    /**
     * 虫食い問題（穴埋め問題）
     */
    FILL_IN_THE_BLANK("fill_in_the_blank");

    private final String value;

    QuestionFormat(String value) {
        this.value = value;
    }

    public String getValue() {
        return value;
    }

    public static QuestionFormat fromValue(String value) {
        for (QuestionFormat format : QuestionFormat.values()) {
            if (format.value.equalsIgnoreCase(value)) {
                return format;
            }
        }
        throw new IllegalArgumentException("Unknown Question format: " + value);
    }
}