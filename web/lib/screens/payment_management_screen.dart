



import 'package:flutter/material.dart';



// 支払い方法のデータを管理するクラス

class PaymentMethodManager {

  static final List<Map<String, dynamic>> _paymentMethods = [];



  static List<Map<String, dynamic>> get paymentMethods => List.from(_paymentMethods);



  static void addPaymentMethod(Map<String, dynamic> newMethod) {

    _paymentMethods.add(newMethod);

  }



  static void updatePaymentMethod(int index, Map<String, dynamic> updatedMethod) {

    _paymentMethods[index] = updatedMethod;

  }



  static void removePaymentMethod(int index) {

    _paymentMethods.removeAt(index);

  }

}



class PaymentManagementScreen extends StatefulWidget {

  const PaymentManagementScreen({Key? key}) : super(key: key);



  @override

  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();

}



class _PaymentManagementScreenState extends State<PaymentManagementScreen> {

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



  void _navigateToAddPayment() async {

    final result = await Navigator.push(

      context,

      MaterialPageRoute(builder: (context) => const AddPaymentMethodScreen()),

    );

   

    if (result == true) {

      _loadPaymentMethods();

      _showSuccessToast('お支払い方法を追加しました');

    }

  }



  void _navigateToEditPayment(int index) async {

    final result = await Navigator.push(

      context,

      MaterialPageRoute(

        builder: (context) => EditPaymentMethodScreen(

          paymentMethod: _paymentMethods[index],

          index: index,

        ),

      ),

    );

   

    if (result == true) {

      _loadPaymentMethods();

      _showSuccessToast('お支払い方法が変更されました');

    }

  }



  void _showSuccessToast(String message) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(message),

        backgroundColor: Colors.green[600],

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

        duration: const Duration(seconds: 2),

      ),

    );

  }



  void _showDeleteConfirm(int index) {

    showDialog(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text('支払い方法を削除'),

        content: const Text('この支払い方法を削除しますか？'),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(context),

            child: const Text('キャンセル',

            style: TextStyle(

              color: Colors.blue,

            ),),

          ),

          ElevatedButton(

            onPressed: () {

              Navigator.pop(context);

              _deletePaymentMethod(index);

            },

            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),

            child: const Text('削除する',

            style: TextStyle(

              color: Colors.white,

            ),),

          ),

        ],

      ),

    );

  }



  void _deletePaymentMethod(int index) {

    setState(() {

      PaymentMethodManager.removePaymentMethod(index);

      _paymentMethods = PaymentMethodManager.paymentMethods;

    });

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: const Text('支払い方法を削除しました'),

        backgroundColor: Colors.red[600],

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.grey[50],

      appBar: AppBar(

        backgroundColor: Colors.white,

        elevation: 0,

        title: const Text(

          'お支払い情報一覧',

          style: TextStyle(color: Colors.black),

        ),

        centerTitle: true,

        iconTheme: const IconThemeData(color: Colors.black),

      ),

      body: _paymentMethods.isEmpty ? _buildEmptyState() : _buildPaymentMethodsList(),

      floatingActionButton: _paymentMethods.isNotEmpty ? _buildFloatingActionButton() : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

    );

  }



  Widget _buildFloatingActionButton() {

    return Container(

      margin: const EdgeInsets.only(bottom: 16),

      child: FloatingActionButton.extended(

        onPressed: _navigateToAddPayment,

        backgroundColor: Colors.blueAccent,

        foregroundColor: Colors.white,

        elevation: 4,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        icon: const Icon(Icons.add, size: 24),

        label: const Text(

          'お支払い方法を追加',

          style: TextStyle(fontWeight: FontWeight.bold),

        ),

      ),

    );

  }



  Widget _buildEmptyState() {

    return Padding(

      padding: const EdgeInsets.all(16),

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Container(

            width: 120,

            height: 120,

            decoration: BoxDecoration(

              color: Colors.blue[50],

              shape: BoxShape.circle,

            ),

            child: const Icon(

              Icons.credit_card,

              size: 60,

              color: Colors.blueAccent,

            ),

          ),

          const SizedBox(height: 24),

          const Text(

            '支払い方法がありません',

            style: TextStyle(

              fontSize: 20,

              fontWeight: FontWeight.bold,

              color: Colors.black87,

            ),

          ),

          const SizedBox(height: 8),

          const Text(

            'お支払い方法を追加して、\nスムーズにお買い物をお楽しみください',

            textAlign: TextAlign.center,

            style: TextStyle(

              color: Colors.grey,

              fontSize: 14,

            ),

          ),

          const SizedBox(height: 32),

          _buildPrimaryAddButton(),

        ],

      ),

    );

  }



  Widget _buildPrimaryAddButton() {

    return SizedBox(

      width: double.infinity,

      child: ElevatedButton(

        onPressed: _navigateToAddPayment,

        style: ElevatedButton.styleFrom(

          backgroundColor: Colors.blueAccent,

          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(12),

          ),

          elevation: 2,

        ),

        child: const Text(

          'お支払い方法を追加',

          style: TextStyle(

            fontSize: 16,

            fontWeight: FontWeight.bold,

            color: Colors.white,

          ),

        ),

      ),

    );

  }



  Widget _buildPaymentMethodsList() {

    return Padding(

      padding: const EdgeInsets.all(16),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(

            'お支払い方法',

            style: TextStyle(

              fontSize: 18,

              fontWeight: FontWeight.bold,

              color: Colors.black87,

            ),

          ),

          const SizedBox(height: 16),

         

          Expanded(

            child: ListView.builder(

              itemCount: _paymentMethods.length,

              itemBuilder: (context, index) {

                final method = _paymentMethods[index];

                return _buildPaymentMethodCard(method, index);

              },

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildPaymentMethodCard(Map<String, dynamic> method, int index) {

    return Container(

      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.05),

            blurRadius: 8,

            offset: const Offset(0, 2),

          ),

        ],

      ),

      child: ListTile(

        leading: Container(

          width: 44,

          height: 44,

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

        title: Text(

          method['brand'],

          style: const TextStyle(

            fontWeight: FontWeight.bold,

            fontSize: 16,

          ),

        ),

        subtitle: Text(

          '•••• ${method['last4']}',

          style: const TextStyle(

            color: Colors.grey,

            fontSize: 14,

          ),

        ),

        trailing: PopupMenuButton<String>(

          icon: const Icon(Icons.more_vert, color: Colors.grey),

          onSelected: (value) {

            if (value == 'edit') {

              _navigateToEditPayment(index);

            } else if (value == 'delete') {

              _showDeleteConfirm(index);

            }

          },

          itemBuilder: (BuildContext context) => [

            const PopupMenuItem<String>(

              value: 'edit',

              child: Row(

                children: [

                  Icon(Icons.edit, size: 20),

                  SizedBox(width: 8),

                  Text('変更'),

                ],

              ),

            ),

            const PopupMenuItem<String>(

              value: 'delete',

              child: Row(

                children: [

                  Icon(Icons.delete, size: 20, color: Colors.red),

                  SizedBox(width: 8),

                  Text('削除', style: TextStyle(color: Colors.red)),

                ],

              ),

            ),

          ],

        ),

        onTap: () => _navigateToEditPayment(index),

        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      ),

    );

  }

}



