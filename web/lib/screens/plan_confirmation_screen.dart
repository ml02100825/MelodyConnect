// plan_confirmation_screen.dart
import 'package:flutter/material.dart';

class PlanConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> selectedPlan;
  final Map<String, dynamic> selectedPaymentMethod;
  
  const PlanConfirmationScreen({
    Key? key,
    required this.selectedPlan,
    required this.selectedPaymentMethod,
  }) : super(key: key);

  @override
  State<PlanConfirmationScreen> createState() => _PlanConfirmationScreenState();
}

class _PlanConfirmationScreenState extends State<PlanConfirmationScreen> {
  bool _isLoading = false;

  Future<void> _confirmPurchase() async {
    setState(() {
      _isLoading = true;
    });

    // 擬似的な購入処理
    await Future.delayed(const Duration(milliseconds: 2000));

    setState(() {
      _isLoading = false;
    });

    // 購入完了メッセージ
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.selectedPlan['period']}プランを購入しました'),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    // 購入完了後、適切な画面に戻る
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '購入確認',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 選択中のプラン
                  _buildSelectedPlanCard(),
                  const SizedBox(height: 16),
                  
                  // 選択中の支払い方法
                  _buildSelectedPaymentCard(),
                  const SizedBox(height: 24),
                  
                  // 合計金額
                  _buildTotalAmount(),
                ],
              ),
            ),
          ),
          
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildSelectedPlanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: Colors.blueAccent,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '選択中のプラン',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'ConnectPlus ${widget.selectedPlan['period']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '¥${widget.selectedPlan['price']}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPaymentCard() {
    final method = widget.selectedPaymentMethod;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: method['color']?.withOpacity(0.1) ?? Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              method['icon'] ?? Icons.credit_card,
              color: method['color'] ?? Colors.blueAccent,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'お支払い方法',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '${method['brand']} •••• ${method['last4']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAmount() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '合計金額',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '¥${widget.selectedPlan['price']}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _confirmPurchase,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  '購入を確定する - ¥${widget.selectedPlan['price']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}