import 'package:my_finance/utils.dart';

class DebtModel {
  final String shareId;
  final String expenseId;
  final String expenseTitle;
  final double totalAmount;
  final double shareAmount;
  final String? paidByMemberId; // Used for "My Debts"
  final String? paidByName; // Tên người trả tiền
  final String? debtorMemberId; // Used for "Owed to me"
  final String? debtorName; // Tên người nợ
  final bool isPaid;
  final DateTime? createdAt;
  // Payment proof fields
  final String? proofImageUrl;     // URL ảnh chứng minh thanh toán
  final String? proofStatus;       // pending, approved, rejected, null
  final DateTime? proofUploadedAt; // Thời gian upload ảnh

  DebtModel({
    required this.shareId,
    required this.expenseId,
    required this.expenseTitle,
    required this.totalAmount,
    required this.shareAmount,
    this.paidByMemberId,
    this.paidByName,
    this.debtorMemberId,
    this.debtorName,
    required this.isPaid,
    this.createdAt,
    this.proofImageUrl,
    this.proofStatus,
    this.proofUploadedAt,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      shareId: json['shareId']?.toString() ?? '',
      expenseId: json['expenseId']?.toString() ?? '',
      expenseTitle: json['expenseTitle'] ?? '',
      totalAmount: Common.parseDouble(json['totalAmount']),
      shareAmount: Common.parseDouble(json['shareAmount'] ?? json['myShare']),
      paidByMemberId: json['paidByMemberId']?.toString(),
      paidByName: json['paidByMemberName']?.toString(),
      debtorMemberId: json['debtorMemberId']?.toString(),
      debtorName: json['debtorMemberName']?.toString(),
      isPaid: json['isPaid'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      proofImageUrl: json['proofImageUrl']?.toString(),
      proofStatus: json['proofStatus']?.toString(),
      proofUploadedAt: json['proofUploadedAt'] != null
          ? DateTime.tryParse(json['proofUploadedAt'].toString())
          : null,
    );
  }

  /// Kiểm tra xem đã có ảnh chứng minh chưa
  bool get hasProof => proofImageUrl != null && proofImageUrl!.isNotEmpty;

  /// Kiểm tra xem ảnh chứng minh đang chờ duyệt
  bool get isProofPending => proofStatus == 'pending';
}
