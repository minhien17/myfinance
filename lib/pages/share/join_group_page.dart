import 'package:flutter/material.dart';
import 'package:my_finance/models/group_model.dart';
import 'package:my_finance/models/member_model.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/pages/share/child_page/transation_group_page.dart';

// 2. Màn hình tham gia nhóm
class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  // Trạng thái hiện tại: 0 = Nhập mã, 1 = Nhập tên
  int _currentStep = 0;
  bool _isLoading = false;

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  // Dữ liệu nhóm sau khi tìm thấy
  Group? _foundGroup;

  // --- LOGIC GIẢ LẬP API ---

  // Bước 1: Kiểm tra mã nhóm
  Future<void> _verifyGroupCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã nhóm')),
      );
      return;
    }

    setState(() => _isLoading = true);

    ApiUtil.getInstance()!.get(
      url: "http://localhost:3004/join/$code",
      onSuccess: (response) {
        setState(() => _isLoading = false);

        try {
          final item = response.data;

          List<Member> allMembers = [];
          int joinedCount = 0;

          if (item["members"] != null) {
            for (var m in item["members"]) {
              final member = Member.fromJson(m is Map ? Map<String, dynamic>.from(m) : {});
              allMembers.add(member);

              if (member.joined) {
                joinedCount++;
              }
            }
          }

          final group = Group(
            id: (item["id"] ?? item["groupId"] ?? "").toString(),
            name: (item["name"] ?? "No Name").toString(),
            code: (item["code"] ?? "").toString(),
            number: joinedCount,
            totalMembers: allMembers.length,
            members: allMembers
          );

          setState(() {
            _foundGroup = group;
            _currentStep = 1; // Chuyển sang bước nhập tên
          });

        } catch (e) {
          print("Error parsing join response: $e");
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Lỗi xử lý dữ liệu nhóm')),
          );
        }
      },
      onError: (error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Lỗi kiểm tra mã: $error')),
        );
      },
    );
  }

  // Bước 2: Xác nhận tham gia
  void _confirmJoin() {
    final memberName = _nameController.text.trim();

    if (memberName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên của bạn')),
      );
      return;
    }

    if (_foundGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin nhóm')),
      );
      return;
    }

    setState(() => _isLoading = true);

    ApiUtil.getInstance()!.post(
      url: "http://localhost:3004/join",
      body: {
        "groupCode": _foundGroup!.code,
        "memberName": memberName
      },
      onSuccess: (response) {
        setState(() => _isLoading = false);

        // Chuyển sang trang chi tiết nhóm
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionGroupPage(
              group: _foundGroup!,
              joinedMemberName: memberName,
            ),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tham gia nhóm ${_foundGroup?.name} thành công!')),
        );
      },
      onError: (error) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Lỗi tham gia: $error')),
        );
      },
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
                _nameController.clear();
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
                child: _currentStep == 0 ? _buildStep1InputCode() : _buildStep2InputName(),
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

  // BƯỚC 2: NHẬP TÊN
  Widget _buildStep2InputName() {
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
                'Mã: ${_foundGroup?.code}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Nhập tên của bạn',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tên này sẽ được hiển thị cho các thành viên khác trong nhóm.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Tên của bạn',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const Spacer(),
        SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _confirmJoin,
            child: _isLoading
                ? const SizedBox(
                    width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                : const Text('Tham gia nhóm'),
          ),
        ),
      ],
    );
  }
}