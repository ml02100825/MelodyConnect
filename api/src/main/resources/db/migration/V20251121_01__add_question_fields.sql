-- Add new columns to question table
-- complete_sentence: 完全な文（穴埋め問題で空欄が埋まった状態）
-- skill_focus: 学習焦点 (vocabulary, grammar, collocation, idiom等)
-- translation_ja: 和訳
-- audio_url: 音声URL (S3想定)
-- is_active: 有効フラグ
-- is_deleted: 削除フラグ

ALTER TABLE question
ADD COLUMN complete_sentence VARCHAR(200) COMMENT '完全な文（穴埋め問題用）',
ADD COLUMN skill_focus VARCHAR(50) COMMENT '学習焦点',
ADD COLUMN translation_ja VARCHAR(500) COMMENT '和訳',
ADD COLUMN audio_url VARCHAR(500) COMMENT '音声URL (S3)',
ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT TRUE COMMENT '有効フラグ',
ADD COLUMN is_deleted BOOLEAN NOT NULL DEFAULT FALSE COMMENT '削除フラグ';
