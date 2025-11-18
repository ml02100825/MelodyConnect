import 'package:flutter/material.dart';

/// ユーザ検索画面（モック準拠のシンプル実装）
class UserSearchScreen extends StatefulWidget {
	const UserSearchScreen({Key? key}) : super(key: key);

	@override
	State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
	final TextEditingController _controller = TextEditingController();
	String _query = '';

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	void _onSearchChanged() {
		setState(() {
			_query = _controller.text.trim();
		});
	}

	@override
	void initState() {
		super.initState();
		_controller.addListener(_onSearchChanged);
	}

	@override
	Widget build(BuildContext context) {
		final isWide = MediaQuery.of(context).size.width > 600;

		return Scaffold(
			appBar: AppBar(
				title: const Text('ユーザ検索'),
				centerTitle: true,
			),
			body: SingleChildScrollView(
				padding: EdgeInsets.all(isWide ? 24 : 16),
				child: ConstrainedBox(
					constraints: BoxConstraints(maxWidth: isWide ? 800 : double.infinity),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							const SizedBox(height: 8),

							// 検索入力
							Container(
								decoration: BoxDecoration(
									borderRadius: BorderRadius.circular(24),
									border: Border.all(color: Colors.grey.shade400),
								),
								padding: const EdgeInsets.symmetric(horizontal: 12),
								child: Row(
									children: [
										const Icon(Icons.search, color: Colors.grey),
										const SizedBox(width: 8),
										Expanded(
											child: TextField(
												controller: _controller,
												decoration: const InputDecoration(
													hintText: 'IDを入力',
													border: InputBorder.none,
												),
												textInputAction: TextInputAction.search,
												onSubmitted: (_) {},
											),
										),
									],
								),
							),

							const SizedBox(height: 20),

							// 検索結果
							if (_query.isEmpty)
								const SizedBox()
							else
								_buildResults(),
						],
					),
				),
			),
		);
	}

	Widget _buildResults() {
		// 簡易的なスタブ検索: ID が `100001` の場合のみダミーユーザを返す
		if (_query == '100001') {
			return Column(
				children: [
					_userCard(
						avatarUrl: null,
						name: 'アフガニスタン斎藤',
						lastLogin: '最終ログイン 2時間前',
					),
				],
			);
		}

		return Padding(
			padding: const EdgeInsets.only(top: 8.0),
			child: Container(
				alignment: Alignment.centerLeft,
				child: const Text(
					'ユーザが見つかりません',
					style: TextStyle(color: Colors.grey),
				),
			),
		);
	}

	Widget _userCard({String? avatarUrl, required String name, required String lastLogin}) {
		return Container(
			margin: const EdgeInsets.symmetric(vertical: 8),
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
			decoration: BoxDecoration(
				borderRadius: BorderRadius.circular(12),
				border: Border.all(color: Colors.grey.shade300),
				color: Colors.white,
			),
			child: Row(
				children: [
					// アイコン
					CircleAvatar(
						radius: 24,
						backgroundColor: Colors.blue.shade50,
						child: const Icon(Icons.person, color: Colors.purple),
					),
					const SizedBox(width: 12),

					// ユーザ情報
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									name,
									style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
								),
								const SizedBox(height: 4),
								Text(
									lastLogin,
									style: const TextStyle(fontSize: 12, color: Colors.grey),
								),
							],
						),
					),

					// 追加ボタン
					SizedBox(
						width: 40,
						height: 40,
						child: OutlinedButton(
							style: OutlinedButton.styleFrom(
								shape: const CircleBorder(),
								padding: EdgeInsets.zero,
								side: BorderSide(color: Colors.grey.shade400),
							),
							onPressed: () {
								// TODO: フレンド追加の API を呼ぶ
								ScaffoldMessenger.of(context).showSnackBar(
									SnackBar(content: Text('「$name」をフレンドに追加しました（スタブ）')),
								);
							},
							child: const Icon(Icons.add),
						),
					),
				],
			),
		);
	}
}

