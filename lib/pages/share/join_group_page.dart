import 'package:flutter/material.dart';
import 'package:my_finance/models/group_model.dart';

// 1. Models: Định nghĩa dữ liệu cho Nhóm và Thành viên
class Member {
  final String id;
  final String name;
  final String? avatarUrl;

  Member({required this.id, required this.name, this.avatarUrl});
}

// 2. Màn hình tham gia nhóm
class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  // Trạng thái hiện tại: 0 = Nhập mã, 1 = Chọn thành viên
  int _currentStep = 0;
  bool _isLoading = false;

  final TextEditingController _codeController = TextEditingController();
  
  // Dữ liệu nhóm sau khi tìm thấy
  Group? _foundGroup;
  
  // ID thành viên mà người dùng chọn (chính là họ)
  String? _selectedMemberId;

  // --- LOGIC GIẢ LẬP API ---

  // Giả lập API kiểm tra mã nhóm
  Future<void> _verifyGroupCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã nhóm')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Giả lập delay mạng 1.5 giây
    await Future.delayed(const Duration(milliseconds: 1500));

    // Mock dữ liệu trả về (Giả sử mã đúng là '123456')
    if (code == '123456') {
      setState(() {
        _foundGroup = Group(
          id: 'g01',
          name: 'Team Dự Án Business Analyst',
          number: 4,
          members: [
            "Hiển", "Trọng", "Đạt"
          ],
        );
        _currentStep = 1; // Chuyển sang bước 2
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy nhóm với mã này.')),
        );
      }
    }
  }

  // Xử lý xác nhận tham gia
  void _confirmJoin() {
    if (_selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn tên của bạn trong danh sách.')),
      );
      return;
    }

    // Logic gọi API join nhóm thật ở đây...
    
    // Sau khi thành công, back về màn danh sách và trả về kết quả
    Navigator.pop(context, true); 
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã tham gia nhóm ${_foundGroup?.name} thành công!')),
    );
  }

  // --- GIAO DIỆN ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tham gia nhóm'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Nếu đang ở bước 2 thì quay lại bước 1, nếu bước 1 thì thoát màn hình
            if (_currentStep == 1) {
              setState(() {
                _currentStep = 0;
                _foundGroup = null;
                _selectedMemberId = null;
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Thanh tiến trình đơn giản
              _buildProgressBar(),
              const SizedBox(height: 24),
              
              // Nội dung chính thay đổi theo bước
              Expanded(
                child: _currentStep == 0 ? _buildStep1InputCode() : _buildStep2SelectMember(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget hiển thị thanh tiến trình
  Widget _buildProgressBar() {
    return Row(
      children: [
        Expanded(
            child: Container(
          height: 4,
          color: Colors.blue,
        )),
        const SizedBox(width: 8),
        Expanded(
            child: Container(
          height: 4,
          color: _currentStep == 1 ? Colors.blue : Colors.grey[300],
        )),
      ],
    );
  }

  // BƯỚC 1: NHẬP MÃ
  Widget _buildStep1InputCode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Nhập mã nhóm',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Vui lòng nhập mã do quản trị viên nhóm cung cấp.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Mã nhóm',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.group_add),
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyGroupCode,
            child: _isLoading
                ? const SizedBox(
                    width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                : const Text('Tiếp tục'),
          ),
        ),
      ],
    );
  }

  // BƯỚC 2: CHỌN THÀNH VIÊN
  Widget _buildStep2SelectMember() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Thông tin nhóm tìm thấy
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 40),
              const SizedBox(height: 8),
              Text(
                _foundGroup?.name ?? '',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              Text(
                'Mã: ${_foundGroup?.id}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Bạn là ai trong danh sách này?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        
        // Danh sách thành viên để chọn
        Expanded(
          child: ListView.separated(
            itemCount: _foundGroup?.members.length ?? 0,
            separatorBuilder: (ctx, index) => const Divider(),
            itemBuilder: (context, index) {
              final member = _foundGroup!.members[index];
              final isSelected = _selectedMemberId == member;

              return ListTile(
                onTap: () {
                  setState(() {
                    _selectedMemberId = member;
                  });
                },
                
                title: Text(
                  member,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue : Colors.black,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.radio_button_checked, color: Colors.blue)
                    : const Icon(Icons.radio_button_off, color: Colors.grey),
                tileColor: isSelected ? Colors.blue.withOpacity(0.05) : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              );
            },
          ),
        ),
        
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _confirmJoin,
            child: const Text('Xác nhận tham gia'),
          ),
        ),
      ],
    );
  }
}