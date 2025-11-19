import 'package:flutter/material.dart';
import '../bottom_nav.dart';

// 簡単なローカライズクラス
class AppLocalizations {
  static final Map<String, Map<String, String>> _localizedValues = {
    '日本語': {
      'language_settings': '言語設定',
      'current_language': '現在の言語',
      'change_language': '変更後の言語',
      'change': '変更',
      'confirm_message': '表示言語を「%s」に変更します。\nよろしいですか？',
      'cancel': 'キャンセル',
    },
    'English': {
      'language_settings': 'Language Settings',
      'current_language': 'Current Language',
      'change_language': 'Language to Change',
      'change': 'Change',
      'confirm_message': 'Change display language to "%s".\nAre you sure?',
      'cancel': 'Cancel',
    },
    '한국어': {
      'language_settings': '언어 설정',
      'current_language': '현재 언어',
      'change_language': '변경할 언어',
      'change': '변경',
      'confirm_message': '표시 언어를 "%s"(으)로 변경합니다.\n계속하시겠습니까?',
      'cancel': '취소',
    },
    '中文': {
      'language_settings': '语言设置',
      'current_language': '当前语言',
      'change_language': '要更改的语言',
      'change': '更改',
      'confirm_message': '将显示语言更改为"%s"。\n确定吗？',
      'cancel': '取消',
    },
  };

  final String currentLanguage;

  AppLocalizations(this.currentLanguage);

  String get languageSettings => _localizedValues[currentLanguage]!['language_settings']!;
  String get currentLanguageText => _localizedValues[currentLanguage]!['current_language']!;
  String get changeLanguage => _localizedValues[currentLanguage]!['change_language']!;
  String get change => _localizedValues[currentLanguage]!['change']!;
  String get cancel => _localizedValues[currentLanguage]!['cancel']!;

  String confirmMessage(String language) => 
      _localizedValues[currentLanguage]!['confirm_message']!.replaceFirst('%s', language);
}

// 言語設定を管理するシンプルな状態管理クラス
class LanguageManager {
  static String currentLanguage = '日本語';
  
  static void changeLanguage(String newLanguage) {
    currentLanguage = newLanguage;
  }
}

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = LanguageManager.currentLanguage;
  bool _showConfirm = false;

  final List<String> _languages = ['日本語', 'English', '한국어', '中文'];

  void _onChangeLanguage(String? value) {
    if (value != null) {
      setState(() {
        _selectedLanguage = value;
      });
    }
  }

  void _showChangeConfirm() {
    if (_selectedLanguage == LanguageManager.currentLanguage) return;
    setState(() => _showConfirm = true);
  }

  void _applyLanguageChange() {
    setState(() {
      LanguageManager.changeLanguage(_selectedLanguage);
      _showConfirm = false;
    });
    
    // 画面全体を更新するために新しいインスタンスを作成
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LanguageSettingsScreen()),
    );
  }

  void _cancelChange() {
    setState(() => _showConfirm = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations(LanguageManager.currentLanguage);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(l10n.languageSettings, style: const TextStyle(color: Colors.black)),
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
                  Text('${l10n.currentLanguageText}：${LanguageManager.currentLanguage}', style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 32),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(l10n.changeLanguage, style: const TextStyle(fontSize: 18)),
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
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 4,
                        ),
                        child: Text(l10n.change, style: const TextStyle(fontSize: 16, color: Colors.white)),
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
                    Text(l10n.confirmMessage(_selectedLanguage), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _applyLanguageChange,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: const BorderSide(color: Colors.black, width: 2),
                          ),
                          elevation: 4,
                        ),
                        child: Text(l10n.change, style: const TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _cancelChange,
                      child: Text(l10n.cancel, style: const TextStyle(color: Colors.blueAccent)),
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