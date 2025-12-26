import 'package:flutter/material.dart';
import 'package:my_finance/api/api_util.dart';
import 'package:my_finance/utils.dart';

// Giả định Model Member
class MemberReport {
  final String name;
  final double spent;
  double balance; // Số dư sau tính toán (có thể âm)

  MemberReport({required this.name, required this.spent, this.balance = 0.0});
}

class ViewReportPage extends StatefulWidget {
  final String groupId;
  final String groupName;
  const ViewReportPage({super.key, required this.groupId, this.groupName = 'Trọ'});

  @override
  State<ViewReportPage> createState() => _ViewReportPageState();
}

class _ViewReportPageState extends State<ViewReportPage> {
  List<MemberReport> _members = [];
  double _totalSpent = 0;
  bool _isCalculated = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBalances();
  }

  void _fetchBalances() {
    setState(() => _loading = true);
    ApiUtil.getInstance()!.get(
      url: "http://localhost:3001/groups/${widget.groupId}/balances",
      onSuccess: (response) {
        if (response.data != null && response.data['balances'] != null) {
          final List balances = response.data['balances'];
          _members = balances.map((b) => MemberReport(
            name: b['memberName'] ?? b['memberId'].toString(),
            spent: 0, // Backend logic for total spent per user is separate, but balance reflects the result
            balance: Common.parseDouble(b['balance'])
          )).toList();
          
          _totalSpent = 0;
          // Note: The /balances endpoint gives net results. 
          // If we want total spent per person, we might need a different endpoint or combine data.
          // For settlement view, net balance is most important.
          
          _isCalculated = true; 
          _loading = false;
          if (mounted) setState(() {});
        }
      },
      onError: (err) {
        print("Fetch balances error: $err");
        if (mounted) setState(() => _loading = false);
      }
    );
  }

  void _calculateSettlement() {
    _fetchBalances(); // Refresh data
  }

  // Định dạng số tiền
  String _formatAmount(double amount) {
    String sign = amount >= 0 ? '' : '-';
    double absAmount = amount.abs();
    
    // Định dạng số có dấu phẩy
    String formatted = absAmount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
      
    return '$sign$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Xem báo cáo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            

            // 1. Tóm tắt Chi tiêu Nhóm
            _buildSummaryCard(),
            
            const SizedBox(height: 20),

            _buildPayCard(),

            // // 2. Nút Tính Toán
            // _buildCalculateButton(),

            // const SizedBox(height: 30),

            // // 3. Kết quả Thanh toán (Chỉ hiển thị khi đã tính toán)
            // if (_isCalculated) _buildSettlementResult(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET CON: Tóm tắt Chi tiêu ---
  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tên nhóm (Trọ)
            Text(
              widget.groupName,
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: Colors.grey[700]
              ),
            ),
            const Divider(height: 20),

            // Tổng chi tiêu
            _buildReportRow('Tổng', _totalSpent, isTotal: true),
            const SizedBox(height: 15),

            // Chi tiêu từng thành viên
            ..._members.map((member) => _buildReportRow(
              member.name, 
              member.spent,
              isTotal: false,
            )).toList(),
          ],
        ),
      ),
    );
  }

    // --- WIDGET CON: Tóm tắt Chi tiêu ---
  Widget _buildPayCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tên nhóm (Trọ)
            Text(
              "Bạn phải trả",
              style: TextStyle(
                fontSize: 22, 
                fontWeight: FontWeight.bold, 
                color: Colors.grey[700]
              ),
            ),
            const Divider(height: 20),

            // Chi tiêu từng thành viên
            _buildReportRow("Đạt", -6667, isTotal: false),
            _buildReportRow("Trọng", 0, isTotal: false)
          ],
        ),
      ),
    );
  }

  // --- WIDGET CON: Hàng Báo cáo (Name | Amount) ---
  Widget _buildReportRow(String label, double amount, {required bool isTotal}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[800],
            ),
          ),
          Text(
            _formatAmount(amount),
            style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? Colors.green[700] : Colors.black, // Tổng chi màu xanh
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET CON: Nút Tính Toán ---
  Widget _buildCalculateButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _calculateSettlement,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isCalculated ? Colors.red[400] : Colors.grey[300], // Màu đỏ khi reset, Xám khi tính
          minimumSize: const Size(150, 45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 2,
        ),
        child: Text(
          _isCalculated ? 'Reset' : 'Calculate',
          style: TextStyle(
            color: _isCalculated ? Colors.white : Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // --- WIDGET CON: Kết quả Thanh toán ---
  Widget _buildSettlementResult() {
    final payees = _members.where((m) => m.balance < 0);
    final receivers = _members.where((m) => m.balance > 0);
    
    // Nếu chưa có ai phải trả/nhận (trường hợp chia tiền hoàn hảo)
    if (payees.isEmpty && receivers.isEmpty) {
        return Center(
            child: Text(
                "Mọi khoản chi đã được cân bằng!", 
                style: TextStyle(fontSize: 16, color: Colors.green[600])
            )
        );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settlement result:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 10),
        
        // Vòng lặp hiển thị kết quả cho từng người
        ..._members.map((member) {
          if (member.balance != 0) {
            String status = member.balance < 0 ? 'You must pay' : 'Must receive';
            Color color = member.balance < 0 ? Colors.red : Colors.green;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        status,
                        style: TextStyle(fontSize: 12, color: color),
                      ),
                    ],
                  ),
                  Text(
                    _formatAmount(member.balance),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink(); // Ẩn người không cần trả/nhận
        }).toList(),
      ],
    );
  }
}