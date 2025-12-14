import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Về chúng tôi'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER: Logo và Tên App
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Placeholder Logo (Bạn có thể thay bằng Image.asset)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Image.asset(
                            "assets/icons/ic_launcher.png",
                            height: 60,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'My Finance',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Quản lý tài chính thông minh',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 2. BODY: Nội dung chính
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Tính năng
                  _buildSectionTitle(context, 'Tính năng nổi bật'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        _buildFeatureTile(
                          icon: Icons.person_outline,
                          title: 'Quản lý chi tiêu cá nhân',
                          subtitle: 'Theo dõi dòng tiền vào ra chi tiết',
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _buildFeatureTile(
                          icon: Icons.groups_outlined,
                          title: 'Quản lý quỹ nhóm',
                          subtitle: 'Tính toán và chia tiền tự động',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Section: Đội ngũ
                  _buildSectionTitle(context, 'Thiết kế và phát triển'),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildMemberRow('Đoàn Minh Hiển', 'Developer'),
                          const SizedBox(height: 12),
                          _buildMemberRow('Phùng Minh Hiếu', 'Developer'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 3. FOOTER
            const Text(
              'Phiên bản 1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            const Text(
              '© 2025 My Finance Team. All rights reserved.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Widget con: Tiêu đề mục
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  // Widget con: Dòng tính năng
  Widget _buildFeatureTile({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
    );
  }

  // Widget con: Dòng thành viên
  Widget _buildMemberRow(String name, String role) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.2),
          child: Text(
            name.split(' ').last[0], // Lấy chữ cái đầu của tên
            style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Text(role, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ],
    );
  }
}