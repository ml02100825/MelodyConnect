# 管理画面ダミーデータ置換計画

## 概要
各管理画面のダミーデータをAPIから取得した実際の値に置き換え、DTOと整合を取る。

---

## 1. music_admin2.dart（楽曲詳細画面）

### 変更内容
| 行 | 変更 | 理由 |
|----|------|------|
| 114 | `_detailRow('名称', ...)` を削除 | 「名称」削除の指示 |
| 120 | `_detailRow('ジャンル', ...)` を削除 | AdminSongResponseにジャンル情報なし |
| 122 | `_detailRow('ジャンルID', ...)` を削除 | genreId不要の指示 |
| 133-136 | 右列の「楽曲」「アーティスト01」を削除 | ダミー表示 |
| 34-38 | 削除機能にAPI呼び出しを追加 | 論理削除の実装 |

### 削除後の表示項目（AdminSongResponseに準拠）
- ID (songId)
- アーティストID (artistId)
- geniusソングID (geniusSongId)
- 追加日時 (createdAt)
- 状態 (isActive)

### 削除機能の実装
```dart
onDelete: () async {
  await AdminApiService.disableSongs([int.parse(widget.music['id'])]);
  Navigator.pop(context);
  Navigator.pop(context, true);
}
```

---

## 2. artist_detail_admin.dart（アーティスト詳細画面）

### 変更内容
| 対象 | 変更 |
|------|------|
| genreIdController | 削除 |
| _originalGenreId | 削除 |
| ジャンルID表示行 | 削除 |
| genreOptions | getGenres() APIから取得 |

### 削除対象（genreId関連）
- 行32: `genreIdController` 宣言
- 行39: `_originalGenreId` 宣言
- 行67,74-75: 初期化処理
- 行247-248: ジャンルID表示行
- 行475,500-501,523-524,530-533,690,705-706: 各種参照

### ジャンルプルダウンのAPI連携
```dart
List<String> genreOptions = [];

Future<void> _loadGenres() async {
  final response = await AdminApiService.getGenres(size: 100);
  final genres = (response['genres'] as List<dynamic>? ?? [])
      .map((g) => g['name'] as String).toList();
  setState(() => genreOptions = genres);
}
```

---

## 3. artist_admin.dart（アーティスト一覧画面）

### 変更内容
| 対象 | 変更 |
|------|------|
| ArtistクラスのgenreId | 削除（行15-18, 47, 64, 78） |
| genreOptions配列（行115-120） | getGenres() APIから取得 |
| ジャンルフィルター（行399） | API取得値を使用 |

### ダミー配列の削除
```dart
// 削除対象
final List<String> genreOptions = [
  'ジャンル01', 'ジャンル02', 'ジャンル03', 'ジャンル04',
];
```

---

## 4. music_admin.dart（楽曲一覧画面）

### 変更内容
| 行 | 変更 |
|----|------|
| 227 | ジャンルダミー `['ジャンル1', 'ジャンル2']` → getGenres() APIから取得 |

### 実装
```dart
List<String> _genreOptions = [];

Future<void> _loadGenres() async {
  final response = await AdminApiService.getGenres(size: 100);
  final genres = (response['genres'] as List<dynamic>? ?? [])
      .map((g) => g['name'] as String).toList();
  setState(() => _genreOptions = genres);
}
```

---

## 5. mondai_admin.dart（問題一覧画面）

### 変更内容
| 行 | 項目 | 変更 |
|----|------|------|
| 259 | 問題形式 | 一覧APIのquestionFormatからユニーク値を抽出 |
| 275 | 難易度 | 一覧APIのdifficultyLevelからユニーク値を抽出 |
| 291 | 状態 | 変更不要（isActiveベース） |

### 実装方針
```dart
Set<String> _questionFormats = {'問題形式'};
Set<String> _difficultyLevels = {'難易度'};

// _loadFromApi内で一覧取得後にユニーク値を抽出
final formats = content.map((q) => _formatQuestionFormat(q['questionFormat']))
    .where((f) => f.isNotEmpty).toSet();
final levels = content.map((q) => q['difficultyLevel']?.toString() ?? '')
    .where((l) => l.isNotEmpty).toSet();
setState(() {
  _questionFormats = {'問題形式', ...formats};
  _difficultyLevels = {'難易度', ...levels};
});
```

**Note**: difficultyLevelはAPIから数値で返却されるため、そのまま文字列として表示

---

## 6. badge_admin.dart（バッジ一覧画面）

### 変更内容
| 行 | 項目 | 変更 |
|----|------|------|
| 288 | モード | 一覧APIのmodeから抽出 |
| 304 | 状態 | 変更不要（isActiveベース） |

### 実装方針
```dart
Set<String> _modeOptions = {'モード'};

// _loadFromApi内で一覧取得後に抽出
final modes = loadedBadges.map((b) => b.mode).where((m) => m.isNotEmpty).toSet();
setState(() {
  _modeOptions = {'モード', ...modes};
});
```

---

## 7. vocabulary_admin.dart（単語一覧画面）

### 変更内容
- **変更不要**: 状態フィルター `['すべて', '有効', '無効']` はisActiveベースで正しい

---

## 修正対象ファイル一覧

| ファイル | 主な変更 |
|----------|----------|
| [music_admin2.dart](web/lib/admin/music_admin2.dart) | 名称・ジャンル・genreId削除、削除API実装 |
| [artist_detail_admin.dart](web/lib/admin/artist_detail_admin.dart) | genreId削除、ジャンルAPI連携 |
| [artist_admin.dart](web/lib/admin/artist_admin.dart) | genreId削除、ジャンルAPI連携 |
| [music_admin.dart](web/lib/admin/music_admin.dart) | ジャンルAPI連携 |
| [mondai_admin.dart](web/lib/admin/mondai_admin.dart) | 問題形式・難易度を一覧から抽出 |
| [badge_admin.dart](web/lib/admin/badge_admin.dart) | モードを一覧から抽出 |

---

## 検証方法

1. **各画面の表示確認**
   - music_admin2.dart: 名称・ジャンル・genreIDが表示されないこと
   - artist_detail_admin.dart: genreIDが表示されないこと
   - 各画面のプルダウンがAPIから取得した値のみ表示されること

2. **削除機能の確認**
   - music_admin2.dartで楽曲削除 → 論理削除（isActive=false）されること

3. **フィルター動作確認**
   - 各プルダウンで選択した値でフィルタリングが正常に動作すること
