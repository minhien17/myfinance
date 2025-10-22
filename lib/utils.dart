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

  static String formatToDay(DateTime date) {
    String s = DateFormat("dd/MM/yyyy").format(date);

    return s;
  }

  static String formatToMonthYear(DateTime date) {
    String s = DateFormat("MM").format(date);
    s += " ${date.year}";
    return s;
  }
}
