class ApiEndpoint {
  // ============================================
  // 🌐 HOST CONFIGURATION
  // ============================================
  // Đổi mạng wifi là phải thay đổi host - vì cái ip address là ăn theo mạng nữa.
  // ipconfig, Ipv4 address

  // 🔹 Chọn 1 trong 3 HOST bên dưới:
  static const String HOST_LOCAL = "localhost";           // Dùng khi chạy trên máy local
  static const String HOST_WIFI = "10.43.157.56";        // Dùng khi chạy trên thiết bị thật qua WiFi

  // 🔹 Chuyển đổi HOST tại đây:
  static String HOST = HOST_LOCAL;  // ← Đổi thành HOST_WIFI khi cần test trên thiết bị thật

  // ============================================
  // 🚪 GATEWAY MODE (Kong)
  // ============================================
  // true = Gọi API qua Kong Gateway (tất cả request đi qua 1 cổng)
  // false = Gọi trực tiếp đến từng service (development mode)
  static bool useKongGateway = false;  // ← Đổi thành true khi dùng Kong

  // ============================================
  // 🔧 SERVICE PORTS
  // ============================================
  static const String PORT_TRANSACTION = "3001";
  static const String PORT_AUTH = "3002";
  static const String PORT_STATISTICS = "3003";
  static const String PORT_GROUP = "3004";
  static const String PORT_GATEWAY = "8000";

  // ============================================
  // 🔷 BASE URLS
  // ============================================
  // Kong Gateway base URL
  static String get kongGateway => "http://$HOST:$PORT_GATEWAY";

  // Direct service URLs (không qua Kong)
  static String get _directTransactionService => "http://$HOST:$PORT_TRANSACTION";
  static String get _directAuthService => "http://$HOST:$PORT_AUTH";
  static String get _directStatisticsService => "http://$HOST:$PORT_STATISTICS";
  static String get _directGroupService => "http://$HOST:$PORT_GROUP";

  // Kong Gateway URLs (qua Kong)
  static String get _kongAuthService => "$kongGateway/api/auth";
  static String get _kongTransactionService => "$kongGateway/api/transactions";
  static String get _kongAccountService => "$kongGateway/api/account";
  static String get _kongStatisticsService => "$kongGateway/api/reports";
  static String get _kongGroupService => "$kongGateway/api/groups";
  static String get _kongGroupExpenseService => "$kongGateway/api/group-expenses";

  // Service URLs (tự động chọn theo useKongGateway)
  static String get transactionService => useKongGateway ? _kongTransactionService : _directTransactionService;
  static String get authService => useKongGateway ? _kongAuthService : _directAuthService;
  static String get statisticsService => useKongGateway ? _kongStatisticsService : _directStatisticsService;
  static String get groupService => useKongGateway ? _kongGroupService : _directGroupService;
  static String get groupExpenseService => useKongGateway ? _kongGroupExpenseService : _directTransactionService;

  // Legacy DOMAIN for backward compatibility
  static String get DOMAIN => transactionService;

  // ============================================
  // 🔐 AUTHENTICATION ENDPOINTS
  // Kong: /api/auth/* -> auth-service:3002/*
  // ============================================
  static String get authLogin => "$authService/auth/login";
  static String get authRegister => "$authService/auth/register";
  static String get authUsersSearch => "$authService/auth/users/search";

  // ============================================
  // 💰 TRANSACTION ENDPOINTS
  // Kong: /api/transactions/* -> transaction-service:3001/*
  // ============================================
  // Base transaction
  static String get transactions => "$transactionService/";
  static String transactionById(String id) => "$transactionService/$id";

  // Account
  static String get allexpense => "$transactionService/allexpense";
  static String get accountBalance => useKongGateway
      ? "$_kongAccountService/balance"
      : "$_directTransactionService/account/balance";

  // Time-based
  static String get months => "$transactionService/months";

  // Analysis
  static String get analyzeText => "$transactionService/analyze-and-save";  // Chỉ phân tích, không lưu
  static String get analyzeAndSave => analyzeText;  // Alias cho backward compatibility
  static String get saveAnalyzedTransactions => "$transactionService/save-analyzed-transactions";

  // ============================================
  // 📊 STATISTICS/REPORTS ENDPOINTS
  // Kong: /api/reports/* -> report-service:3003/*
  // ============================================
  static String get statsLine => "$statisticsService/stats/line";
  static String get transactionsSummary => "$statisticsService/transactions/summary";

  // ============================================
  // 👥 GROUP ENDPOINTS
  // Kong: /api/groups/* -> group-service:3004/*
  // ============================================
  // Base group
  static String get groupCreate => "$groupService/";
  static String get groupMy => "$groupService/my";
  static String get groupJoin => "$groupService/join";
  static String groupJoinByCode(String code) => "$groupService/join/$code";

  // Group-specific operations
  static String groupById(String groupId) => "$groupService/$groupId";
  static String groupMembers(String groupId) => "$groupService/$groupId/members";
  static String groupLeave(String groupId) => "$groupService/$groupId/leave";
  static String groupTransferOwnership(String groupId) => "$groupService/$groupId/transfer-ownership";
  static String groupMyMemberId(String groupId) => "$groupService/$groupId/my-member-id";

  // Member operations
  static String memberUserId(String memberId) => "$groupService/members/$memberId/user-id";
  static String groupRemoveMember(String groupId, String memberId) => "$groupService/$groupId/members/$memberId";

