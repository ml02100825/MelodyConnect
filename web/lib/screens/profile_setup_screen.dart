import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/profile_api_service.dart';
import '../services/token_storage_service.dart';
import 'home_screen.dart';

/// プロフィール設定画面（ステップ2: ユーザー名とアイコン設定）
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _userUuidController = TextEditingController();
  final _profileApiService = ProfileApiService();
  final _tokenStorage = TokenStorageService();
  final ImagePicker _imagePicker = ImagePicker();

  bool _isLoading = false;
  bool _isUploading = false;
  XFile? _selectedImageFile;
  Uint8List? _imageBytes;
  String? _uploadedImageUrl;

  @override
  void dispose() {
    _usernameController.dispose();
    _userUuidController.dispose();
    super.dispose();
  }

  /// ユーザー名のバリデーション
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'ユーザー名を入力してください';
    }

    if (value.length < 3) {
      return 'ユーザー名は3文字以上である必要があります';
    }

    if (value.length > 20) {
      return 'ユーザー名は20文字以下である必要があります';
    }

    return null;
  }

  /// ユーザーIDのバリデーション
  String? _validateUserUuid(String? value) {
    if (value == null || value.isEmpty) {
      return 'ユーザーIDを入力してください';
    }

    if (value.length < 4) {
      return 'ユーザーIDは4文字以上である必要があります';
    }

    if (value.length > 36) {
      return 'ユーザーIDは36文字以下である必要があります';
    }

    // 英数字とアンダースコア、ハイフンのみ許可
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(value)) {
      return 'ユーザーIDは英数字、_、-のみ使用できます';
    }

    return null;
  }

  /// 画像を選択
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
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

        // すぐにアップロード
        await _uploadImage();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画像の選択に失敗しました: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 画像をアップロード
  Future<void> _uploadImage() async {
    if (_selectedImageFile == null || _imageBytes == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8080/api/upload/image'),
      );

      // Web環境ではバイト配列から直接アップロード
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          _imageBytes!,
          filename: _selectedImageFile!.name,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        String imageUrl = data['imageUrl'];

        // S3のURLか相対パスかを判定
        if (!imageUrl.startsWith('http://') && !imageUrl.startsWith('https://')) {
          // 相対パスの場合、絶対URLに変換
          imageUrl = 'http://localhost:8080$imageUrl';
        }

        setState(() {
          _uploadedImageUrl = imageUrl;
          _isUploading = false;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('画像をアップロードしました'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'アップロードに失敗しました');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _selectedImageFile = null;
        _imageBytes = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('画像のアップロードに失敗しました: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// プロフィール更新処理
  Future<void> _handleProfileUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_uploadedImageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('アイコン画像を選択してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 保存されている認証情報を取得
      final userId = await _tokenStorage.getUserId();
      final accessToken = await _tokenStorage.getAccessToken();

      if (userId == null || accessToken == null) {
        throw Exception('認証情報が見つかりません');
      }

      // プロフィール更新API呼び出し
      final response = await _profileApiService.updateProfile(
        userId: userId,
        username: _usernameController.text.trim(),
        userUuid: _userUuidController.text.trim(),
        imageUrl: _uploadedImageUrl!,
        accessToken: accessToken,
      );

      // ユーザー名を保存
      await _tokenStorage.saveUsername(response['username']);

      if (!mounted) return;

      // 成功メッセージを表示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('プロフィールを設定しました'),
          backgroundColor: Colors.green,
        ),
      );

      // ホーム画面へ遷移
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // レスポンシブ対応: 画面幅に応じて最大幅を設定
    final screenWidth = MediaQuery.of(context).size.width;
    final maxWidth = screenWidth > 600 ? 500.0 : double.infinity;
    final padding = screenWidth > 600 ? 48.0 : 24.0;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // タイトル
                  const Text(
                    'プロフィール設定',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ユーザー名、ユーザーID、アイコンを設定してください',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // ユーザー名入力
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'ユーザー名',
                      hintText: '3〜20文字で入力',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateUsername,
                    enabled: !_isLoading && !_isUploading,
                  ),
                  const SizedBox(height: 24),

                  // ユーザーID入力
                  TextFormField(
                    controller: _userUuidController,
                    decoration: const InputDecoration(
                      labelText: 'ユーザーID（フレンド申請用）',
                      hintText: '4〜36文字で入力（英数字、_、-）',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    validator: _validateUserUuid,
                    enabled: !_isLoading && !_isUploading,
                  ),
                  const SizedBox(height: 32),

                  // アイコン画像選択
                  const Text(
                    'アイコン画像',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 画像プレビューまたは選択ボタン
                  Center(
                    child: GestureDetector(
                      onTap: _isLoading || _isUploading ? null : _pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _uploadedImageUrl != null
                                ? Colors.blue
                                : Colors.grey,
                            width: 3,
                          ),
                        ),
                        child: _isUploading
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : _imageBytes != null
                                ? ClipOval(
                                    child: Image.memory(
                                      _imageBytes!,
                                      fit: BoxFit.cover,
                                      width: 150,
                                      height: 150,
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_a_photo,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        '画像を選択',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'タップして画像を選択（最大5MB）',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // 設定完了ボタン
                  ElevatedButton(
                    onPressed: (_isLoading || _isUploading)
                        ? null
                        : _handleProfileUpdate,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            '設定完了',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
