import 'package:flutter/material.dart';
import '../bottom_nav.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _currentLanguage = '日本語';
  String _selectedLanguage = '日本語';
  bool _showConfirm = false;

  final List<String> _languages = ['日本語', 'English', '한국어', '中文'];

  void _onChangeLanguage(String? value) {
    if (value != null) setState(() => _selectedLanguage = value);
  }

  void _showChangeConfirm() {
    if (_selectedLanguage == _currentLanguage) return;
    setState(() => _showConfirm = true);
  }

  void _applyLanguageChange() {
    setState(() {
      _currentLanguage = _selectedLanguage;
      _showConfirm = false;
    });
    // 実運用ではここでローカライズ切替処理
  }

  void _cancelChange() {
    setState(() => _showConfirm = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('言語設定', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, thickness: 1),
                  const SizedBox(height: 32),
                  Text('現在の言語：$_currentLanguage', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('変更後の言語', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 16),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedLanguage,
                            items: _languages.map((lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang),
                            )).toList(),
                            onChanged: _onChangeLanguage,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: _showChangeConfirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: const BorderSide(color: Colors.black, width: 2),
                          ),
                          elevation: 4,
                        ),
                        child: const Text('変更', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          if (_showConfirm)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.redAccent, width: 4)),
                      child: const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text('表示言語を「$_selectedLanguage」に変更します。\nよろしいですか？', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _applyLanguageChange,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: const BorderSide(color: Colors.black, width: 2),
                          ),
                          elevation: 4,
                        ),
                        child: const Text('変更', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _cancelChange,
                      child: const Text('キャンセル', style: TextStyle(color: Colors.blueAccent)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 4,
        onTap: (index) {},
      ),
    );
  }
}