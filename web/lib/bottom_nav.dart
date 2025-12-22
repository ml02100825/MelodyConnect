import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/battle_mode_selection_screen.dart';
import 'screens/quiz_selection_screen.dart';
import 'screens/friend_screen.dart';
import 'screens/other_screen.dart';


class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey[400],
      currentIndex: currentIndex,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'ホーム',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.music_note),
          label: 'ミュージック',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school),
          label: '学習',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'フレンド',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu),
          label: 'メニュー',
        ),
      ],
      onTap: (index) {
        onTap(index);
        _navigateToScreen(context, index);
      },
    );
  }

  void _navigateToScreen(BuildContext context, int index) {
    late Widget screen;
    switch (index) {
      case 0:
        screen = const HomeScreen();
        break;
      case 1:
        screen = const BattleModeSelectionScreen();
        break;
      case 2:
        screen = const QuizSelectionScreen();
        break;
      case 3:
        screen = const FriendScreen();
        break;
      case 4:
        screen = const OtherScreen();
        break;
      default:
        return;
    }
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => screen),
      (route) => false,
    );
  }
}