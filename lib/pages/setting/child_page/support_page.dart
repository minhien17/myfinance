import 'package:flutter/material.dart';

class SupportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Support'),
      ),
      body: Center(
        child: Text(
          'Đây là Trang Hỗ Trợ (Support)',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}



