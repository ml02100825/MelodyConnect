# Musixmatch API セットアップガイド

## 概要

MelodyConnectでは、日本語・韓国語楽曲の歌詞取得の信頼性を向上させるため、**Musixmatch API**をフォールバックとして使用しています。

## なぜMusixmatchが必要なのか？

**問題:**
- Geniusでは日本語・韓国語楽曲の歌詞がローマ字版のみの場合が多い
- ローマ字版では言語学習アプリとして機能しない

**解決策:**
- Genius（第一選択）→ Musixmatch（フォールバック）の二段階取得
- Musixmatchは日本語・韓国語のオリジナル歌詞に強い

## 動作フロー

```
1. Geniusから歌詞を取得
   ↓
2. 取得した歌詞がローマ字のみ？
   YES → Musixmatchから取得
   NO  → Geniusの歌詞を使用
   ↓
3. どちらからも取得できない場合はエラー
```

## Musixmatch APIキーの取得

### 1. アカウント登録

1. [Musixmatch Developer Portal](https://developer.musixmatch.com/) にアクセス
2. 「Sign Up」をクリックしてアカウントを作成
3. メール認証を完了

### 2. APIキーの発行

1. ダッシュボードにログイン
2. 「Applications」→「Create New Application」
3. アプリケーション情報を入力：
   - **Name**: MelodyConnect（任意）
   - **Description**: Language learning app using song lyrics
   - **Category**: Education
4. 利用規約に同意して「Create」
5. APIキーが表示されます（例: `1a2b3c4d5e6f7g8h9i0j`）

### 3. プラン

- **Free Plan**: 2,000 requests/day（開発・テスト用）
- **Commercial Plan**: より多くのリクエスト数が必要な場合

## セットアップ

### 環境変数の設定

#### 開発環境（ローカル）

`.env`ファイルを作成（またはdocker-compose.ymlで設定）：

```bash
MUSIXMATCH_API_KEY=your_musixmatch_api_key_here
```

#### Docker Compose

`docker-compose.yml`:

```yaml
services:
  api:
    environment:
      - MUSIXMATCH_API_KEY=${MUSIXMATCH_API_KEY}
```

#### 本番環境

環境変数を設定：

```bash
export MUSIXMATCH_API_KEY=your_musixmatch_api_key_here
```

または、システムの環境変数設定に追加。

## 動作確認

### ログの確認

アプリケーションを起動して、問題生成をリクエストすると、以下のようなログが表示されます：

```log
# Geniusで取得成功の場合
INFO  - Geniusから歌詞を取得しました

# Geniusで失敗→Musixmatchにフォールバックの場合
WARN  - Geniusから歌詞を取得できませんでした（ローマ字版のみの可能性）
INFO  - Musixmatchから歌詞を取得します: artist=ヨルシカ, song=だから僕は音楽を辞めた
INFO  - Musixmatchから歌詞を取得しました

# 両方失敗の場合
ERROR - どの歌詞APIからも歌詞を取得できませんでした: songName=（曲名）
```

## トラブルシューティング

### APIキーが設定されていない

```log
WARN - Musixmatch APIキーが設定されていません
```

**解決方法:** 環境変数`MUSIXMATCH_API_KEY`を設定してアプリケーションを再起動

### APIキーが無効

```log
WARN - Musixmatch API エラー: status_code=401
```

**解決方法:** APIキーが正しいか確認、または再発行

### レート制限に達した

```log
WARN - Musixmatch API エラー: status_code=402
```

**解決方法:**
- Free Planの場合: 翌日まで待つか、Commercial Planにアップグレード
- リクエスト数を確認: [Developer Portal Dashboard](https://developer.musixmatch.com/dashboard)

### 歌詞が見つからない

```log
WARN - 歌詞が見つかりませんでした: trackId=12345
```

**原因:** Musixmatchにも該当楽曲の歌詞がない
**対応:** 他の楽曲を試すか、ユーザーに手動入力機能を提供（今後の改善予定）

## API制限事項

### Musixmatch Free Plan

- **リクエスト数**: 2,000 requests/day
- **歌詞の長さ**: 30%のプレビューのみ（Full lyrics requires Commercial Plan）
- **商用利用**: 不可

### 注意点

1. **著作権**: 歌詞は著作権で保護されています。教育目的での使用に限定してください
2. **キャッシング**: 同じ歌詞を複数回リクエストしないよう、キャッシング機能の実装を推奨
3. **帰属表示**: Musixmatchの利用規約に従い、適切な帰属表示を行ってください

## 今後の改善案

### さらなる改善オプション

1. **歌詞キャッシング**
   - Redis等を使用して取得済み歌詞をキャッシュ
   - APIリクエスト数を削減

2. **追加の歌詞ソース**
   - UTATEN（日本語歌詞専門）
   - Lyrics.com
   - ユーザー手動入力オプション

3. **プレフェッチ**
   - 人気楽曲の歌詞を事前に取得
   - データベースに保存

4. **Commercial Plan移行**
   - Full lyrics access
   - より多くのリクエスト数

## 参考リンク

- [Musixmatch Developer Portal](https://developer.musixmatch.com/)
- [API Documentation](https://developer.musixmatch.com/documentation)
- [Terms of Service](https://about.musixmatch.com/terms/)
- [Pricing Plans](https://developer.musixmatch.com/plans)

## サポート

問題が解決しない場合は、以下を確認してください：

1. APIキーが正しく設定されているか
2. ログにエラーメッセージが表示されていないか
3. Musixmatch APIの制限に達していないか

それでも解決しない場合は、GitHubのIssueを作成してください。
