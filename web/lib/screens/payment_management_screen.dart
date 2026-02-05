import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_webapp/config/app_config.dart';
import '../services/token_storage_service.dart';

const Map<String, String> _brandPrefixes = {
  'VISA': '4111',
  'MasterCard': '5555',
  'JCB': '3530',
  'American Express': '3782',
};

int _cvvLengthForBrand(String brand) => brand == 'American Express' ? 4 : 3;

String _normalizeDigits(String input) => input.replaceAll(RegExp(r'\D'), '');

String _applyBrandPrefix(String current, String brand) {
  final prefix = _brandPrefixes[brand] ?? '';
  if (prefix.isEmpty) return _normalizeDigits(current);
  final digits = _normalizeDigits(current);
  final rest = digits.length > 4 ? digits.substring(4) : '';
  return '$prefix$rest';
}

String? _validateExpiryValue(String? value) {
  if (value == null || value.isEmpty) return '有効期限を入力してください';
  if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) return 'MM/YY形式で入力してください';
  final month = int.tryParse(value.substring(0, 2)) ?? 0;
  if (month < 1 || month > 12) return '月は01-12で入力してください';
  return null;
}

String? _validateCvvValue(String? value, String brand) {
  if (value == null || value.isEmpty) return 'PWDを入力してください';
  final expected = _cvvLengthForBrand(brand);
  if (value.length != expected) return 'PWDは$expected桁で入力してください';
  return null;
}

class ExpiryTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = _normalizeDigits(newValue.text);
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(limited[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// APIサービス（DBと通信するクラス）
class PaymentApiService {
  static String get _baseUrl => AppConfig.apiBaseUrl;
  static String get baseUrl => '$_baseUrl/api/payments';

  static Future<List<dynamic>> getPaymentMethods() async {
    final token = await TokenStorageService().getAccessToken(); // 修正済み
    if (token == null) return [];
    
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return [];
  }

  static Future<void> addPaymentMethod(Map<String, dynamic> data) async {
    final token = await TokenStorageService().getAccessToken(); // 修正済み
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) throw Exception('Add failed');
  }

  static Future<void> updatePaymentMethod(int id, Map<String, dynamic> data) async {
    final token = await TokenStorageService().getAccessToken(); // 修正済み
    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) throw Exception('Update failed');
  }

  static Future<void> deletePaymentMethod(int id) async {
    final token = await TokenStorageService().getAccessToken(); // 修正済み
    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw Exception('Delete failed');
  }
}

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({Key? key}) : super(key: key);

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  List<dynamic> _paymentMethods = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await PaymentApiService.getPaymentMethods();
      if (mounted) {
        setState(() {
          _paymentMethods = methods;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
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

  void _navigateToEditPayment(dynamic method) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditPaymentMethodScreen(
          paymentMethod: method,
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

  void _showDeleteConfirm(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('支払い方法を削除'),
        content: const Text('この支払い方法を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル', style: TextStyle(color: Colors.blue)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await PaymentApiService.deletePaymentMethod(id);
              _deletePaymentMethod(); 
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('削除する', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deletePaymentMethod() {
    _loadPaymentMethods();
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
        title: const Text('お支払い情報一覧', style: TextStyle(color: Colors.black)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator()) 
        : (_paymentMethods.isEmpty ? _buildEmptyState() : _buildPaymentMethodsList()),
      floatingActionButton: (!_loading && _paymentMethods.isNotEmpty) ? _buildFloatingActionButton() : null,
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
        label: const Text('お支払い方法を追加', style: TextStyle(fontWeight: FontWeight.bold)),
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
            width: 120, height: 120,
            decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
            child: const Icon(Icons.credit_card, size: 60, color: Colors.blueAccent),
          ),
          const SizedBox(height: 24),
          const Text('支払い方法がありません', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text('お支払い方法を追加して、\nスムーズにお買い物をお楽しみください', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
        child: const Text('お支払い方法を追加', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildPaymentMethodsList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('お支払い方法', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _paymentMethods.length,
              itemBuilder: (context, index) {
                final method = _paymentMethods[index];
                return _buildPaymentMethodCard(method);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(dynamic method) {
    final brand = method['brand'] ?? 'Unknown';
    final last4 = method['last4'] ?? '0000';
    final id = method['id']; 

    Color cardColor = Colors.blue;
    if (brand == 'MasterCard') cardColor = Colors.red;
    if (brand == 'JCB') cardColor = Colors.orange;
    if (brand == 'American Express') cardColor = Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: cardColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(Icons.credit_card, color: cardColor, size: 24),
        ),
        title: Text(brand, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text('•••• $last4', style: const TextStyle(color: Colors.grey, fontSize: 14)),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          onSelected: (value) {
            if (value == 'edit') {
              _navigateToEditPayment(method);
            } else if (value == 'delete') {
              if (id != null) _showDeleteConfirm(id);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('変更')])),
            const PopupMenuItem<String>(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 20, color: Colors.red), SizedBox(width: 8), Text('削除', style: TextStyle(color: Colors.red))])),
          ],
        ),
        onTap: () => _navigateToEditPayment(method),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  @override
  void initState() {
    super.initState();
    _applyBrandPrefixToCardNumber();
  }

  void _applyBrandPrefixToCardNumber() {
    final updated = _applyBrandPrefix(_cardNumberController.text, _selectedCardBrand);
    _cardNumberController.text = updated;
    _cardNumberController.selection = TextSelection.collapsed(offset: updated.length);
  }

  void _trimCvvToBrand() {
    final maxLen = _cvvLengthForBrand(_selectedCardBrand);
    if (_cvvController.text.length > maxLen) {
      _cvvController.text = _cvvController.text.substring(0, maxLen);
      _cvvController.selection = TextSelection.collapsed(offset: _cvvController.text.length);
    }
  }

  void _onBrandSelected(String brand) {
    setState(() {
      _selectedCardBrand = brand;
      _applyBrandPrefixToCardNumber();
      _trimCvvToBrand();
    });
  }

  Future<void> _savePaymentMethod() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final newPaymentMethod = {
          'brand': _selectedCardBrand,
          'cardNumber': _cardNumberController.text,
          'expiry': _expiryController.text,
          'cvv': _cvvController.text,
          'country': _selectedCountry,
          'cardHolder': _cardHolderController.text,
        };
        await PaymentApiService.addPaymentMethod(newPaymentMethod);
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存に失敗しました')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // バリデーション
  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) return 'カード番号を入力してください';
    final cleaned = value.replaceAll(' ', '');
    if (cleaned.length < 14) return '正しいカード番号を入力してください';
    return null;
  }
  String? _validateExpiry(String? value) {
    return _validateExpiryValue(value);
  }
  String? _validateCVV(String? value) => _validateCvvValue(value, _selectedCardBrand);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('お支払い方法を追加', style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Colors.black), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('カードブランドを選択', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
        SizedBox(height: 60, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _cardBrands.length, itemBuilder: (context, index) {
          final brand = _cardBrands[index];
          final isSelected = _selectedCardBrand == brand['name'];
          return GestureDetector(onTap: () => _onBrandSelected(brand['name']), child: Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isSelected ? brand['color'] : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? brand['color'] : Colors.grey[300]!, width: 2)), child: Row(children: [Icon(brand['icon'], color: isSelected ? Colors.white : brand['color'], size: 20), const SizedBox(width: 8), Text(brand['name'], style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))])));
        })),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]), child: Column(children: [
          TextFormField(controller: _cardNumberController, decoration: const InputDecoration(labelText: 'カード番号', border: OutlineInputBorder(), prefixIcon: Icon(Icons.credit_card)), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: _validateCardNumber),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: TextFormField(controller: _expiryController, decoration: const InputDecoration(labelText: '有効期限', hintText: 'MM/YY', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4), ExpiryTextInputFormatter()], validator: _validateExpiry)), const SizedBox(width: 16), Expanded(child: TextFormField(controller: _cvvController, decoration: InputDecoration(labelText: 'PWD', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock), counterText: ''), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_cvvLengthForBrand(_selectedCardBrand))], maxLength: _cvvLengthForBrand(_selectedCardBrand), obscureText: true, validator: _validateCVV))]),
          const SizedBox(height: 16),
          TextFormField(controller: _cardHolderController, decoration: const InputDecoration(labelText: 'カード名義人', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)), validator: (v) => (v == null || v.isEmpty) ? '入力してください' : null),
          const SizedBox(height: 16),
          DropdownButtonFormField(value: _selectedCountry, decoration: const InputDecoration(labelText: '国', border: OutlineInputBorder(), prefixIcon: Icon(Icons.flag)), items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _selectedCountry = v!)),
        ])),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _savePaymentMethod, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('お支払い方法を追加', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
      ])),
    );
  }
}

// 支払い方法編集画面
class EditPaymentMethodScreen extends StatefulWidget {
  final dynamic paymentMethod; 
  const EditPaymentMethodScreen({Key? key, required this.paymentMethod}) : super(key: key);
  @override State<EditPaymentMethodScreen> createState() => _EditPaymentMethodScreenState();
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
  final List<Map<String, dynamic>> _cardBrands = [{'name': 'VISA', 'icon': Icons.credit_card, 'color': Colors.blue}, {'name': 'MasterCard', 'icon': Icons.credit_card, 'color': Colors.red}, {'name': 'JCB', 'icon': Icons.credit_card, 'color': Colors.orange}, {'name': 'American Express', 'icon': Icons.credit_card, 'color': Colors.green}];
  final List<String> _countries = ['日本', 'アメリカ', 'イギリス', 'カナダ', 'オーストラリア'];

