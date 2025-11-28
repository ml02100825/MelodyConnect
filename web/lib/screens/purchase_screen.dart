import 'package:flutter/material.dart';
import 'payment_selection_screen.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({Key? key}) : super(key: key);

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  // 単一のプラン情報
  final Map<String, dynamic> _plan = {
    'period': '1ヶ月',
    'price': 500,
    'monthlyEquivalent': 500,
    'name': 'ConnectPlus'
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '購入する',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // プラン概要カード
            _buildPlanCard(),
            const SizedBox(height: 24),
            
            // 機能比較テーブル
            _buildFeatureComparison(),
          ],
        ),
      ),
      bottomNavigationBar: _buildPurchaseButton(),
    );
  }

  Widget _buildPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ConnectPlus',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 16),
          _buildBenefitItem('ライフの上限アップ'),
          _buildBenefitItem('ライフ回復アイテム'),
          _buildBenefitItem('単語帳が全権閲覧可'),
          _buildBenefitItem('単語帳の並び替え機能解放'),
          const SizedBox(height: 16),
          Text(
            '¥${_plan['price']}/月',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureComparison() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          // ヘッダー
          _buildComparisonRow(
            '',
            'Free',
            'Plus',
            isHeader: true,
          ),
          const Divider(height: 1),
          
          // ライフの数
          _buildComparisonRow(
            'ライフの数',
            '5',
            '10',
          ),
          const Divider(height: 1),
          
          // ライフ回復アイテム
          _buildComparisonRow(
            'ライフ回復アイテム',
            '×',
            '10個/月',
          ),
          const Divider(height: 1),
          
          // 単語帳の機能
          _buildComparisonRow(
            '単語帳の機能',
            '一部制限',
            '無制限',
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, String freeValue, String plusValue, {bool isHeader = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                fontSize: isHeader ? 16 : 14,
                color: isHeader ? Colors.black : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              freeValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                fontSize: isHeader ? 16 : 14,
                color: isHeader ? Colors.black : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              plusValue,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                fontSize: isHeader ? 16 : 14,
                color: isHeader ? Colors.blueAccent : Colors.blueAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            // 支払い方法選択画面に遷移（プラン情報を渡す）
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentSelectionScreen(
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            '購入する - ¥${_plan['price']}',
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