  // ============================================
  // 📨 GROUP INVITATION ENDPOINTS
  // ============================================
  // Invite user to group: POST /:groupId/invitations
  static String groupInvite(String groupId) => "$groupService/$groupId/invitations";
  // Get pending invitations of a group: GET /:groupId/invitations
  static String groupInvitations(String groupId) => "$groupService/$groupId/invitations";
  // Get my pending invitations: GET /invitations/my
  static String get groupInvitationsMy => "$groupService/invitations/my";
  // Accept invitation: POST /invitations/:id/accept
  static String groupInvitationAccept(String invitationId) => "$groupService/invitations/$invitationId/accept";
  // Reject invitation: POST /invitations/:id/reject
  static String groupInvitationReject(String invitationId) => "$groupService/invitations/$invitationId/reject";
  // Cancel invitation: DELETE /:groupId/invitations/:id
  static String groupInvitationCancel(String groupId, String invitationId) => "$groupService/$groupId/invitations/$invitationId";

  // ============================================
  // 💸 GROUP EXPENSE ENDPOINTS
  // Kong: /api/group-expenses/:gId/expenses/* -> transaction-service:3001/groups/:gId/expenses/*
  // ============================================
  static String groupExpenses(String groupId) {
    if (useKongGateway) {
      return "$_kongGroupExpenseService/$groupId/expenses";
    }
    return "$_directTransactionService/groups/$groupId/expenses";
  }

  static String groupExpenseMyDebts(String groupId) {
    if (useKongGateway) {
      return "$_kongGroupExpenseService/$groupId/expenses/my-debts";
    }
    return "$_directTransactionService/groups/$groupId/expenses/my-debts";
  }

  static String groupExpenseOwedToMe(String groupId) {
    if (useKongGateway) {
      return "$_kongGroupExpenseService/$groupId/expenses/owed-to-me";
    }
    return "$_directTransactionService/groups/$groupId/expenses/owed-to-me";
  }

  static String groupExpenseMarkPaid(String groupId) {
    if (useKongGateway) {
      return "$_kongGroupExpenseService/$groupId/expenses/mark-paid";
    }
    return "$_directTransactionService/groups/$groupId/expenses/mark-paid";
  }

  static String groupExpensePaymentHistory(String groupId) {
    if (useKongGateway) {
      return "$_kongGroupExpenseService/$groupId/expenses/payment-history";
    }
    return "$_directTransactionService/groups/$groupId/expenses/payment-history";
  }

  // My expenses in group: GET /:groupId/expenses/my-expenses
  static String groupExpenseMyExpenses(String groupId) {
    if (useKongGateway) {
      return "$_kongGroupExpenseService/$groupId/expenses/my-expenses";
    }
    return "$_directTransactionService/groups/$groupId/expenses/my-expenses";
  }

  static String groupBalances(String groupId) {
    if (useKongGateway) {
      return "$_kongGroupExpenseService/$groupId/balances";
    }
    return "$_directTransactionService/groups/$groupId/balances";
  }

  // Upload payment proof: POST /:groupId/expenses/upload-proof
  static String groupExpenseUploadProof(String groupId) {
    if (useKongGateway) {
      return "$_kongGroupExpenseService/$groupId/expenses/upload-proof";
    }
    return "$_directTransactionService/groups/$groupId/expenses/upload-proof";
  }

  // Get payment proof: GET /:groupId/expenses/shares/:shareId/proof
  static String groupExpenseGetProof(String groupId, String shareId) {
    if (useKongGateway) {
      return "$_kongGroupExpenseService/$groupId/expenses/shares/$shareId/proof";
    }
    return "$_directTransactionService/groups/$groupId/expenses/shares/$shareId/proof";
  }

  /// Convert relative path (e.g. "/uploads/proofs/xxx.jpg") to full URL
  /// Dùng để hiển thị ảnh từ server
  static String getFullImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    // Nếu đã là full URL thì trả về nguyên
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    // Ghép với transaction service URL (nơi lưu ảnh)
    return "$_directTransactionService$relativePath";
  }

  // ============================================
  // 📡 SSE (Server-Sent Events) ENDPOINTS
  // Real-time updates for groups and expenses
  // ============================================
  // Group SSE (group-service:3004)
  static String groupSseEvents(String groupId) => "$_directGroupService/sse/$groupId/events";
  static String get userGroupsSseEvents => "$_directGroupService/sse/user/events";

  // Expense SSE (transaction-service:3001)
  static String groupExpenseSseEvents(String groupId) => "$_directTransactionService/groups/$groupId/expenses/sse/events";
  static String get userExpensesSseEvents => "$_directTransactionService/expenses/sse/user/events";

  // ============================================
  // 🔗 LEGACY ENDPOINTS (for backward compatibility)
  // ============================================
  static String get transacions => "$DOMAIN/transactions";

  // login, signup (legacy)
  static String get login => "$DOMAIN/users/login";
  static String get signup => "$DOMAIN/users/signup";

  // end point user (legacy)
  static String get userInfor => "$DOMAIN/users/infor";
  static String get productYouLike => "$DOMAIN/users/favourite";
  static String get userCart => "$DOMAIN/users/cart";
  static String get updateUser => "$DOMAIN/users/update";
  static String get updateUserPassword => "$DOMAIN/users/changepw";
  static String get adress => "$DOMAIN/users/address";
  static String get orders => "$DOMAIN/users/ordered_products";
  static String get orderAdd => "$DOMAIN/users/ordered_product";

  // end point product (legacy)
  static String get product => "$DOMAIN/products";
  static String get myproduct => "$DOMAIN/products/myproduct";
  static String get review => "$DOMAIN/products/review";
  static String get upload => "$DOMAIN/products/upload";

  // end point discovery (legacy)
  static String get discovery => "$DOMAIN/recommendation/recommend";
}
