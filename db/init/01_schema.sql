CREATE TABLE IF NOT EXISTS samples (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  message VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO samples(message) VALUES ('hello db');

-- クレジットカード情報（表示用）保存テーブル
CREATE TABLE IF NOT EXISTS user_payment_methods (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT NOT NULL,
  brand VARCHAR(50) NOT NULL,
  last4 VARCHAR(10) NOT NULL,
  expiry VARCHAR(10) NOT NULL,
  holder_name VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- user_id で検索を速くするためのインデックス（任意ですが推奨）
CREATE INDEX idx_payment_user_id ON user_payment_methods(user_id);