// 支払い方法追加画面

class AddPaymentMethodScreen extends StatefulWidget {

  const AddPaymentMethodScreen({Key? key}) : super(key: key);



  @override

  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();

}



class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {

  final _formKey = GlobalKey<FormState>();

  final _cardNumberController = TextEditingController();

  final _expiryController = TextEditingController();

  final _cvvController = TextEditingController();

  final _cardHolderController = TextEditingController();



  String _selectedCardBrand = 'VISA';

  String _selectedCountry = '日本';

  bool _isLoading = false;



  final List<Map<String, dynamic>> _cardBrands = [

    {'name': 'VISA', 'icon': Icons.credit_card, 'color': Colors.blue},

    {'name': 'MasterCard', 'icon': Icons.credit_card, 'color': Colors.red},

    {'name': 'JCB', 'icon': Icons.credit_card, 'color': Colors.orange},

    {'name': 'American Express', 'icon': Icons.credit_card, 'color': Colors.green},

  ];



  final List<String> _countries = ['日本', 'アメリカ', 'イギリス', 'カナダ', 'オーストラリア'];



  Future<void> _savePaymentMethod() async {

    if (_formKey.currentState!.validate()) {

      setState(() {

        _isLoading = true;

      });



      await Future.delayed(const Duration(milliseconds: 1500));



      final newPaymentMethod = {

        'brand': _selectedCardBrand,

        'last4': _cardNumberController.text.length >= 4

            ? _cardNumberController.text.substring(_cardNumberController.text.length - 4)

            : '0000',

        'type': _selectedCardBrand,

        'icon': Icons.credit_card,

        'color': _cardBrands.firstWhere((brand) => brand['name'] == _selectedCardBrand)['color'],

        'cardNumber': _cardNumberController.text,

        'expiry': _expiryController.text,

        'cvv': _cvvController.text,

        'country': _selectedCountry,

      };

     

      PaymentMethodManager.addPaymentMethod(newPaymentMethod);

     

      setState(() {

        _isLoading = false;

      });

     

      Navigator.pop(context, true);

    }

  }



  String? _validateCardNumber(String? value) {

    if (value == null || value.isEmpty) return 'カード番号を入力してください';

    final cleaned = value.replaceAll(' ', '');

    if (cleaned.length != 16) return '16桁のカード番号を入力してください';

    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return '数字のみ入力してください';

    return null;

  }



  String? _validateExpiry(String? value) {

    if (value == null || value.isEmpty) return '有効期限を入力してください';

    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) return 'MM/YY形式で入力してください';

