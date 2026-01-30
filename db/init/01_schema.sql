-- 既存のテーブル定義があればそれを修正、なければ以下を使用
CREATE TABLE IF NOT EXISTS users (
    user_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(20) NOT NULL,
    mailaddress VARCHAR(30) NOT NULL,
    password VARCHAR(255) NOT NULL,
    total_play INT NOT NULL DEFAULT 0,
    image_url VARCHAR(200),
    language INT NOT NULL DEFAULT 0,
    privacy INT DEFAULT 0,
    
    -- ▼▼▼ 修正箇所 ▼▼▼
    subscribe_flag INT NOT NULL DEFAULT 0,    -- 0:未契約, 1:契約中(利用可能)
    cancellation_flag INT NOT NULL DEFAULT 0, -- 0:未解約, 1:解約済み
    -- ▲▲▲▲▲▲▲▲▲▲▲▲▲▲
    
    accepted_at TIMESTAMP,
    life INT NOT NULL DEFAULT 5,
    life_last_recovered_at TIMESTAMP,
    delete_flag BOOLEAN NOT NULL DEFAULT FALSE,
    expires_at TIMESTAMP,
    canceled_at TIMESTAMP,
    offline_at TIMESTAMP,
    user_uuid VARCHAR(20),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ban_flag BOOLEAN NOT NULL DEFAULT FALSE,
    initial_setup_completed BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_mailaddress ON users(mailaddress);
CREATE INDEX idx_users_user_uuid ON users(user_uuid);

-- お問い合わせテーブル (前回作成したもの)
CREATE TABLE IF NOT EXISTS contacts (
  contact_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(100) NOT NULL,
  contact_detail TEXT NOT NULL,
  image_url VARCHAR(255),
  user_id BIGINT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(user_id)
);
CREATE INDEX idx_contacts_user_id ON contacts(user_id);