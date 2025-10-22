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
      description: "Rental"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/food.png',
        height: 30,
        width: 30,
      ),
      title: 'food',
      description: "Food & Drink"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/donation.png',
        height: 30,
        width: 30,
      ),
      title: 'donation',
      description: "Donation & Gift"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/education.png',
        height: 30,
        width: 30,
      ),
      title: 'education',
      description: "Education"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/entertain.png',
        height: 30,
        width: 30,
      ),
      title: 'entertainment',
      description: "Entertainment"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/family.png',
        height: 30,
        width: 30,
      ),
      title: 'family',
      description: "Family & Love"),
  
  ItemIcon(
      img: Image.asset(
        'assets/icons/transportation.png',
        height: 30,
        width: 30,
      ),
      title: 'transportation',
      description: "Transportation"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/other.png',
        height: 30,
        width: 30,
      ),
      title: 'other',
      description: "Other Expense"),
  ItemIcon(
      img: Image.asset(
        'assets/icons/ic_launcher.png',
        height: 30,
        width: 30,
      ),
      title: 'income',
      description: "Income"),
];

// trả về description theo title
String? titleOf(String type) {
  for (int i = 0; i < ListIcon.length; i++) {
    if (ListIcon[i].title == type) {
      return ListIcon[i].description;
    }
  }
  return null;
}