    return null;

  }



  String? _validateCVV(String? value) {

    if (value == null || value.isEmpty) return 'CVVを入力してください';

    if (value.length != 3) return '3桁のCVVを入力してください';

    if (!RegExp(r'^\d+$').hasMatch(value)) return '数字のみ入力してください';

    return null;

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.grey[50],

      appBar: AppBar(

        backgroundColor: Colors.white,

        elevation: 0,

        title: const Text(

          'お支払い方法を追加',

          style: TextStyle(color: Colors.black),

        ),

        centerTitle: true,

        iconTheme: const IconThemeData(color: Colors.black),

        leading: IconButton(

          icon: const Icon(Icons.arrow_back),

          onPressed: () => Navigator.pop(context),

        ),

      ),

      body: _isLoading ? _buildLoadingState() : _buildForm(),

    );

  }



  Widget _buildLoadingState() {

    return const Center(

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          CircularProgressIndicator(

            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),

          ),

          SizedBox(height: 16),

          Text(

            '処理中...',

            style: TextStyle(

              fontSize: 16,

              color: Colors.grey,

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildForm() {

    return SingleChildScrollView(

      padding: const EdgeInsets.all(16),

      child: Form(

        key: _formKey,

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(

              'カードブランドを選択',

              style: TextStyle(

                fontSize: 16,

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 12),

            _buildCardBrandSelector(),

            const SizedBox(height: 24),



            _buildCardForm(),

            const SizedBox(height: 32),



            _buildSaveButton(),

          ],

        ),

      ),

    );

  }



  Widget _buildCardBrandSelector() {

    return SizedBox(

      height: 60,

      child: ListView.builder(

        scrollDirection: Axis.horizontal,

        itemCount: _cardBrands.length,

        itemBuilder: (context, index) {

          final brand = _cardBrands[index];

          final isSelected = _selectedCardBrand == brand['name'];

          return GestureDetector(

            onTap: () {

              setState(() {

                _selectedCardBrand = brand['name'];

              });

            },

            child: Container(

              margin: const EdgeInsets.only(right: 12),

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

              decoration: BoxDecoration(

                color: isSelected ? brand['color'] : Colors.white,

                borderRadius: BorderRadius.circular(12),

                border: Border.all(

                  color: isSelected ? brand['color'] : Colors.grey[300]!,

                  width: 2,

                ),

              ),

              child: Row(

                children: [

                  Icon(

                    brand['icon'],

                    color: isSelected ? Colors.white : brand['color'],

                    size: 20,

                  ),

                  const SizedBox(width: 8),

                  Text(

                    brand['name'],

                    style: TextStyle(

                      color: isSelected ? Colors.white : Colors.black87,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                ],

              ),

            ),

          );

        },

      ),

    );

  }



  Widget _buildCardForm() {

    return Container(

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.05),

            blurRadius: 8,

            offset: const Offset(0, 2),

          ),

        ],

      ),

      child: Column(

        children: [

          TextFormField(

            controller: _cardNumberController,

            decoration: const InputDecoration(

              labelText: 'カード番号',

              hintText: '1234 5678 9012 3456',

              border: OutlineInputBorder(),

              prefixIcon: Icon(Icons.credit_card),

            ),

            keyboardType: TextInputType.number,

            validator: _validateCardNumber,

          ),

          const SizedBox(height: 16),



          Row(

            children: [

              Expanded(

                child: TextFormField(

                  controller: _expiryController,

                  decoration: const InputDecoration(

                    labelText: '有効期限',

                    hintText: 'MM/YY',

                    border: OutlineInputBorder(),

                    prefixIcon: Icon(Icons.calendar_today),

                  ),

                  validator: _validateExpiry,

                ),

              ),

              const SizedBox(width: 16),

              Expanded(

                child: TextFormField(

                  controller: _cvvController,

                  decoration: const InputDecoration(

                    labelText: 'PWD',

                    hintText: '123',

                    border: OutlineInputBorder(),

                    prefixIcon: Icon(Icons.lock),

                  ),

                  keyboardType: TextInputType.number,

                  obscureText: true,

                  validator: _validateCVV,

                ),

              ),

            ],

          ),

          const SizedBox(height: 16),



          TextFormField(

            controller: _cardHolderController,

            decoration: const InputDecoration(

              labelText: 'カード名義人',

              hintText: 'TARO YAMADA',

              border: OutlineInputBorder(),

              prefixIcon: Icon(Icons.person),

            ),

            validator: (value) {

              if (value == null || value.isEmpty) return 'カード名義人を入力してください';

              return null;

            },

          ),

          const SizedBox(height: 16),



          DropdownButtonFormField(

            value: _selectedCountry,

            decoration: const InputDecoration(

              labelText: '国',

              border: OutlineInputBorder(),

              prefixIcon: Icon(Icons.flag),

            ),

            items: _countries.map((country) {

              return DropdownMenuItem(

                value: country,

                child: Text(country),

              );

            }).toList(),

            onChanged: (value) {

              setState(() {

                _selectedCountry = value!;

              });

            },

          ),

        ],

      ),

    );

  }



  Widget _buildSaveButton() {

    return SizedBox(

      width: double.infinity,

      child: ElevatedButton(

        onPressed: _isLoading ? null : _savePaymentMethod,

        style: ElevatedButton.styleFrom(

          backgroundColor: Colors.blueAccent,

          padding: const EdgeInsets.symmetric(vertical: 18),

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

            : const Text(

                'お支払い方法を追加',

                style: TextStyle(

                  color: Colors.white,

                  fontSize: 16,

                  fontWeight: FontWeight.bold,

                ),

              ),

      ),

    );

  }



  @override

  void dispose() {

    _cardNumberController.dispose();

    _expiryController.dispose();

    _cvvController.dispose();

    _cardHolderController.dispose();

    super.dispose();

  }

}



// 支払い方法編集画面

class EditPaymentMethodScreen extends StatefulWidget {

  final Map<String, dynamic> paymentMethod;

  final int index;



  const EditPaymentMethodScreen({

    Key? key,

    required this.paymentMethod,

    required this.index,

  }) : super(key: key);



  @override

  State<EditPaymentMethodScreen> createState() => _EditPaymentMethodScreenState();

}



