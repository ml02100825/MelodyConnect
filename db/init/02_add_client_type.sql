ALTER TABLE sessions
  ADD COLUMN IF NOT EXISTS client_type VARCHAR(50) DEFAULT 'unknown';

CREATE INDEX IF NOT EXISTS idx_sessions_client_type ON sessions (client_type);
