import 'package:flutter/material.dart';
import 'contact_model.dart';
import 'buttom_admin.dart';

class ContactDetailAdmin extends StatefulWidget {
  final Contact contact;

  const ContactDetailAdmin({Key? key, required this.contact}) : super(key: key);

  @override
  _ContactDetailAdminState createState() => _ContactDetailAdminState();
}

class _ContactDetailAdminState extends State<ContactDetailAdmin> {
  late Contact _currentContact;
  final TextEditingController _responseController = TextEditingController();
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _currentContact = widget.contact;
    _selectedStatus = _currentContact.status;
    _responseController.text = _currentContact.response ?? '';
  }

  void _updateStatus() {
    setState(() {
      _currentContact = _currentContact.copyWith(status: _selectedStatus);
    });
  }

  void _saveResponse() {
    setState(() {
      _currentContact = _currentContact.copyWith(
        status: '対応済',
        response: _responseController.text,
      );
      _selectedStatus = '対応済';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('返信を保存しました')),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '未対応':
        return Colors.red;
      case '対応中':
        return Colors.orange;
      case '対応済':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: BottomAdminLayout(
        mainContent: _buildMainContent(),
        selectedMenu: 'お問い合わせ管理',
        onMenuSelected: (_) {},
        showTabs: false,
      ),
    );
  }

  Widget _buildMainContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 基本情報
          _buildContactHeader(),
          SizedBox(height: 24),

          // お問い合わせ内容
          _buildContactContent(),
          SizedBox(height: 24),

          // 返信フォーム
          _buildResponseForm(),
          SizedBox(height: 32),

          // 操作ボタン
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildContactHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'お問い合わせ詳細',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildInfoRow('ID', _currentContact.id),
            _buildInfoRow('お名前', _currentContact.name),
            _buildInfoRow('メールアドレス', _currentContact.email),
            _buildInfoRow('カテゴリ', _currentContact.category),
            _buildInfoRow(
              'ステータス',
              _currentContact.status,
              valueStyle: TextStyle(
                color: _getStatusColor(_currentContact.status),
                fontWeight: FontWeight.bold,
              ),
            ),
            _buildInfoRow(
              '受信日時',
              '${_currentContact.createdAt.year}/${_currentContact.createdAt.month.toString().padLeft(2, '0')}/${_currentContact.createdAt.day.toString().padLeft(2, '0')} ${_currentContact.createdAt.hour.toString().padLeft(2, '0')}:${_currentContact.createdAt.minute.toString().padLeft(2, '0')}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactContent() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'お問い合わせ内容',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                _currentContact.content,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '返信フォーム',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // ステータス選択
            Row(
              children: [
                Text('ステータス: ', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: ['未対応', '対応中', '対応済'].map((String status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStatus = newValue!;
                    });
                  },
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _updateStatus,
                  child: Text('ステータス更新'),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // 返信内容
            Text('返信内容:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Container(
              height: 150,
              child: TextField(
                controller: _responseController,
                maxLines: null,
                expands: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '返信内容を入力してください...',
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveResponse,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text('返信を保存', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // 左端：一覧へ戻る
        OutlinedButton(
          onPressed: () {
            Navigator.pop(context, {'contact': _currentContact});
          },
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.grey,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          child: Text('一覧へ戻る', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: valueStyle ?? TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}