class _EditPaymentMethodScreenState extends State<EditPaymentMethodScreen> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cardNumberController;

  late TextEditingController _expiryController;

  late TextEditingController _cvvController;

  late TextEditingController _cardHolderController;



  late String _selectedCardBrand;

  late String _selectedCountry;

  bool _isLoading = false;



  final List<Map<String, dynamic>> _cardBrands = [

    {'name': 'VISA', 'icon': Icons.credit_card, 'color': Colors.blue},

    {'name': 'MasterCard', 'icon': Icons.credit_card, 'color': Colors.red},

    {'name': 'JCB', 'icon': Icons.credit_card, 'color': Colors.orange},

    {'name': 'American Express', 'icon': Icons.credit_card, 'color': Colors.green},

  ];



  final List<String> _countries = ['日本', 'アメリカ', 'イギリス', 'カナダ', 'オーストラリア'];



  @override

  void initState() {

    super.initState();

    _cardNumberController = TextEditingController(text: widget.paymentMethod['cardNumber']);

    _expiryController = TextEditingController(text: widget.paymentMethod['expiry']);

    _cvvController = TextEditingController(text: widget.paymentMethod['cvv']);

    _cardHolderController = TextEditingController(text: widget.paymentMethod['cardHolder'] ?? '');

    _selectedCardBrand = widget.paymentMethod['brand'];

    _selectedCountry = widget.paymentMethod['country'];

  }



  Future<void> _updatePaymentMethod() async {

    if (_formKey.currentState!.validate()) {

      setState(() {

        _isLoading = true;

      });



      await Future.delayed(const Duration(milliseconds: 1500));



      final updatedMethod = {

        'brand': _selectedCardBrand,

        'last4': _cardNumberController.text.length >= 4

            ? _cardNumberController.text.substring(_cardNumberController.text.length - 4)

            : '0000',

        'type': _selectedCardBrand,

        'icon': Icons.credit_card,

        'color': _cardBrands.firstWhere((brand) => brand['name'] == _selectedCardBrand)['color'],

        'cardNumber': _cardNumberController.text,

        'expiry': _expiryController.text,

        'cvv': _cvvController.text,

        'country': _selectedCountry,

      };

     

      PaymentMethodManager.updatePaymentMethod(widget.index, updatedMethod);

     

      setState(() {

        _isLoading = false;

      });

     

      Navigator.pop(context, true);

    }

  }



  // バリデーション関数（追加画面と同じ）

  String? _validateCardNumber(String? value) {

    if (value == null || value.isEmpty) return 'カード番号を入力してください';

    final cleaned = value.replaceAll(' ', '');

    if (cleaned.length != 16) return '16桁のカード番号を入力してください';

    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return '数字のみ入力してください';

    return null;

  }



  String? _validateExpiry(String? value) {

    if (value == null || value.isEmpty) return '有効期限を入力してください';

    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) return 'MM/YY形式で入力してください';

    return null;

  }



  String? _validateCVV(String? value) {

    if (value == null || value.isEmpty) return 'PWDを入力してください';

    if (value.length != 3) return '3桁のPWDを入力してください';

    if (!RegExp(r'^\d+$').hasMatch(value)) return '数字のみ入力してください';

    return null;

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.grey[50],

      appBar: AppBar(

        backgroundColor: Colors.white,

        elevation: 0,

        title: const Text(

          'お支払い方法を変更',

          style: TextStyle(color: Colors.black),

        ),

        centerTitle: true,

        iconTheme: const IconThemeData(color: Colors.black),

        leading: IconButton(

          icon: const Icon(Icons.arrow_back),

          onPressed: () => Navigator.pop(context),

        ),

      ),

      body: _isLoading ? _buildLoadingState() : _buildForm(),

    );

  }



  Widget _buildLoadingState() {

    return const Center(

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          CircularProgressIndicator(

            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),

          ),

          SizedBox(height: 16),

          Text(

            '処理中...',

            style: TextStyle(

              fontSize: 16,

              color: Colors.grey,

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildForm() {

    return SingleChildScrollView(

      padding: const EdgeInsets.all(16),

      child: Form(

        key: _formKey,

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(

              'カードブランドを選択',

              style: TextStyle(

                fontSize: 16,

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 12),

            _buildCardBrandSelector(),

            const SizedBox(height: 24),



            _buildCardForm(),

            const SizedBox(height: 32),



            _buildUpdateButton(),

          ],

        ),

      ),

    );

  }



  Widget _buildCardBrandSelector() {

    return SizedBox(

      height: 60,

      child: ListView.builder(

        scrollDirection: Axis.horizontal,

        itemCount: _cardBrands.length,

        itemBuilder: (context, index) {

          final brand = _cardBrands[index];

          final isSelected = _selectedCardBrand == brand['name'];

          return GestureDetector(

            onTap: () {

              setState(() {

                _selectedCardBrand = brand['name'];

              });

            },

            child: Container(

              margin: const EdgeInsets.only(right: 12),

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

              decoration: BoxDecoration(

                color: isSelected ? brand['color'] : Colors.white,

                borderRadius: BorderRadius.circulCar(12),

                border: Border.all(

                  color: isSelected ? brand['color'] : Colors.grey[300]!,

                  width: 2,

                ),

              ),

              child: Row(

                children: [

                  Icon(

                    brand['icon'],

                    color: isSelected ? Colors.white : brand['color'],

                    size: 20,

                  ),

                  const SizedBox(width: 8),

                  Text(

                    brand['name'],

                    style: TextStyle(

                      color: isSelected ? Colors.white : Colors.black87,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                ],

              ),

            ),

          );

        },

      ),

    );

  }



  Widget _buildCardForm() {

    return Container(

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.05),

            blurRadius: 8,

            offset: const Offset(0, 2),

          ),

        ],

      ),

      child: Column(

        children: [

          TextFormField(

            controller: _cardNumberController,

            decoration: const InputDecoration(

              labelText: 'カード番号',

              hintText: '1234 5678 9012 3456',

              border: OutlineInputBorder(),

              prefixIcon: Icon(Icons.credit_card),

            ),

            keyboardType: TextInputType.number,

            validator: _validateCardNumber,

          ),

          const SizedBox(height: 16),



          Row(

            children: [

              Expanded(

                child: TextFormField(

                  controller: _expiryController,

                  decoration: const InputDecoration(

                    labelText: '有効期限',

                    hintText: 'MM/YY',

                    border: OutlineInputBorder(),

                    prefixIcon: Icon(Icons.calendar_today),

                  ),

                  validator: _validateExpiry,

                ),

              ),

              const SizedBox(width: 16),

              Expanded(

                child: TextFormField(

                  controller: _cvvController,

                  decoration: const InputDecoration(

                    labelText: 'PWD',

                    hintText: '123',

                    border: OutlineInputBorder(),

                    prefixIcon: Icon(Icons.lock),

                  ),

                  keyboardType: TextInputType.number,

                  obscureText: true,

                  validator: _validateCVV,

                ),

              ),

            ],

          ),

          const SizedBox(height: 16),



          TextFormField(

            controller: _cardHolderController,

            decoration: const InputDecoration(

              labelText: 'カード名義人',

              hintText: 'TARO YAMADA',

              border: OutlineInputBorder(),

              prefixIcon: Icon(Icons.person),

            ),

            validator: (value) {

              if (value == null || value.isEmpty) return 'カード名義人を入力してください';

              return null;

            },

          ),

          const SizedBox(height: 16),



          DropdownButtonFormField(

            value: _selectedCountry,

            decoration: const InputDecoration(

              labelText: '国',

              border: OutlineInputBorder(),

              prefixIcon: Icon(Icons.flag),

            ),

            items: _countries.map((country) {

              return DropdownMenuItem(

                value: country,

                child: Text(country),

              );

            }).toList(),

            onChanged: (value) {

              setState(() {

                _selectedCountry = value!;

              });

            },

          ),

        ],

      ),

    );

  }



  Widget _buildUpdateButton() {

    return SizedBox(

      width: double.infinity,

      child: ElevatedButton(

        onPressed: _isLoading ? null : _updatePaymentMethod,

        style: ElevatedButton.styleFrom(

          backgroundColor: Colors.blueAccent,

          padding: const EdgeInsets.symmetric(vertical: 18),

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

            : const Text(

                'お支払い方法を変更',

                style: TextStyle(

                  color: Colors.white,

                  fontSize: 16,

                  fontWeight: FontWeight.bold,

                ),

              ),

      ),

    );

  }



  @override

  void dispose() {

    _cardNumberController.dispose();

    _expiryController.dispose();

    _cvvController.dispose();

    _cardHolderController.dispose();

    super.dispose();

  }

}



  static void updatePaymentMethod(int index, Map<String, dynamic> updatedMethod) {

    _paymentMethods[index] = updatedMethod;

  }



  static void removePaymentMethod(int index) {

    _paymentMethods.removeAt(index);

  }

}



