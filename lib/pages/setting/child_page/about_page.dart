import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About'),
      ),
      body: Center(
        child: Text(
          'Đây là Trang Về Ứng Dụng (About)',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}