  @override
  void initState() {
    super.initState();
    final m = widget.paymentMethod;
    _cardNumberController = TextEditingController(text: m['cardNumber'] ?? ''); 
    _expiryController = TextEditingController(text: m['expiry'] ?? '');
    _cvvController = TextEditingController(text: m['cvv'] ?? '');
    _cardHolderController = TextEditingController(text: m['holderName'] ?? m['cardHolder'] ?? '');
    _selectedCardBrand = m['brand'] ?? 'VISA';
    _selectedCountry = m['country'] ?? '日本';
  }

  void _applyBrandPrefixToCardNumber() {
    final updated = _applyBrandPrefix(_cardNumberController.text, _selectedCardBrand);
    _cardNumberController.text = updated;
    _cardNumberController.selection = TextSelection.collapsed(offset: updated.length);
  }

  void _trimCvvToBrand() {
    final maxLen = _cvvLengthForBrand(_selectedCardBrand);
    if (_cvvController.text.length > maxLen) {
      _cvvController.text = _cvvController.text.substring(0, maxLen);
      _cvvController.selection = TextSelection.collapsed(offset: _cvvController.text.length);
    }
  }

  void _onBrandSelected(String brand) {
    setState(() {
      _selectedCardBrand = brand;
      _applyBrandPrefixToCardNumber();
      _trimCvvToBrand();
    });
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) return '入力してください';
    final cleaned = value.replaceAll(' ', '');
    if (cleaned.length < 4) return '入力してください';
    return null;
  }

  String? _validateExpiry(String? value) {
    return _validateExpiryValue(value);
  }

  String? _validateCVV(String? value) => _validateCvvValue(value, _selectedCardBrand);

  Future<void> _updatePaymentMethod() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final updatedMethod = {
          'brand': _selectedCardBrand,
          'cardNumber': _cardNumberController.text,
          'expiry': _expiryController.text,
          'cvv': _cvvController.text,
          'country': _selectedCountry,
          'cardHolder': _cardHolderController.text,
        };
        final id = widget.paymentMethod['id'];
        if (id != null) {
          await PaymentApiService.updatePaymentMethod(id, updatedMethod);
        }
        if (mounted) Navigator.pop(context, true);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('変更に失敗しました')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('お支払い方法を変更', style: TextStyle(color: Colors.black)), backgroundColor: Colors.white, elevation: 0, centerTitle: true, iconTheme: const IconThemeData(color: Colors.black), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('カードブランドを選択', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
        SizedBox(height: 60, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _cardBrands.length, itemBuilder: (context, index) {
          final brand = _cardBrands[index];
          final isSelected = _selectedCardBrand == brand['name'];
          return GestureDetector(onTap: () => _onBrandSelected(brand['name']), child: Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isSelected ? brand['color'] : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? brand['color'] : Colors.grey[300]!, width: 2)), child: Row(children: [Icon(brand['icon'], color: isSelected ? Colors.white : brand['color'], size: 20), const SizedBox(width: 8), Text(brand['name'], style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))])));
        })),
        const SizedBox(height: 24),
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]), child: Column(children: [
          TextFormField(controller: _cardNumberController, decoration: const InputDecoration(labelText: 'カード番号', border: OutlineInputBorder(), prefixIcon: Icon(Icons.credit_card)), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], validator: _validateCardNumber),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: TextFormField(controller: _expiryController, decoration: const InputDecoration(labelText: '有効期限', hintText: 'MM/YY', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4), ExpiryTextInputFormatter()], validator: _validateExpiry)), const SizedBox(width: 16), Expanded(child: TextFormField(controller: _cvvController, decoration: InputDecoration(labelText: 'PWD', border: const OutlineInputBorder(), prefixIcon: const Icon(Icons.lock), counterText: ''), keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_cvvLengthForBrand(_selectedCardBrand))], maxLength: _cvvLengthForBrand(_selectedCardBrand), obscureText: true, validator: _validateCVV))]),
          const SizedBox(height: 16),
          TextFormField(controller: _cardHolderController, decoration: const InputDecoration(labelText: 'カード名義人', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)), validator: (v) => v!.isEmpty ? '入力してください' : null),
          const SizedBox(height: 16),
          DropdownButtonFormField(value: _selectedCountry, decoration: const InputDecoration(labelText: '国', border: OutlineInputBorder(), prefixIcon: Icon(Icons.flag)), items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(), onChanged: (v) => setState(() => _selectedCountry = v!)),
        ])),
        const SizedBox(height: 32),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _updatePaymentMethod, style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('お支払い方法を変更', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
      ]))),
    );
  }
}
