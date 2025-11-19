import 'package:flutter/material.dart';
import '../bottom_nav.dart';


class BattleScreen extends StatefulWidget {
  const BattleScreen({Key? key}) : super(key: key);

	@override
	State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.music_note,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '対戦',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.person_add,
                color: Colors.black87,
                size: 20,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [],
        ),
      ),

      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          // TODO: 画面遷移処理を書く
        },
      ),
    );
  }
}
