import 'package:flutter/material.dart';

// Biến toàn cục để giữ context của Dialog đang mở
// LƯU Ý: Đây là cách đơn giản nhưng có thể gặp vấn đề nếu bạn có nhiều Navigator
// Cách an toàn hơn là sử dụng Provider/Riverpod hoặc truyền BuildContext
BuildContext? _loadingDialogContext; 

// --- 1. Hàm Hiển Thị Loading ---
void showLoading(BuildContext context) {
  // Kiểm tra nếu đã có dialog đang mở thì không mở lại
  if (_loadingDialogContext != null) return; 

  showDialog(
    context: context,
    barrierDismissible: false, // Ngăn đóng khi tap ra ngoài
    builder: (BuildContext dialogContext) {
      // Lưu trữ context của dialog
      _loadingDialogContext = dialogContext; 

      return WillPopScope(
        onWillPop: () async => false, // Ngăn đóng bằng nút Back
        child: AlertDialog(
          backgroundColor: Colors.transparent, 
          contentPadding: EdgeInsets.zero,
          elevation: 0,
          content: Center(
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    },
  );
}

// --- 2. Hàm Ẩn Loading ---
void hideLoading() {
  if (_loadingDialogContext != null) {
    // Sử dụng maybePop an toàn hơn pop nếu context không tồn tại
    Navigator.of(_loadingDialogContext!).pop(); 
    _loadingDialogContext = null; // Reset context
  }
}