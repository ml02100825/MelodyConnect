import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../bottom_nav.dart';
import '../services/token_storage_service.dart';
import 'payment_management_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // フラグ管理
  int subscribeFlag = 0;
  int cancellationFlag = 0;
  DateTime? expiryDate;
  bool _isLoading = true;
  
  static const String baseUrl = 'http://localhost:8080/api/payments';
  List<Map<String, dynamic>> _myCards = [];

  @override
  void initState() {
    super.initState();
    _fetchStatusFromServer();
  }

  Future<void> _fetchStatusFromServer() async {
    try {
      final tokenStorage = TokenStorageService();
      final token = await tokenStorage.getAccessToken();
      
      if (token == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/subscription-status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // ▼▼▼ 2つのフラグを取得 ▼▼▼
        final int sFlag = data['subscribeFlag'] ?? 0;
        final int cFlag = data['cancellationFlag'] ?? 0;
        final String? expiresAtStr = data['expiresAt'];

        DateTime? parsedDate;
        if (expiresAtStr != null && expiresAtStr.isNotEmpty) {
          parsedDate = DateTime.tryParse(expiresAtStr);
        }
        
        if (mounted) {
          setState(() {
            subscribeFlag = sFlag;
            cancellationFlag = cFlag;
            expiryDate = parsedDate;
            _mockRefreshCards();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _getRemainingDays() {
    if (expiryDate == null) return 0;
    final now = DateTime.now();
    final difference = expiryDate!.difference(now);
    return difference.inDays >= 0 ? difference.inDays : 0;
  }

  void _mockRefreshCards() {
    setState(() {
      if (_myCards.isEmpty) _myCards = [{'brand': 'VISA', 'last4': '1234'}];
    });
  }

  @override
  Widget build(BuildContext context) {
    // ▼▼▼ 2つのフラグで状態を判定 ▼▼▼
    
    // 契約中 (自動更新あり): Sub=1, Cancel=0
    bool isSubscribed = (subscribeFlag == 1 && cancellationFlag == 0);
    
    // 解約予約中 (期限まで有効): Sub=1, Cancel=1
    bool isCanceledButActive = (subscribeFlag == 1 && cancellationFlag == 1);
    
    // 未契約: Sub=0
    bool isUnsubscribed = (subscribeFlag == 0);

    final primaryCard = _myCards.isNotEmpty ? _myCards.first : null;
    final remainingDays = _getRemainingDays();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('ConnectPlus', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // ヘッダー表示
                  _buildHeader(!isUnsubscribed, isSubscribed, remainingDays),
                  const SizedBox(height: 32),

                  // 状態に応じたビューの切り替え
                  if (isSubscribed) 
                    _buildSubscribedView()
                  else if (isCanceledButActive)
                    _buildCanceledView(remainingDays)
                  else 
                    _buildUnsubscribedView(primaryCard),
                  
                  const SizedBox(height: 24),
                  _buildBenefitsList(),
                ],
              ),
            ),
       bottomNavigationBar: BottomNavBar(currentIndex: 0, onTap: (index) {}),
    );
  }

  Widget _buildHeader(bool isActive, bool isAutoRenewal, int days) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isActive ? Colors.amber[50] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.workspace_premium,
              size: 80,
              color: isActive ? Colors.amber[700] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          const Text('ConnectPlus', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          if (!isActive)
            const Text('¥500/月', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
          
          if (isActive) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isAutoRenewal ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isAutoRenewal ? Colors.green : Colors.orange,
                ),
              ),
              child: Text(
                isAutoRenewal 
                    ? 'あと $days 日で更新' 
                    : 'あと $days 日で終了',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isAutoRenewal ? Colors.green[800] : Colors.orange[800],
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  // 以下、_buildSubscribedView などのUIパーツは前回と同じです
  // ボタン押下時にAPIを呼び出し、完了後に _fetchStatusFromServer() を呼ぶことで画面が更新されます
  
  Widget _buildSubscribedView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.blue[700], size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'あなたはサブスクに登録中です\n(自動更新あり)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _showCancelDialog,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('解約する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Widget _buildCanceledView(int days) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '解約手続き済みです。\nあと $days 日間は特典をご利用いただけます。',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnsubscribedView(Map<String, dynamic>? primaryCard) {
    if (primaryCard != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("お支払い方法", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.credit_card, color: Colors.blueGrey, size: 30),
                const SizedBox(width: 16),
                Text('${primaryCard['brand']} •••• ${primaryCard['last4']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _goToCardManagement,
              child: const Text('カードの確認・変更はこちら', style: TextStyle(color: Colors.blue)),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showSubscribeDialog(primaryCard),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('¥500/月で登録する', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _goToCardManagement,
          icon: const Icon(Icons.add_card, color: Colors.white),
          label: const Text('支払い方法を登録して購入', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
  }

  Widget _buildBenefitsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('特典内容', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        _buildBenefitItem('ライフの上限が5から10に増加', Icons.favorite),
        _buildBenefitItem('ライフ回復アイテム付与', Icons.card_giftcard),
        _buildBenefitItem('単語帳の全権閲覧可能', Icons.menu_book),
        _buildBenefitItem('単語帳の並び替え機能解放', Icons.sort),
      ],
    );
  }

  Widget _buildBenefitItem(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(child: Text(text)),
          const Icon(Icons.check_circle, color: Colors.blue),
        ],
      ),
    );
  }

  Future<void> _goToCardManagement() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentManagementScreen()));
    _mockRefreshCards();
  }

  void _showSubscribeDialog(Map<String, dynamic> card) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('購入確認'),
        content: const Text('ConnectPlusを¥500/月で購入しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processSubscribe();
            },
            child: const Text('購入する'),
          ),
        ],
      ),
    );
  }

  Future<void> _processSubscribe() async {
    setState(() => _isLoading = true);
    try {
      final token = await TokenStorageService().getAccessToken();
      final response = await http.post(
        Uri.parse('$baseUrl/subscribe'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        await _fetchStatusFromServer();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('登録完了！'), backgroundColor: Colors.green));
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('登録に失敗しました'), backgroundColor: Colors.red));
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('解約確認'),
        content: const Text('本当に解約しますか？\n次回更新日まで特典は利用可能です。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _processUnsubscribe();
            },
            child: const Text('解約する'),
          ),
        ],
      ),
    );
  }

  Future<void> _processUnsubscribe() async {
    setState(() => _isLoading = true);
    try {
      final token = await TokenStorageService().getAccessToken();
      final response = await http.post(
        Uri.parse('$baseUrl/unsubscribe'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        await _fetchStatusFromServer();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('解約しました'), backgroundColor: Colors.orange));
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('解約に失敗しました'), backgroundColor: Colors.red));
    }
  }
}