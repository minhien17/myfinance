import 'package:flutter/material.dart';

class ChangeUsernamePage extends StatefulWidget {
  final String currentUsername; // Nhận username hiện tại từ trang trước

  const ChangeUsernamePage({Key? key, required this.currentUsername})
      : super(key: key);

  @override
  _ChangeUsernamePageState createState() => _ChangeUsernamePageState();
}

class _ChangeUsernamePageState extends State<ChangeUsernamePage> {
  final TextEditingController _newUsernameController = TextEditingController();

  @override
  void dispose() {
    _newUsernameController.dispose();
    super.dispose();
  }

  void _changeUsername() {
    final newUsername = _newUsernameController.text.trim();

    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your new username')),
      );
      return;
    }

    // Gọi API đổi username tại đây
    print('Changing username from "${widget.currentUsername}" to "$newUsername"');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1️⃣ AppBar
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Change username'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),

      // 2️⃣ Nội dung
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hiển thị username hiện tại (read-only)
            Text(
              'Current username: ${widget.currentUsername}',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 20),

            // Trường nhập username mới
            TextFormField(
              controller: _newUsernameController,
              decoration: const InputDecoration(
                labelText: 'New username',
                border: UnderlineInputBorder(),
              ),
            ),

            const SizedBox(height: 40),

            // Nút "CHANGE USERNAME"
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _changeUsername,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const Text(
                  'CHANGE USERNAME',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
