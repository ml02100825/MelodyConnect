import 'package:flutter/material.dart';
import '../bottom_nav.dart';
import 'payment_management_screen.dart';
import 'subscription_screen.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({Key? key}) : super(key: key);

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
          'ショップ',
          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('アイテム', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const ItemDetailScreen(
                          icon: Icons.music_note,
                          label: 'ライフ回復アイテム',
                          subLabel: '×1',
                          price: '¥120',
                          itemId: 1,
                        ),
                      )),
                      child: _buildItemCard(icon: Icons.music_note, label: 'ライフ回復アイテム', subLabel: '×1', price: '¥120'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const ItemDetailScreen(
                          icon: Icons.shopping_bag,
                          label: 'ライフ回復アイテム',
                          subLabel: '×5',
                          price: '¥450',
                          itemId: 2,
                        ),
                      )),
                      child: _buildItemCard(icon: Icons.shopping_bag, label: 'ライフ回復アイテム', subLabel: '×5', price: '¥450'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const Text('定期購入', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
              const SizedBox(height: 16),
              _buildSubscriptionCard(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 0, onTap: (index) {}),
    );
  }

  Widget _buildItemCard({required IconData icon, required String label, required String subLabel, required String price}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(icon, size: 60, color: Colors.black87),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          Text(subLabel, style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey[400]!), borderRadius: BorderRadius.circular(20)),
            child: Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          const Text('ConnectPlus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('¥500/月', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                child: const Text('¥500/月', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('ライフの上限アップなど\nの特典付き！', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscriptionScreen())),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text('詳細へ', style: TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

// アイテム詳細画面
class ItemDetailScreen extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subLabel;
  final String price;
  final int itemId;

  const ItemDetailScreen({
    Key? key,
    required this.icon,
    required this.label,
    required this.subLabel,
    required this.price,
    required this.itemId,
  }) : super(key: key);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  bool get _hasPaymentMethod => PaymentMethodManager.paymentMethods.isNotEmpty;
  Map<String, dynamic>? _selectedPaymentMethod;
  
  @override
  void initState() {
    super.initState();
    _selectedPaymentMethod = _hasPaymentMethod ? PaymentMethodManager.paymentMethods.first : null;
  }
  
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
        title: const Text('アイテム詳細', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(widget.icon, size: 120, color: Colors.black87),
            const SizedBox(height: 32),
            Text(widget.label, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(widget.subLabel, style: const TextStyle(fontSize: 18, color: Colors.black54)),
            const SizedBox(height: 16),
            Text(widget.price, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('商品説明', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12),
                  Text('ライフを回復できるアイテムです。\n使用すると即座にライフが回復します。', style: TextStyle(fontSize: 15, height: 1.6, color: Colors.black87)),
                ],
              ),
            ),
            const Spacer(),
            // 登録済みカード情報表示
            if (_hasPaymentMethod)
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
                    Icon(_primaryPaymentMethod!['icon'] ?? Icons.credit_card, color: _primaryPaymentMethod!['color'] ?? Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${_primaryPaymentMethod!['brand']} •••• ${_primaryPaymentMethod!['last4']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
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
                onPressed: () => _handlePurchase(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _hasPaymentMethod ? '${widget.price}で購入' : '支払い方法を登録して購入',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _handlePurchase() async {
    if (_hasPaymentMethod) {
      _showPurchaseConfirmDialog();
    } else {
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (context) => const AddPaymentMethodScreen()),
      );
      if (result == true) {
        setState(() {
          _selectedPaymentMethod = PaymentMethodManager.paymentMethods.last;
        });
        _showPurchaseConfirmDialog();
      }
    }
  }

  void _navigateToPaymentManagement() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentManagementScreen()),
    );
    setState(() {
      // 支払い方法が削除された場合の対応
      if (_hasPaymentMethod) {
        _selectedPaymentMethod = PaymentMethodManager.paymentMethods.first;
      } else {
        _selectedPaymentMethod = null;
      }
    });
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
            ...PaymentMethodManager.paymentMethods.map((method) {
              final isSelected = _selectedPaymentMethod == method;
              return ListTile(
                leading: Icon(method['icon'] ?? Icons.credit_card, color: method['color'] ?? Colors.blue),
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
                  setState(() {
                    _selectedPaymentMethod = PaymentMethodManager.paymentMethods.last;
                  });
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showPurchaseConfirmDialog() {
    final pm = _primaryPaymentMethod;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('購入確認'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.label} ${widget.subLabel}を${widget.price}で購入しますか?'),
            const SizedBox(height: 12),
            if (pm != null)
              Text('お支払い: ${pm['brand']} •••• ${pm['last4']}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('購入が完了しました'), backgroundColor: Colors.blue),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('購入する'),
          ),
        ],
      ),
    );
  }
}
