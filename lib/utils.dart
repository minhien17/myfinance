import 'package:intl/intl.dart';

class Common {
  static String formatNumber(String s) {
    final number = double.tryParse(s.replaceAll(',', ''));
    if (number == null) {
      return s; // Trả về chuỗi gốc nếu không thể chuyển đổi
    }
    final formatter =
        NumberFormat('#,##0'); // Định dạng có dấu phẩy mỗi hàng nghìn
    return formatter.format(number);
  }

  static String formatToMonthYear(DateTime date) {
    String s = DateFormat("MM").format(date);
    s += " ${date.year}";
    return s;
  }

  static String formatToDay(DateTime date) {
    String s = DateFormat("dd/MM/yyyy").format(date);
    return s;
  }

  static double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }
}