class PaymentManagementScreen extends StatefulWidget {

  const PaymentManagementScreen({Key? key}) : super(key: key);



  @override

  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();

}



class _PaymentManagementScreenState extends State<PaymentManagementScreen> {

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



  void _navigateToAddPayment() async {

    final result = await Navigator.push(

      context,

      MaterialPageRoute(builder: (context) => const AddPaymentMethodScreen()),

    );

   

    if (result == true) {

      _loadPaymentMethods();

      _showSuccessToast('お支払い方法を追加しました');

    }

  }



  void _navigateToEditPayment(int index) async {

    final result = await Navigator.push(

      context,

      MaterialPageRoute(

        builder: (context) => EditPaymentMethodScreen(

          paymentMethod: _paymentMethods[index],

          index: index,

        ),

      ),

    );

   

    if (result == true) {

      _loadPaymentMethods();

      _showSuccessToast('お支払い方法が変更されました');

    }

  }



  void _showSuccessToast(String message) {

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: Text(message),

        backgroundColor: Colors.green[600],

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

        duration: const Duration(seconds: 2),

      ),

    );

  }



  void _showDeleteConfirm(int index) {

    showDialog(

      context: context,

      builder: (context) => AlertDialog(

        title: const Text('支払い方法を削除'),

        content: const Text('この支払い方法を削除しますか？'),

        actions: [

          TextButton(

            onPressed: () => Navigator.pop(context),

            child: const Text('キャンセル',

            style: TextStyle(

              color: Colors.blue,

            ),),

          ),

          ElevatedButton(

            onPressed: () {

              Navigator.pop(context);

              _deletePaymentMethod(index);

            },

            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),

            child: const Text('削除する',

            style: TextStyle(

              color: Colors.white,

            ),),

          ),

        ],

      ),

    );

  }



  void _deletePaymentMethod(int index) {

    setState(() {

      PaymentMethodManager.removePaymentMethod(index);

      _paymentMethods = PaymentMethodManager.paymentMethods;

    });

    ScaffoldMessenger.of(context).showSnackBar(

      SnackBar(

        content: const Text('支払い方法を削除しました'),

        backgroundColor: Colors.red[600],

        behavior: SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.grey[50],

      appBar: AppBar(

        backgroundColor: Colors.white,

        elevation: 0,

        title: const Text(

          'お支払い情報一覧',

          style: TextStyle(color: Colors.black),

        ),

        centerTitle: true,

        iconTheme: const IconThemeData(color: Colors.black),

      ),

      body: _paymentMethods.isEmpty ? _buildEmptyState() : _buildPaymentMethodsList(),

      floatingActionButton: _paymentMethods.isNotEmpty ? _buildFloatingActionButton() : null,

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

    );

  }



  Widget _buildFloatingActionButton() {

    return Container(

      margin: const EdgeInsets.only(bottom: 16),

      child: FloatingActionButton.extended(

        onPressed: _navigateToAddPayment,

        backgroundColor: Colors.blueAccent,

        foregroundColor: Colors.white,

        elevation: 4,

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

        icon: const Icon(Icons.add, size: 24),

        label: const Text(

          'お支払い方法を追加',

          style: TextStyle(fontWeight: FontWeight.bold),

        ),

      ),

    );

  }



  Widget _buildEmptyState() {

    return Padding(

      padding: const EdgeInsets.all(16),

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          Container(

            width: 120,

            height: 120,

            decoration: BoxDecoration(

              color: Colors.blue[50],

              shape: BoxShape.circle,

            ),

            child: const Icon(

              Icons.credit_card,

              size: 60,

              color: Colors.blueAccent,

            ),

          ),

          const SizedBox(height: 24),

          const Text(

            '支払い方法がありません',

            style: TextStyle(

              fontSize: 20,

              fontWeight: FontWeight.bold,

              color: Colors.black87,

            ),

          ),

          const SizedBox(height: 8),

          const Text(

            'お支払い方法を追加して、\nスムーズにお買い物をお楽しみください',

            textAlign: TextAlign.center,

            style: TextStyle(

              color: Colors.grey,

              fontSize: 14,

            ),

          ),

          const SizedBox(height: 32),

          _buildPrimaryAddButton(),

        ],

      ),

    );

  }



  Widget _buildPrimaryAddButton() {

    return SizedBox(

      width: double.infinity,

      child: ElevatedButton(

        onPressed: _navigateToAddPayment,

        style: ElevatedButton.styleFrom(

          backgroundColor: Colors.blueAccent,

          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(12),

          ),

          elevation: 2,

        ),

        child: const Text(

          'お支払い方法を追加',

          style: TextStyle(

            fontSize: 16,

            fontWeight: FontWeight.bold,

            color: Colors.white,

          ),

        ),

      ),

    );

  }



  Widget _buildPaymentMethodsList() {

    return Padding(

      padding: const EdgeInsets.all(16),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          const Text(

            'お支払い方法',

            style: TextStyle(

              fontSize: 18,

              fontWeight: FontWeight.bold,

              color: Colors.black87,

            ),

          ),

          const SizedBox(height: 16),

         

          Expanded(

            child: ListView.builder(

              itemCount: _paymentMethods.length,

              itemBuilder: (context, index) {

                final method = _paymentMethods[index];

                return _buildPaymentMethodCard(method, index);

              },

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildPaymentMethodCard(Map<String, dynamic> method, int index) {

    return Container(

      margin: const EdgeInsets.only(bottom: 12),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(12),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.05),

            blurRadius: 8,

            offset: const Offset(0, 2),

          ),

        ],

      ),

      child: ListTile(

        leading: Container(

          width: 44,

          height: 44,

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

        title: Text(

          method['brand'],

          style: const TextStyle(

            fontWeight: FontWeight.bold,

            fontSize: 16,

          ),

        ),

        subtitle: Text(

          '•••• ${method['last4']}',

          style: const TextStyle(

            color: Colors.grey,

            fontSize: 14,

          ),

        ),

        trailing: PopupMenuButton<String>(

          icon: const Icon(Icons.more_vert, color: Colors.grey),

          onSelected: (value) {

            if (value == 'edit') {

              _navigateToEditPayment(index);

            } else if (value == 'delete') {

              _showDeleteConfirm(index);

            }

          },

          itemBuilder: (BuildContext context) => [

            const PopupMenuItem<String>(

              value: 'edit',

              child: Row(

                children: [

                  Icon(Icons.edit, size: 20),

                  SizedBox(width: 8),

                  Text('変更'),

                ],

              ),

            ),

            const PopupMenuItem<String>(

              value: 'delete',

              child: Row(

                children: [

                  Icon(Icons.delete, size: 20, color: Colors.red),

                  SizedBox(width: 8),

                  Text('削除', style: TextStyle(color: Colors.red)),

                ],

              ),

            ),

          ],

        ),

        onTap: () => _navigateToEditPayment(index),

        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      ),

    );

  }

}



