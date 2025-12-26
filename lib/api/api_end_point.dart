class ApiEndpoint {
  // host wifi
  static String HOST = "10.241.110.56"; // mạng dữ liệu

  // đổi mạng wifi là phải thay đổi host - vì cái ip address là ăn theo mạng nữa.
  // ipconfig, Ipv4 address

  // 🔷 Transaction Service (Port 3001)
  static String TRANSACTION_SERVICE = "$HOST:3001";

  // 🔶 Group Service (Port 3004)
  static String GROUP_SERVICE = "$HOST:3004";

  // Legacy DOMAIN for backward compatibility
  static String DOMAIN = "$HOST:3001";

  static String transacions = "$DOMAIN/transactions";

  // login, signup
  static String login = "$DOMAIN/users/login";
  static String signup = "$DOMAIN/users/signup";

  // end point user
  static String userInfor = "$DOMAIN/users/infor";
  static String productYouLike = "$DOMAIN/users/favourite";
  static String userCart = "$DOMAIN/users/cart";
  static String updateUser = "$DOMAIN/users/update";
  static String updateUserPassword = "$DOMAIN/users/changepw";
  static String adress = "$DOMAIN/users/address";
  static String orders = "$DOMAIN/users/ordered_products";
  static String orderAdd = "$DOMAIN/users/ordered_product";
  // end point product
  static String product = "$DOMAIN/products";
  static String myproduct = "$DOMAIN/products/myproduct";
  static String review = "$DOMAIN/products/review";
  static String upload = "$DOMAIN/products/upload";

  // end point discovery
  static String discovery = "$DOMAIN/recommendation/recommend";
}
