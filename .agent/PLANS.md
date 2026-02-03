- 目的
  最近編集したファイルの文字化けを解消し、UTF-8で再保存する
- 変更対象（ファイル/モジュール）
  web/lib/services/artist_api_service.dart
  web/lib/widgets/unified_selection_dialog.dart
  web/lib/screens/like_artist_edit_screen.dart
  api/src/main/java/com/example/api/dto/LikeArtistRequest.java
  api/src/main/java/com/example/api/service/ArtistService.java
- 手順（チェックリスト）
  - 対象ファイルをUTF-8で再保存する
  - 文字化けが解消されたことを確認する
- 受け入れ条件
  直近で編集したファイルの文字化けが解消される
- リスク/代替案
  - リスク: 文字コード以外の要因（フォント/IDE設定）で見た目が改善しない可能性
  - 代替案: IDEの文字コード設定やフォントを確認する