// 支払い方法追加画面

class AddPaymentMethodScreen extends StatefulWidget {

  const AddPaymentMethodScreen({Key? key}) : super(key: key);



  @override

  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();

}



class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {

  final _formKey = GlobalKey<FormState>();

  final _cardNumberController = TextEditingController();

  final _expiryController = TextEditingController();

  final _cvvController = TextEditingController();

  final _cardHolderController = TextEditingController();



  String _selectedCardBrand = 'VISA';

  String _selectedCountry = '日本';

  bool _isLoading = false;



  final List<Map<String, dynamic>> _cardBrands = [

    {'name': 'VISA', 'icon': Icons.credit_card, 'color': Colors.blue},

    {'name': 'MasterCard', 'icon': Icons.credit_card, 'color': Colors.red},

    {'name': 'JCB', 'icon': Icons.credit_card, 'color': Colors.orange},

    {'name': 'American Express', 'icon': Icons.credit_card, 'color': Colors.green},

  ];



  final List<String> _countries = ['日本', 'アメリカ', 'イギリス', 'カナダ', 'オーストラリア'];



  Future<void> _savePaymentMethod() async {

    if (_formKey.currentState!.validate()) {

      setState(() {

        _isLoading = true;

      });



      await Future.delayed(const Duration(milliseconds: 1500));



      final newPaymentMethod = {

        'brand': _selectedCardBrand,

        'last4': _cardNumberController.text.length >= 4

            ? _cardNumberController.text.substring(_cardNumberController.text.length - 4)

            : '0000',

        'type': _selectedCardBrand,

        'icon': Icons.credit_card,

        'color': _cardBrands.firstWhere((brand) => brand['name'] == _selectedCardBrand)['color'],

        'cardNumber': _cardNumberController.text,

        'expiry': _expiryController.text,

        'cvv': _cvvController.text,

        'country': _selectedCountry,

      };

     

      PaymentMethodManager.addPaymentMethod(newPaymentMethod);

     

      setState(() {

        _isLoading = false;

      });

     

      Navigator.pop(context, true);

    }

  }



  String? _validateCardNumber(String? value) {

    if (value == null || value.isEmpty) return 'カード番号を入力してください';

    final cleaned = value.replaceAll(' ', '');

    if (cleaned.length != 16) return '16桁のカード番号を入力してください';

    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return '数字のみ入力してください';

    return null;

  }



  String? _validateExpiry(String? value) {

    if (value == null || value.isEmpty) return '有効期限を入力してください';

    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) return 'MM/YY形式で入力してください';

