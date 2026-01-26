import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // 追加
import '../bottom_nav.dart';
import '../services/token_storage_service.dart'; // 追加
import 'payment_management_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _tokenStorage = TokenStorageService();
  
  bool isSubscribed = false;
  bool _isLoading = true;
  List<dynamic> _paymentMethods = [];
  Map<String, dynamic>? _selectedPaymentMethod;

  // APIのベースURL
  static const String baseUrl = 'http://localhost:8080/api/payments';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // 初期データ読み込み（サブスク状態 & カード情報）
  Future<void> _initData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _checkSubscriptionStatus(),
      _loadPaymentMethods(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  // サブスク状態の確認
  Future<void> _checkSubscriptionStatus() async {
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/subscription-status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            isSubscribed = data['isSubscribed'] ?? false;
          });
        }
      }
    } catch (e) {
      debugPrint('Status check error: $e');
    }
  }

  // カード情報の取得
  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await PaymentApiService.getPaymentMethods();
      if (mounted) {
        setState(() {
          _paymentMethods = methods;
          if (_paymentMethods.isNotEmpty && _selectedPaymentMethod == null) {
            _selectedPaymentMethod = _paymentMethods.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Payment load error: $e');
    }
  }

  // サブスク登録処理
  Future<void> _subscribe() async {
    try {
      setState(() => _isLoading = true);
      final token = await _tokenStorage.getAccessToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/subscribe'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await _checkSubscriptionStatus(); // 状態更新
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('ConnectPlusに登録しました！'), backgroundColor: Colors.blue),
          );
        }
      } else {
        final error = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(error['error'] ?? '登録に失敗しました');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 解約処理
  Future<void> _unsubscribe() async {
    try {
      setState(() => _isLoading = true);
      final token = await _tokenStorage.getAccessToken();
      
      final response = await http.post(
        Uri.parse('$baseUrl/unsubscribe'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        await _checkSubscriptionStatus(); // 状態更新
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('解約しました'), backgroundColor: Colors.orange),
          );
        }
      }
    } catch (e) {
      debugPrint('Unsubscribe error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  bool get _hasPaymentMethod => _paymentMethods.isNotEmpty;
  Map<String, dynamic>? get _primaryPaymentMethod => _selectedPaymentMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ConnectPlus',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ヘッダー部分
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSubscribed ? Colors.amber[50] : Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.workspace_premium,
                      size: 80,
                      color: isSubscribed ? Colors.amber[700] : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'ConnectPlus',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!isSubscribed)
                    const Text(
                      '¥500/月',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 登録済みの場合の表示
            if (isSubscribed) ...[
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
                        'あなたはサブスクに登録中です',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 登録情報カード
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '登録情報',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('プラン', 'ConnectPlus 月間プラン'),
                    const Divider(height: 24),
                    _buildInfoRow('金額', '¥500/月'),
                    // お支払い方法の表示（適宜APIから取得したものを表示）
                    if (_primaryPaymentMethod != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        'お支払い方法',
                        '${_primaryPaymentMethod!['brand']} •••• ${_primaryPaymentMethod!['last4']}',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 特典内容
            const Text(
              '特典内容',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildBenefitItem('ライフの上限が5から10に増加', Icons.favorite),
            _buildBenefitItem('ライフ回復アイテム付与', Icons.card_giftcard),
            _buildBenefitItem('単語帳の全権閲覧可能', Icons.menu_book),
            _buildBenefitItem('単語帳の並び替え機能解放', Icons.sort),
            const SizedBox(height: 40),

            // ボタン
            if (!isSubscribed) ...[
              // 登録済みカード情報表示
              if (_hasPaymentMethod && _primaryPaymentMethod != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.credit_card, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_primaryPaymentMethod!['brand']} •••• ${_primaryPaymentMethod!['last4']}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _showPaymentMethodSelector(),
                        child: const Text('変更', style: TextStyle(color: Colors.blue)),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleSubscribeAction(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    _hasPaymentMethod ? '¥500/月で登録する' : '支払い方法を登録して購入',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _showCancelDialog(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'サブスクリプションを解約',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {},
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.end,
          ),
        ),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.blue, size: 24),
        ],
      ),
    );
  }

  void _handleSubscribeAction() async {
    if (_hasPaymentMethod) {
      _showSubscribeDialog();
    } else {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const AddPaymentMethodScreen()),
      );
      if (result == true) {
        await _loadPaymentMethods();
        if (mounted && _paymentMethods.isNotEmpty) {
          setState(() {
            _selectedPaymentMethod = _paymentMethods.last;
          });
          _showSubscribeDialog();
        }
      }
    }
  }
  
  void _showPaymentMethodSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('支払い方法を選択', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ..._paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod != null && _selectedPaymentMethod!['id'] == method['id'];
              return ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.blue),
                title: Text('${method['brand']} •••• ${method['last4']}'),
                trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blue) : null,
                onTap: () {
                  setState(() {
                    _selectedPaymentMethod = method;
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 8),
            Divider(color: Colors.grey[300]),
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
              title: const Text('新しい支払い方法を追加', style: TextStyle(color: Colors.blue)),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPaymentMethodScreen()),
                );
                if (result == true) {
                  await _loadPaymentMethods();
                  if (mounted && _paymentMethods.isNotEmpty) {
                    setState(() {
                      _selectedPaymentMethod = _paymentMethods.last;
                    });
                  }
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSubscribeDialog() {
    final pm = _primaryPaymentMethod;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('購入確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ConnectPlusを¥500/月で購入しますか?'),
            const SizedBox(height: 12),
            if (pm != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.credit_card, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${pm['brand']} •••• ${pm['last4']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _subscribe(); // API呼び出し
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('購入する'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('解約確認'),
        content: const Text(
          'ConnectPlusを解約しますか?\n\n解約すると特典が利用できなくなります。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _unsubscribe(); // API呼び出し
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('解約する'),
          ),
        ],
      ),
    );
  }
}