import 'package:flutter/material.dart';
import '../bottom_nav.dart';

/// ユーザ検索・フレンド申請管理画面（統合版）
class UserSearchScreen extends StatefulWidget {
	const UserSearchScreen({Key? key}) : super(key: key);

	@override
	State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
	final TextEditingController _controller = TextEditingController();
	String _query = '';
	bool _showSubmittedBanner = false;
	final Set<String> _pendingRequests = {'100001'}; // 申請済み ID セット

	@override
	void initState() {
		super.initState();
		_controller.addListener(() {
			setState(() {
				_query = _controller.text.trim();
			});
		});
	}

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	void _sendFriendRequest(String userId, String name) {
		setState(() {
			_pendingRequests.add(userId);
			_showSubmittedBanner = true;
		});

		Future.delayed(const Duration(seconds: 2), () {
			if (mounted) {
				setState(() {
					_showSubmittedBanner = false;
				});
			}
		});
	}

	void _cancelFriendRequest(String userId, String name) {
		setState(() {
			_pendingRequests.remove(userId);
		});

		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(content: Text('「$name」の申請を取り消しました')),
		);
	}

	@override
	Widget build(BuildContext context) {
		final isWide = MediaQuery.of(context).size.width > 600;

		return Scaffold(
			appBar: AppBar(
				title: const Text('ユーザ検索'),
				centerTitle: true,
			),
			body: Stack(
				children: [
					SingleChildScrollView(
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

					// 申請しましたバナー
					if (_showSubmittedBanner)
						Positioned(
							top: 12,
							left: 0,
							right: 0,
							child: Center(
								child: Container(
									padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
									decoration: BoxDecoration(
										borderRadius: BorderRadius.circular(6),
										border: Border.all(color: Colors.grey.shade600),
										color: Colors.white,
									),
									child: const Text('申請しました'),
								),
							),
						),
				],
			),
			bottomNavigationBar: BottomNavBar(
				currentIndex: 3,
				onTap: (index) {
					// TODO: 画面遷移処理
				},
			),
		);
	}

	Widget _buildResults() {
		// スタブ: 100001 でダミーユーザを返す
		if (_query == '100001') {
			final isPending = _pendingRequests.contains('100001');
			return Column(
				children: [
					_userCard(
						userId: '100001',
						name: 'アフガニスタン斎藤',
						lastLogin: '最終ログイン  2時間前',
						isPending: isPending,
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

	Widget _userCard({
		required String userId,
		required String name,
		required String lastLogin,
		required bool isPending,
	}) {
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
					CircleAvatar(
						radius: 24,
						backgroundColor: Colors.blue.shade50,
						child: const Icon(Icons.person, color: Colors.purple),
					),
					const SizedBox(width: 12),
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
								if (isPending) {
									_cancelFriendRequest(userId, name);
								} else {
									_sendFriendRequest(userId, name);
								}
							},
							child: Icon(isPending ? Icons.close : Icons.add),
						),
					),
				],
			),
		);
	}
}

