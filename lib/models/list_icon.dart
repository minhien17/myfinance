import 'package:flutter/material.dart';
import 'package:my_finance/models/icon.dart';

List<ItemIcon> ListIcon = [
  ItemIcon(
      img: Image.asset(
        'assets/icons/home.png',
        height: 30,
        width: 30,
      ),
      title: 'home',
      description: "Thuê nhà"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/food.png',
        height: 30,
        width: 30,
      ),
      title: 'food',
      description: "Ăn uống"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/donation.png',
        height: 30,
        width: 30,
      ),
      title: 'donation',
      description: "Quyên góp"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/education.png',
        height: 30,
        width: 30,
      ),
      title: 'education',
      description: "Giáo dục"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/entertain.png',
        height: 30,
        width: 30,
      ),
      title: 'entertainment',
      description: "Vui chơi"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/family.png',
        height: 30,
        width: 30,
      ),
      title: 'family',
      description: "Gia đình"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/houseware.png',
        height: 30,
        width: 30,
      ),
      title: 'houseware',
      description: "Đồ gia dụng"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/transportation.png',
        height: 30,
        width: 30,
      ),
      title: 'transportation',
      description: "Di chuyển"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/other.png',
        height: 30,
        width: 30,
      ),
      title: 'other',
      description: "Chi phí khác"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/ic_launcher.png',
        height: 30,
        width: 30,
      ),
      title: 'income',
      description: "Thu nhập"),
  ItemIcon(
      img: const Icon(Icons.shopping_bag, size: 30, color: Colors.orange),
      title: 'shopping',
      description: "Mua sắm"),
  ItemIcon(
      img: const Icon(Icons.local_hospital, size: 30, color: Colors.red),
      title: 'health',
      description: "Sức khỏe"),
  ItemIcon(
      img: const Icon(Icons.water_drop, size: 30, color: Colors.blue),
      title: 'utilities',
      description: "Tiện ích"),
  ItemIcon(
      img: const Icon(Icons.person, size: 30, color: Colors.purple),
      title: 'personal',
      description: "Cá nhân"),
  ItemIcon(
      img: const Icon(Icons.trending_up, size: 30, color: Colors.green),
      title: 'investment',
      description: "Đầu tư"),
  ItemIcon(
      img: const Icon(Icons.flight, size: 30, color: Colors.teal),
      title: 'travel',
      description: "Du lịch"),
];

// trả về description theo title
String? titleOf(String type) {
  for (int i = 0; i < ListIcon.length; i++) {
    if (ListIcon[i].title == type) {
      return ListIcon[i].description;
    }
  }
  return "Còn lại";
}

List<ItemIcon> ListIconGroup = [
  ItemIcon(
      img: Image.asset(
        'assets/icons/home.png',
        height: 30,
        width: 30,
      ),
      title: 'home',
      description: "Thuê nhà"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/food.png',
        height: 30,
        width: 30,
      ),
      title: 'food',
      description: "Ăn uống"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/houseware.png',
        height: 30,
        width: 30,
      ),
      title: 'houseware',
      description: "Đồ gia dụng"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/entertain.png',
        height: 30,
        width: 30,
      ),
      title: 'entertainment',
      description: "Vui chơi"),
  
  ItemIcon(
      img: Image.asset(
        'assets/icons/other.png',
        height: 30,
        width: 30,
      ),
      title: 'other',
      description: "Chi phí khác"),
];