import 'package:flutter/material.dart';


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
          icon: Icon(Icons.mail_outline),
          label: 'メール',
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
      onTap: onTap,
    );
  }
}
