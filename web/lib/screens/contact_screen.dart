import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_webapp/config/app_config.dart';
import '../services/contact_api_service.dart';
import '../services/token_storage_service.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  String get _baseUrl => AppConfig.apiBaseUrl;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  final ContactApiService _apiService = ContactApiService();
  
  bool _isLoading = false;
  XFile? _selectedImage;
  String? _uploadedImageUrl; // サーバーにアップロード後のURL

  // 画像を選択する
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  // 画像をサーバーにアップロードする処理
  Future<String?> _uploadImage(XFile image) async {
    try {
      final token = await TokenStorageService().getAccessToken();
      final uri = Uri.parse('$_baseUrl/api/upload/image');
      
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      // Web対応
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'file', 
          bytes, 
          filename: image.name
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file', 
          image.path
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['imageUrl'];
      } else {
        throw Exception('画像のアップロードに失敗: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl;

      // 1. 画像が選択されていれば先にアップロード
      if (_selectedImage != null) {
        finalImageUrl = await _uploadImage(_selectedImage!);
        if (finalImageUrl == null) {
          throw Exception('画像のアップロードに失敗しました。再試行してください。');
        }
      }

      // 2. お問い合わせ内容を送信 (画像のURLを含む)
      await _apiService.submitContact(
        title: _titleController.text,
        detail: _detailController.text,
        imageUrl: finalImageUrl,
      );

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('お問い合わせを送信しました'), backgroundColor: Colors.green),
      );
      
      Navigator.pop(context);
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('お問い合わせ'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '不具合の報告やご意見・ご要望はこちらからお送りください。',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 24),
              
              // タイトル入力
              const Text('タイトル', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: '例: ログインできない、機能の要望など',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (value) => value!.isEmpty ? 'タイトルを入力してください' : null,
              ),
              const SizedBox(height: 24),

              // 詳細入力
              const Text('お問い合わせ内容', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '詳細をご記入ください',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? '内容を入力してください' : null,
              ),
              const SizedBox(height: 24),

              // ▼▼▼ ここが復活した「写真送信枠」です ▼▼▼
              const Text('スクリーンショット（任意）', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[100],
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb 
                              ? Image.network(_selectedImage!.path, fit: BoxFit.cover)
                              : Image.file(File(_selectedImage!.path), fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, color: Colors.grey, size: 40),
                            SizedBox(height: 8),
                            Text('タップして画像を選択', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                ),
              ),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextButton(
                    onPressed: () => setState(() => _selectedImage = null),
                    child: const Text('画像を削除', style: TextStyle(color: Colors.red)),
                  ),
                ),
              // ▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲▲

              const SizedBox(height: 32),

              // 送信ボタン
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          '送信する',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
