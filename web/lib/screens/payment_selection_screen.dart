// payment_selection_screen.dart
import 'package:flutter/material.dart';
import 'payment_management_screen.dart'; // PaymentMethodManagerをインポート
import 'plan_confirmation_screen.dart'; // PlanConfirmationScreenをインポート

class PaymentSelectionScreen extends StatefulWidget {
  final Map<String, dynamic>? selectedPlan;
  final String? title;
  final String? buttonText;
  final Function(Map<String, dynamic>)? onPaymentSelected;
  
  const PaymentSelectionScreen({
    Key? key,
    this.selectedPlan,
    this.title,
    this.buttonText,
    this.onPaymentSelected,
  }) : super(key: key);

  @override
  State<PaymentSelectionScreen> createState() => _PaymentSelectionScreenState();
}

class _PaymentSelectionScreenState extends State<PaymentSelectionScreen> {
  int _selectedPaymentIndex = 0;
  List<Map<String, dynamic>> _paymentMethods = [];

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  void _loadPaymentMethods() {
    setState(() {
      _paymentMethods = PaymentMethodManager.paymentMethods;
    });
  }

  void _handleContinue() {
    if (_paymentMethods.isEmpty) return;
    
    final selectedMethod = _paymentMethods[_selectedPaymentIndex];
    
    // コールバックがある場合はコールバックを実行
    if (widget.onPaymentSelected != null) {
      widget.onPaymentSelected!(selectedMethod);
      return;
    }
    
    // プランがある場合はプラン確認画面へ
    if (widget.selectedPlan != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlanConfirmationScreen(
            selectedPlan: widget.selectedPlan!,
            selectedPaymentMethod: selectedMethod,
          ),
        ),
      );
    } else {
      // プランがない場合は前の画面に戻る
      Navigator.pop(context, selectedMethod);
    }
  }

  void _navigateToAddPayment() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPaymentMethodScreen(
          // selectedPlanパラメータを削除
        ),
      ),
    );
    
    if (result == true) {
      _loadPaymentMethods();
    }
  }

  void _navigateToEditPayment(int index) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPaymentMethodScreen(
          paymentMethod: _paymentMethods[index],
          index: index,
          // selectedPlanパラメータを削除
        ),
      ),
    );
    
    if (result == true) {
      _loadPaymentMethods();
    }
  }

  String _getTitle() {
    return widget.title ?? 'お支払い方法を選択';
  }

  String _getButtonText() {
    if (widget.buttonText != null) return widget.buttonText!;
    if (widget.selectedPlan != null) return '購入する - ¥${widget.selectedPlan!['price']}';
    return '続ける';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _getTitle(),
          style: const TextStyle(color: Colors.black),
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
                  // 選択中のプランがある場合のみ表示
                  if (widget.selectedPlan != null)
                    _buildSelectedPlanCard(),
                  if (widget.selectedPlan != null)
                    const SizedBox(height: 24),
                  
                  const Text(
                    'お支払い方法を選択してください',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (_paymentMethods.isEmpty)
                    _buildEmptyState()
                  else
                    _buildPaymentMethodsList(),
                ],
              ),
            ),
          ),
          
          if (_paymentMethods.isNotEmpty)
            _buildContinueButton(),
        ],
      ),
    );
  }

  Widget _buildSelectedPlanCard() {
    if (widget.selectedPlan == null) return const SizedBox.shrink();
    
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
                  'ConnectPlus ${widget.selectedPlan!['period']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '¥${widget.selectedPlan!['price']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(
            Icons.credit_card,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '登録された支払い方法がありません',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToAddPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'お支払い方法を追加',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsList() {
    return Column(
      children: List.generate(_paymentMethods.length, (index) {
        final method = _paymentMethods[index];
        final isSelected = _selectedPaymentIndex == index;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedPaymentIndex = index;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.blueAccent : Colors.grey[300]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blueAccent : Colors.grey,
                      width: 2,
                    ),
                    color: isSelected ? Colors.blueAccent : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: method['color']?.withOpacity(0.1) ?? Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    method['icon'] ?? Icons.credit_card,
                    color: method['color'] ?? Colors.blueAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method['brand'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '•••• ${method['last4']}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                IconButton(
                  onPressed: () => _navigateToEditPayment(index),
                  icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _handleContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            _getButtonText(),
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