    return null;

  }



  String? _validateCVV(String? value) {

    if (value == null || value.isEmpty) return 'CVVを入力してください';

    if (value.length != 3) return '3桁のCVVを入力してください';

    if (!RegExp(r'^\d+$').hasMatch(value)) return '数字のみ入力してください';

    return null;

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.grey[50],

      appBar: AppBar(

        backgroundColor: Colors.white,

        elevation: 0,

        title: const Text(

          'お支払い方法を追加',

          style: TextStyle(color: Colors.black),

        ),

        centerTitle: true,

        iconTheme: const IconThemeData(color: Colors.black),

        leading: IconButton(

          icon: const Icon(Icons.arrow_back),

          onPressed: () => Navigator.pop(context),

        ),

      ),

      body: _isLoading ? _buildLoadingState() : _buildForm(),

    );

  }



  Widget _buildLoadingState() {

    return const Center(

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          CircularProgressIndicator(

            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),

          ),

          SizedBox(height: 16),

          Text(

            '処理中...',

            style: TextStyle(

              fontSize: 16,

              color: Colors.grey,

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildForm() {

    return SingleChildScrollView(

      padding: const EdgeInsets.all(16),

      child: Form(

        key: _formKey,

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(

              'カードブランドを選択',

              style: TextStyle(

                fontSize: 16,

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 12),

            _buildCardBrandSelector(),

            const SizedBox(height: 24),



            _buildCardForm(),

            const SizedBox(height: 32),



            _buildSaveButton(),

          ],

        ),

      ),

    );

  }



  Widget _buildCardBrandSelector() {

    return SizedBox(

      height: 60,

      child: ListView.builder(

        scrollDirection: Axis.horizontal,

        itemCount: _cardBrands.length,

        itemBuilder: (context, index) {

          final brand = _cardBrands[index];

          final isSelected = _selectedCardBrand == brand['name'];

          return GestureDetector(

            onTap: () {

              setState(() {

                _selectedCardBrand = brand['name'];

              });

            },

            child: Container(

              margin: const EdgeInsets.only(right: 12),

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

              decoration: BoxDecoration(

                color: isSelected ? brand['color'] : Colors.white,

                borderRadius: BorderRadius.circular(12),

                border: Border.all(

                  color: isSelected ? brand['color'] : Colors.grey[300]!,

                  width: 2,

                ),

              ),

              child: Row(

                children: [

                  Icon(

                    brand['icon'],

                    color: isSelected ? Colors.white : brand['color'],

                    size: 20,

                  ),

                  const SizedBox(width: 8),

                  Text(

                    brand['name'],

                    style: TextStyle(

                      color: isSelected ? Colors.white : Colors.black87,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                ],

              ),

            ),

          );

        },

      ),

    );

  }



  Widget _buildCardForm() {

    return Container(

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.05),

            blurRadius: 8,

            offset: const Offset(0, 2),

          ),

        ],

      ),

      child: Column(

        children: [

          TextFormField(

            controller: _cardNumberController,

            decoration: const InputDecoration(

              labelText: 'カード番号',

              hintText: '1234 5678 9012 3456',

              border: OutlineInputBorder(),

              prefixIcon: Icon(Icons.credit_card),

            ),

            keyboardType: TextInputType.number,

            validator: _validateCardNumber,

          ),

          const SizedBox(height: 16),



          Row(

            children: [

              Expanded(

                child: TextFormField(

                  controller: _expiryController,

                  decoration: const InputDecoration(

                    labelText: '有効期限',

                    hintText: 'MM/YY',

                    border: OutlineInputBorder(),

                    prefixIcon: Icon(Icons.calendar_today),

                  ),

                  validator: _validateExpiry,

                ),

              ),

              const SizedBox(width: 16),

              Expanded(

                child: TextFormField(

                  controller: _cvvController,

                  decoration: const InputDecoration(

                    labelText: 'PWD',

                    hintText: '123',

                    border: OutlineInputBorder(),

                    prefixIcon: Icon(Icons.lock),

                  ),

                  keyboardType: TextInputType.number,

                  obscureText: true,

                  validator: _validateCVV,

                ),

              ),

            ],

          ),

          const SizedBox(height: 16),



          TextFormField(

            controller: _cardHolderController,

            decoration: const InputDecoration(

              labelText: 'カード名義人',

              hintText: 'TARO YAMADA',

              border: OutlineInputBorder(),

              prefixIcon: Icon(Icons.person),

            ),

            validator: (value) {

              if (value == null || value.isEmpty) return 'カード名義人を入力してください';

              return null;

            },

          ),

          const SizedBox(height: 16),



          DropdownButtonFormField(

            value: _selectedCountry,

            decoration: const InputDecoration(

              labelText: '国',

              border: OutlineInputBorder(),

              prefixIcon: Icon(Icons.flag),

            ),

            items: _countries.map((country) {

              return DropdownMenuItem(

                value: country,

                child: Text(country),

              );

            }).toList(),

            onChanged: (value) {

              setState(() {

                _selectedCountry = value!;

              });

            },

          ),

        ],

      ),

    );

  }



  Widget _buildSaveButton() {

    return SizedBox(

      width: double.infinity,

      child: ElevatedButton(

        onPressed: _isLoading ? null : _savePaymentMethod,

        style: ElevatedButton.styleFrom(

          backgroundColor: Colors.blueAccent,

          padding: const EdgeInsets.symmetric(vertical: 18),

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

            : const Text(

                'お支払い方法を追加',

                style: TextStyle(

                  color: Colors.white,

                  fontSize: 16,

                  fontWeight: FontWeight.bold,

                ),

              ),

      ),

    );

  }



  @override

  void dispose() {

    _cardNumberController.dispose();

    _expiryController.dispose();

    _cvvController.dispose();

    _cardHolderController.dispose();

    super.dispose();

  }

}



// 支払い方法編集画面

class EditPaymentMethodScreen extends StatefulWidget {

  final Map<String, dynamic> paymentMethod;

  final int index;



  const EditPaymentMethodScreen({

    Key? key,

    required this.paymentMethod,

    required this.index,

  }) : super(key: key);



  @override

  State<EditPaymentMethodScreen> createState() => _EditPaymentMethodScreenState();

}



class _EditPaymentMethodScreenState extends State<EditPaymentMethodScreen> {

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _cardNumberController;

  late TextEditingController _expiryController;

  late TextEditingController _cvvController;

  late TextEditingController _cardHolderController;



  late String _selectedCardBrand;

  late String _selectedCountry;

  bool _isLoading = false;



  final List<Map<String, dynamic>> _cardBrands = [

    {'name': 'VISA', 'icon': Icons.credit_card, 'color': Colors.blue},

    {'name': 'MasterCard', 'icon': Icons.credit_card, 'color': Colors.red},

    {'name': 'JCB', 'icon': Icons.credit_card, 'color': Colors.orange},

    {'name': 'American Express', 'icon': Icons.credit_card, 'color': Colors.green},

  ];



  final List<String> _countries = ['日本', 'アメリカ', 'イギリス', 'カナダ', 'オーストラリア'];



  @override

  void initState() {

    super.initState();

    _cardNumberController = TextEditingController(text: widget.paymentMethod['cardNumber']);

    _expiryController = TextEditingController(text: widget.paymentMethod['expiry']);

    _cvvController = TextEditingController(text: widget.paymentMethod['cvv']);

    _cardHolderController = TextEditingController(text: widget.paymentMethod['cardHolder'] ?? '');

    _selectedCardBrand = widget.paymentMethod['brand'];

    _selectedCountry = widget.paymentMethod['country'];

  }



  Future<void> _updatePaymentMethod() async {

    if (_formKey.currentState!.validate()) {

      setState(() {

        _isLoading = true;

      });



      await Future.delayed(const Duration(milliseconds: 1500));



      final updatedMethod = {

        'brand': _selectedCardBrand,

        'last4': _cardNumberController.text.length >= 4

            ? _cardNumberController.text.substring(_cardNumberController.text.length - 4)

            : '0000',

        'type': _selectedCardBrand,

        'icon': Icons.credit_card,

        'color': _cardBrands.firstWhere((brand) => brand['name'] == _selectedCardBrand)['color'],

        'cardNumber': _cardNumberController.text,

        'expiry': _expiryController.text,

        'cvv': _cvvController.text,

        'country': _selectedCountry,

      };

     

      PaymentMethodManager.updatePaymentMethod(widget.index, updatedMethod);

     

      setState(() {

        _isLoading = false;

      });

     

      Navigator.pop(context, true);

    }

  }



  // バリデーション関数（追加画面と同じ）

  String? _validateCardNumber(String? value) {

    if (value == null || value.isEmpty) return 'カード番号を入力してください';

    final cleaned = value.replaceAll(' ', '');

    if (cleaned.length != 16) return '16桁のカード番号を入力してください';

    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return '数字のみ入力してください';

    return null;

  }



