import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PrivacySettingsScreen extends StatefulWidget {
  final int userId;
  
  const PrivacySettingsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isPublic = true; // デフォルト公開
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/v1/privacy/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _isPublic = data['is_account_public'] ?? true;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('設定読み込みエラー: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updatePrivacy(bool isPublic) async {
    final privacyValue = isPublic ? 0 : 1;
    
    try {
      final response = await http.put(
        Uri.parse('http://localhost:8080/api/v1/privacy/${widget.userId}?privacy=$privacyValue'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _isPublic = isPublic);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('更新に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('プライバシー設定'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'アカウント公開設定',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '「公開」にすると、他のユーザーにオンライン状態とバッジが表示されます。\n'
                      '「非公開」にすると、オンラインでもオフライン状態として表示され、バッジも非表示になります。',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('アカウントを公開する'),
                      subtitle: _isPublic 
                          ? const Text('オンライン表示: ON, バッジ表示: ON')
                          : const Text('オンライン表示: OFF, バッジ表示: OFF'),
                      value: _isPublic,
                      onChanged: (value) => _updatePrivacy(value),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '現在の設定状態',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildStatusItem('オンライン表示', _isPublic),
                    _buildStatusItem('バッジ表示', _isPublic),
                    _buildStatusItem('プロフィール公開', _isPublic),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isEnabled ? Colors.green[100] : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isEnabled ? 'ON' : 'OFF',
              style: TextStyle(
                color: isEnabled ? Colors.green[800] : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}