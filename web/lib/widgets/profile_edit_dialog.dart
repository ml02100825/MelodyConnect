import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../services/profile_api_service.dart';
import '../services/token_storage_service.dart';
import '../services/s3_image_upload_service.dart';
import 'package:image_picker/image_picker.dart';
/// ========================================
/// プロフィール編集ダイアログ
/// ========================================
/// SettingsScreenのプロフィールカードから表示されます。
/// ユーザー名、ユーザーID（フレンド申請用）、アイコンURLを
/// 編集できます。
/// ========================================
class ProfileEditDialog extends StatefulWidget {
  /// 現在のユーザー名
  final String currentUsername;
  /// 現在のユーザーID（フレンド申請用）
  final String currentUserUuid;
  /// 現在のアイコンURL
  final String? currentImageUrl;

  const ProfileEditDialog({
    Key? key,
    required this.currentUsername,
    required this.currentUserUuid,
    this.currentImageUrl,
  }) : super(key: key);

  @override
  State<ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<ProfileEditDialog> {
  final _profileApiService = ProfileApiService();
  final _tokenStorage = TokenStorageService();
  final _formKey = GlobalKey<FormState>();
  Uint8List? _imageBytes;
  String? _uploadedImageUrl;
  XFile? _selectedImageFile;

  // ========================================
  // フォーム入力用コントローラー
  // ========================================
  late TextEditingController _usernameController;
  late TextEditingController _userUuidController;
  late TextEditingController _imageUrlController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // 現在の値でコントローラーを初期化
    _usernameController = TextEditingController(text: widget.currentUsername);
    _userUuidController = TextEditingController(text: widget.currentUserUuid);
    _imageUrlController = TextEditingController(text: widget.currentImageUrl ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _userUuidController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  /// ========================================
  /// 画像を選択
  /// ========================================
  /// ImagePickerを使用してギャラリーから画像を選択します。
  /// ========================================
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageFile = pickedFile;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画像の選択に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ========================================
  /// プロフィールを更新
  /// ========================================
  /// ProfileApiServiceを使用してバックエンドに
  /// プロフィール更新リクエストを送信します。
  /// 画像がある場合は先にS3にアップロードします。
  /// ========================================
  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = await _tokenStorage.getUserId();
      final accessToken = await _tokenStorage.getAccessToken();

      if (userId == null || accessToken == null) {
        throw Exception('認証情報が見つかりません');
      }

      String? imageUrl = widget.currentImageUrl; // 既存のURLを保持

      // 画像が選択されている場合は先にS3にアップロード
      if (_imageBytes != null && _selectedImageFile != null) {
        imageUrl = await S3ImageUploadService().uploadImage(
          imageBytes: _imageBytes!,
          filename: _selectedImageFile!.name,
        );
      }

      // プロフィール更新API呼び出し（JSONリクエスト）
      await _profileApiService.updateProfile(
        userId: userId,
        username: _usernameController.text.trim(),
        userUuid: _userUuidController.text.trim(),
        imageUrl: imageUrl,
        accessToken: accessToken,
      );

      // TokenStorageのユーザー名も更新
      await _tokenStorage.saveUsername(_usernameController.text.trim());

      if (mounted) {
        Navigator.of(context).pop(true); // 成功を返す
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('更新に失敗しました: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========================================
              // タイトル
              // ========================================
              const Text(
                'プロフィール編集',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '各項目を編集して保存してください',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // ========================================
              // アイコン画像選択
              // ========================================
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _isSubmitting ? null : _pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _imageBytes != null ? Colors.blue : Colors.grey,
                            width: 3,
                          ),
                        ),
                        child: _imageBytes != null
                            ? ClipOval(
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover,
                                  width: 150,
                                  height: 150,
                                ),
                              )
                            : (widget.currentImageUrl != null && widget.currentImageUrl!.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      widget.currentImageUrl!,
                                      fit: BoxFit.cover,
                                      width: 150,
                                      height: 150,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text('画像を選択', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                          ],
                                        );
                                      },
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('画像を選択', style: TextStyle(color: Colors.grey, fontSize: 14)),
                                    ],
                                  )),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'タップして画像を選択（最大5MB）',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ========================================
              // ユーザー名入力フィールド
              // ========================================
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'ユーザー名',
                  hintText: '3〜20文字で入力',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  helperText: '他のユーザーに表示される名前です',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'ユーザー名を入力してください';
                  }
                  if (value.trim().length < 3) {
                    return 'ユーザー名は3文字以上で入力してください';
                  }
                  if (value.trim().length > 20) {
                    return 'ユーザー名は20文字以下で入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ========================================
              // ユーザーID入力フィールド（フレンド申請用）
              // ========================================
              TextFormField(
                controller: _userUuidController,
                decoration: InputDecoration(
                  labelText: 'ユーザーID',
                  hintText: '4〜36文字で入力（英数字）',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  helperText: 'フレンド申請で使用する一意のIDです',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'ユーザーIDを入力してください';
                  }
                  if (value.trim().length < 4) {
                    return 'ユーザーIDは4文字以上で入力してください';
                  }
                  if (value.trim().length > 36) {
                    return 'ユーザーIDは36文字以下で入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // ========================================
              // ボタン
              // ========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('キャンセル'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitProfile,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('保存'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