  String? _validateExpiry(String? value) {

    if (value == null || value.isEmpty) return '有効期限を入力してください';

    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) return 'MM/YY形式で入力してください';

    return null;

  }



  String? _validateCVV(String? value) {

    if (value == null || value.isEmpty) return 'PWDを入力してください';

    if (value.length != 3) return '3桁のPWDを入力してください';

    if (!RegExp(r'^\d+$').hasMatch(value)) return '数字のみ入力してください';

    return null;

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.grey[50],

      appBar: AppBar(

        backgroundColor: Colors.white,

        elevation: 0,

        title: const Text(

          'お支払い方法を変更',

          style: TextStyle(color: Colors.black),

        ),

        centerTitle: true,

        iconTheme: const IconThemeData(color: Colors.black),

        leading: IconButton(

          icon: const Icon(Icons.arrow_back),

          onPressed: () => Navigator.pop(context),

        ),

      ),

      body: _isLoading ? _buildLoadingState() : _buildForm(),

    );

  }



  Widget _buildLoadingState() {

    return const Center(

      child: Column(

        mainAxisAlignment: MainAxisAlignment.center,

        children: [

          CircularProgressIndicator(

            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),

          ),

          SizedBox(height: 16),

          Text(

            '処理中...',

            style: TextStyle(

              fontSize: 16,

              color: Colors.grey,

            ),

          ),

        ],

      ),

    );

  }



  Widget _buildForm() {

    return SingleChildScrollView(

      padding: const EdgeInsets.all(16),

      child: Form(

        key: _formKey,

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(

              'カードブランドを選択',

              style: TextStyle(

                fontSize: 16,

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 12),

            _buildCardBrandSelector(),

            const SizedBox(height: 24),



            _buildCardForm(),

            const SizedBox(height: 32),



            _buildUpdateButton(),

          ],

        ),

      ),

    );

  }



  Widget _buildCardBrandSelector() {

    return SizedBox(

      height: 60,

      child: ListView.builder(

        scrollDirection: Axis.horizontal,

        itemCount: _cardBrands.length,

        itemBuilder: (context, index) {

          final brand = _cardBrands[index];

          final isSelected = _selectedCardBrand == brand['name'];

          return GestureDetector(

            onTap: () {

              setState(() {

                _selectedCardBrand = brand['name'];

              });

            },

            child: Container(

              margin: const EdgeInsets.only(right: 12),

              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

              decoration: BoxDecoration(

                color: isSelected ? brand['color'] : Colors.white,

                borderRadius: BorderRadius.circular(12),

                border: Border.all(

                  color: isSelected ? brand['color'] : Colors.grey[300]!,

                  width: 2,

                ),

              ),

              child: Row(

                children: [

                  Icon(

                    brand['icon'],

                    color: isSelected ? Colors.white : brand['color'],

                    size: 20,

                  ),

                  const SizedBox(width: 8),

                  Text(

                    brand['name'],

                    style: TextStyle(

                      color: isSelected ? Colors.white : Colors.black87,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                ],

              ),

            ),

          );

        },

      ),

    );

  }



  Widget _buildCardForm() {

    return Container(

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.05),

            blurRadius: 8,

            offset: const Offset(0, 2),

          ),

        ],

      ),

      child: Column(

        children: [

          TextFormField(

            controller: _cardNumberController,

            decoration: const InputDecoration(

              labelText: 'カード番号',

              hintText: '1234 5678 9012 3456',

              border: OutlineInputBorder(),

              prefixIcon: Icon(Icons.credit_card),

            ),

            keyboardType: TextInputType.number,

            validator: _validateCardNumber,

          ),

          const SizedBox(height: 16),



          Row(

            children: [

              Expanded(

                child: TextFormField(

                  controller: _expiryController,

                  decoration: const InputDecoration(

                    labelText: '有効期限',

                    hintText: 'MM/YY',

                    border: OutlineInputBorder(),

                    prefixIcon: Icon(Icons.calendar_today),

                  ),

                  validator: _validateExpiry,

                ),

              ),

              const SizedBox(width: 16),

              Expanded(

                child: TextFormField(

                  controller: _cvvController,

                  decoration: const InputDecoration(

                    labelText: 'PWD',

                    hintText: '123',

                    border: OutlineInputBorder(),

                    prefixIcon: Icon(Icons.lock),

                  ),

                  keyboardType: TextInputType.number,

                  obscureText: true,

                  validator: _validateCVV,

                ),

              ),

            ],

          ),

          const SizedBox(height: 16),



          TextFormField(

            controller: _cardHolderController,

            decoration: const InputDecoration(

              labelText: 'カード名義人',

              hintText: 'TARO YAMADA',

              border: OutlineInputBorder(),

              prefixIcon: Icon(Icons.person),

            ),

            validator: (value) {

              if (value == null || value.isEmpty) return 'カード名義人を入力してください';

              return null;

            },

          ),

          const SizedBox(height: 16),



          DropdownButtonFormField(

            value: _selectedCountry,

            decoration: const InputDecoration(

              labelText: '国',

              border: OutlineInputBorder(),

              prefixIcon: Icon(Icons.flag),

            ),

            items: _countries.map((country) {

              return DropdownMenuItem(

                value: country,

                child: Text(country),

              );

            }).toList(),

            onChanged: (value) {

              setState(() {

                _selectedCountry = value!;

              });

            },

          ),

        ],

      ),

    );

  }



  Widget _buildUpdateButton() {

    return SizedBox(

      width: double.infinity,

      child: ElevatedButton(

        onPressed: _isLoading ? null : _updatePaymentMethod,

        style: ElevatedButton.styleFrom(

          backgroundColor: Colors.blueAccent,

          padding: const EdgeInsets.symmetric(vertical: 18),

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

            : const Text(

                'お支払い方法を変更',

                style: TextStyle(

                  color: Colors.white,

                  fontSize: 16,

                  fontWeight: FontWeight.bold,

                ),

              ),

      ),

    );

  }



  @override

  void dispose() {

    _cardNumberController.dispose();

    _expiryController.dispose();

    _cvvController.dispose();

    _cardHolderController.dispose();

    super.dispose();

  }

}