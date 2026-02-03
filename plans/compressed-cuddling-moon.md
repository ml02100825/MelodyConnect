# 実装計画: プライバシーフィルター・パスワードリセット確認・メールアドレス表示

## 概要
3つの独立した機能を実装:
1. ルームマッチのフレンド招待でprivacy=2のユーザーをオフライン表示
2. パスワードリセット前に確認ダイアログを表示
3. メールアドレス変更画面で現在のメールアドレスを表示

---

## Feature 1: プライバシーフィルター (Backend)

### ファイル
- [RoomController.java](api/src/main/java/com/example/api/controller/RoomController.java)

### 変更内容
`getFriends()` メソッド (line 297-322) のループ内で、`getUserStatus()` を呼ぶ前にプライバシーチェックを追加:

```java
// line 308-314 を以下に変更
// プライバシー設定チェック: privacy=2（非公開）の場合は強制オフライン
String status;
boolean canInvite;
if (friendUser.getPrivacy() != null && friendUser.getPrivacy() == 2) {
    status = "offline";
    canInvite = false;
} else {
    status = getUserStatus(friendUserId);
    canInvite = canInviteUser(friendUserId, f);
}
friendInfo.put("status", status);
friendInfo.put("canInvite", canInvite);
```

### 動作
- privacy=2のフレンドは実際のオンライン状態に関わらず「オフライン」として表示
- 招待ボタンも非表示（canInvite=false）

---

## Feature 2: パスワードリセット確認ダイアログ (Frontend)

### ファイル
- [other_screen.dart](web/lib/screens/other_screen.dart)

### 変更内容
`パスワードリセット` ListTile の `onTap` (line 284-299) を確認ダイアログでラップ:

```dart
onTap: () async {
  final email = await _tokenStorage.getEmail();
  if (!mounted) return;
  if (email == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('認証情報が見つかりません')),
    );
    return;
  }
  // 確認ダイアログを表示
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('確認'),
      content: const Text('パスワードをリセットしますか？\n登録されているメールアドレスにリセット用コードを送信します。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('キャンセル'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PasswordResetScreen(initialEmail: email),
              ),
            );
          },
          child: const Text('リセットする'),
        ),
      ],
    ),
  );
},
```

### 参考パターン
同ファイル内のログアウト確認 (line 321-338) と同じパターン

---

## Feature 3: 現在のメールアドレス表示 (Frontend)

### ファイル
- [email_change_screen.dart](web/lib/screens/email_change_screen.dart)

### 変更内容

**1. 状態変数追加 (line 22付近):**
```dart
bool _isEmailSent = false;
String? _currentEmail;  // 追加
```

**2. initState追加:**
```dart
@override
void initState() {
  super.initState();
  _loadCurrentEmail();
}

Future<void> _loadCurrentEmail() async {
  final email = await _tokenStorage.getEmail();
  if (mounted) {
    setState(() => _currentEmail = email);
  }
}
```

**3. `_buildConfirmView()` を修正 (line 91-96):**
```dart
const SizedBox(height: 16),
// 現在のメールアドレスを表示
if (_currentEmail != null) ...[
  Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mail_outline, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            _currentEmail!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  ),
  const SizedBox(height: 16),
],
const Text(
  '上記のメールアドレスに\n変更用のコードを送信します。',
  textAlign: TextAlign.center,
  style: TextStyle(fontSize: 16),
),
```

---

## 検証方法

### Feature 1
1. テストユーザーのprivacyを2に設定
2. そのユーザーをフレンドに持つユーザーでログイン
3. ルームマッチでフレンド招待画面を開く
4. privacy=2のユーザーがオフライン表示されることを確認
5. 招待ボタンが表示されないことを確認

### Feature 2
1. その他画面を開く
2. パスワードリセットをタップ
3. 確認ダイアログが表示されることを確認
4. キャンセルでダイアログが閉じることを確認
5. リセットするでPasswordResetScreenに遷移することを確認

### Feature 3
1. メールアドレス変更画面を開く
2. 現在のメールアドレスがボックス内に表示されることを確認
3. 説明文が「上記のメールアドレスに〜」に変わっていることを確認
