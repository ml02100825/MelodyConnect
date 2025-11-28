import 'package:flutter/material.dart';
import 'user_list_admin.dart';
inport 'vocabulary_admin.dart';
import'contact_list_admin.dart';

class BottomAdminLayout extends StatelessWidget {
  final Widget mainContent;
  final String selectedMenu;
  final Function(String)? onMenuSelected; // オプションに変更
  final String? selectedTab;
  final Function(String?)? onTabSelected;
  final bool showTabs;

  const BottomAdminLayout({
    Key? key,
    required this.mainContent,
    required this.selectedMenu,
    this.onMenuSelected, // 必須からオプションに
    this.selectedTab,
    this.onTabSelected,
    this.showTabs = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー（固定）
              _buildHeader(),
              const SizedBox(height: 32),
             
              // タブメニュー（コンテンツ管理の場合のみ表示・固定）
              if (showTabs) ...[
                _buildTabMenu(context),
                const SizedBox(height: 24),
              ],
             
              // メインコンテンツエリア
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // サイドバー（固定）
                    _buildSidebar(context),
                    const SizedBox(width: 32),
                   
                    // メインコンテンツ（スクロール可能）
                    Expanded(
                      child: mainContent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ヘッダー部分（固定）
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Melody',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'cursive',
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Connect',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: Colors.grey[300]),
      ],
    );
  }

  // タブメニュー（コンテンツ管理の場合のみ表示・固定）
  Widget _buildTabMenu(BuildContext context) {
    final tabs = ['単語', '問題', '楽曲', 'アーティスト', 'ジャンル', 'バッジ'];
   
    return Row(
      children: tabs.map((tab) {
        final isSelected = selectedTab == tab;
        return GestureDetector(
          onTap: () {
            onTabSelected?.call(tab);
            _navigateToTabContent(context, tab);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? Colors.lightBlue : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              tab,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.lightBlue : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // サイドバーメニュー（固定）
  Widget _buildSidebar(BuildContext context) {
    final menuItems = ['ユーザー管理', 'コンテンツ管理', 'お問い合わせ管理'];

    return SizedBox(
      width: 192,
      child: Column(
        children: menuItems.map((item) {
          final isSelected = selectedMenu == item;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  onMenuSelected?.call(item); // オプショナル呼び出し
                  _navigateToMenuContent(context, item);
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected ? Colors.lightBlue : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.lightBlue : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // サイドバーメニュー遷移処理
  void _navigateToMenuContent(BuildContext context, String menu) {
    switch (menu) {
      case 'ユーザー管理':
        // 既にユーザー管理画面の場合は何もしない
        if (selectedMenu != 'ユーザー管理') {
          // UserListAdmin画面へ遷移
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => UserListAdmin()));
        }
        break;
      case 'コンテンツ管理':
        // コンテンツ管理画面へ遷移（最初のタブを表示）
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VocabularyAdmin(initialTab: '単語')));
        break;
      case 'お問い合わせ管理':
        // お問い合わせ管理画面へ遷移
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ContactListAdmin()));
        break;
    }
  }

  // タブメニュー遷移処理
  void _navigateToTabContent(BuildContext context, String tab) {
    // コンテンツ管理内でのタブ切り替え処理
    // 実際のアプリでは、状態管理を使って同じ画面内でコンテンツを切り替える
    switch (tab) {
      case '単語':
        // 単語管理コンテンツを表示
        break;
      case '問題':
        // 問題管理コンテンツを表示
        break;
      case '楽曲':
        // 楽曲管理コンテンツを表示
        break;
      case 'アーティスト':
        // アーティスト管理コンテンツを表示
        break;
      case 'ジャンル':
        // ジャンル管理コンテンツを表示
        break;
      case 'バッジ':
        // バッジ管理コンテンツを表示
        break;
    }
  }
}