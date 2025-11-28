import 'package:flutter/material.dart';

// 1. サブスク登録・解約画面
class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  bool _hasSubscription = false; // サブスク登録状態

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'サブスク登録・解約',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 現在のステータス表示
            _buildStatusCard(),
            const SizedBox(height: 24),
            
            // アクションボタン
            if (!_hasSubscription) _buildSubscribeButton(),
            if (_hasSubscription) _buildUnsubscribeButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _hasSubscription ? 'サブスク登録中' : 'サブスク未登録',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _hasSubscription ? Colors.green : Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasSubscription 
                ? 'ConnectPlusプランに加入しています'
                : '現在サブスクリプションに加入していません',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribeButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // 支払い情報登録画面へ遷移
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PaymentRegistrationScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'サブスク登録',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildUnsubscribeButton() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _showUnsubscribeConfirm,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.redAccent),
            ),
            child: const Text(
              'サブスク解約',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // プラン選択画面へ遷移（プラン変更用）
              
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'プラン変更',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showUnsubscribeConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サブスク解約'),
        content: const Text('本当にサブスクリプションを解約しますか？\n解約後はプレミアム機能が利用できなくなります。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performUnsubscribe();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('解約する'),
          ),
        ],
      ),
    );
  }

  void _performUnsubscribe() {
    // 解約処理（スタブ）
    setState(() {
      _hasSubscription = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('サブスクリプションを解約しました')),
    );
  }
}

// 2. 支払い情報登録画面
class PaymentRegistrationScreen extends StatefulWidget {
  const PaymentRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<PaymentRegistrationScreen> createState() => _PaymentRegistrationScreenState();
}

class _PaymentRegistrationScreenState extends State<PaymentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '支払い情報登録',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // カード情報入力フォーム
              _buildCardForm(),
              const SizedBox(height: 24),
              
              // 登録ボタン
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _registerPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '支払い情報を登録',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
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
            'クレジットカード情報',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // カード番号
          TextFormField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'カード番号',
              hintText: '1234 5678 9012 3456',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'カード番号を入力してください';
              }
              if (value.replaceAll(' ', '').length != 16) {
                return '有効なカード番号を入力してください';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // 有効期限
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  decoration: const InputDecoration(
                    labelText: '有効期限',
                    hintText: 'MM/YY',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '有効期限を入力してください';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              
              // CVV
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'CVVを入力してください';
                    }
                    if (value.length != 3) {
                      return '有効なCVVを入力してください';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 名義人
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'カード名義人',
              hintText: 'TARO YAMADA',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'カード名義人を入力してください';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  void _registerPayment() {
    if (_formKey.currentState!.validate()) {
      // 支払い情報登録成功後、サブスク登録確認画面へ
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionConfirmationScreen(
            cardNumber: _cardNumberController.text,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

// 3. サブスク登録確認画面
class SubscriptionConfirmationScreen extends StatefulWidget {
  final String cardNumber;
  
  const SubscriptionConfirmationScreen({
    Key? key,
    required this.cardNumber,
  }) : super(key: key);

  @override
  State<SubscriptionConfirmationScreen> createState() => _SubscriptionConfirmationScreenState();
}

class _SubscriptionConfirmationScreenState extends State<SubscriptionConfirmationScreen> {
  int _selectedPlanIndex = 2; // デフォルトで12ヶ月プラン

  final List<Map<String, dynamic>> _plans = [
    {'period': '1ヶ月', 'price': 500, 'monthlyEquivalent': 500},
    {'period': '6ヶ月', 'price': 2700, 'monthlyEquivalent': 450},
    {'period': '12ヶ月', 'price': 4800, 'monthlyEquivalent': 400},
  ];

  void _confirmSubscription() {
    final selectedPlan = _plans[_selectedPlanIndex];
    
    // サブスク登録処理（スタブ）
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${selectedPlan['period']}プランでサブスク登録しました')),
    );
    
    // 登録完了後、設定画面に戻る
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionManagementScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlan = _plans[_selectedPlanIndex];
    final maskedCardNumber = '**** **** **** ${widget.cardNumber.substring(widget.cardNumber.length - 4)}';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'サブスク登録確認',
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
            // 登録情報サマリー
            _buildSummaryCard(maskedCardNumber),
            const SizedBox(height: 24),
            
            // プラン選択
            _buildPlanSelection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildConfirmationButton(selectedPlan),
    );
  }

  Widget _buildSummaryCard(String maskedCardNumber) {
    return Container(
      width: double.infinity,
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('プラン', 'ConnectPlus'),
          _buildInfoRow('支払い方法', 'クレジットカード'),
          _buildInfoRow('カード番号', maskedCardNumber),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'プランを選択',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Column(
          children: List.generate(_plans.length, (index) {
            final plan = _plans[index];
            final isSelected = _selectedPlanIndex == index;
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPlanIndex = index;
                });
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blueAccent.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? Colors.blueAccent : Colors.grey[300]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plan['period'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.blueAccent : Colors.black87,
                          ),
                        ),
                        Text(
                          '¥${plan['monthlyEquivalent']}/月相当',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '¥${plan['price']}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.blueAccent : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildConfirmationButton(Map<String, dynamic> selectedPlan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _confirmSubscription,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'サブスク登録 - ¥${selectedPlan['price']}',
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