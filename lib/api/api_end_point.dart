class ApiEndpoint {
  // host wifi

  static String HOST = "192.168.212.56"; // mạng dữ liệu
  //"192.168.1.103"; // FEF

  // đổi mạng wifi là phải thay đổi host
  // ipconfig, Ipv4 address

  static String DOMAIN = "http://$HOST:8000/api";

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
