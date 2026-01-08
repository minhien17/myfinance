import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:my_finance/api/api_end_point.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // 🔌 Socket connections cho 2 services
  IO.Socket? _groupSocket;      // Group Service - port 3004
  IO.Socket? _expenseSocket;    // Transaction Service - port 3001

  bool _isGroupConnected = false;
  bool _isExpenseConnected = false;
  String? _currentGroupId;

  String? _currentUserId;

  // Callbacks cho các events
  Function(Map<String, dynamic>)? onMemberJoined;
  Function(Map<String, dynamic>)? onMemberLeft;
  Function(Map<String, dynamic>)? onMemberAdded;
  Function(Map<String, dynamic>)? onMemberRemoved;
  Function(Map<String, dynamic>)? onOwnershipTransferred;
  Function(Map<String, dynamic>)? onGroupDeleted;
  Function(Map<String, dynamic>)? onExpenseCreated;
  Function(Map<String, dynamic>)? onShareMarkedPaid;
  // Callback khi user được thêm vào nhóm mới
  Function(Map<String, dynamic>)? onAddedToGroup;
  // Callbacks cho invitation system
  Function(Map<String, dynamic>)? onGroupInvitation;
  Function(Map<String, dynamic>)? onInvitationCancelled;
  Function(Map<String, dynamic>)? onInvitationAccepted;
  Function(Map<String, dynamic>)? onInvitationRejected;

  /// Kết nối WebSocket đến cả 2 services
  void connect({String? token}) {
    _connectGroupService(token: token);
    _connectExpenseService(token: token);
  }

  /// Kết nối đến Group Service (ws://localhost:3004/groups)
  void _connectGroupService({String? token}) {
    if (_isGroupConnected && _groupSocket != null) return;

    final groupUrl = 'http://${ApiEndpoint.HOST}:${ApiEndpoint.PORT_GROUP}';

    _groupSocket = IO.io(
      '$groupUrl/groups', // namespace /groups
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setExtraHeaders(token != null ? {'Authorization': 'Bearer $token'} : {})
          .build(),
    );

    _groupSocket!.onConnect((_) {
      print('🔌 WebSocket Group Service connected: $groupUrl/groups');
      _isGroupConnected = true;

      // Rejoin room nếu đã có groupId trước đó
      if (_currentGroupId != null) {
        _joinGroupRoomInternal(_currentGroupId!);
      }
      // Rejoin user room nếu đã có userId trước đó
      if (_currentUserId != null) {
        _joinUserRoomInternal(_currentUserId!);
      }
    });

    _groupSocket!.onDisconnect((_) {
      print('🔌 WebSocket Group Service disconnected');
      _isGroupConnected = false;
    });

    _groupSocket!.onConnectError((error) {
      print('❌ WebSocket Group Service connection error: $error');
    });

    _groupSocket!.onError((error) {
      print('❌ WebSocket Group Service error: $error');
    });

    // Đăng ký lắng nghe các GROUP EVENTS
    _registerGroupEventListeners();
  }

  /// Kết nối đến Transaction/Expense Service (ws://localhost:3001/groups)
  void _connectExpenseService({String? token}) {
    if (_isExpenseConnected && _expenseSocket != null) return;

    final expenseUrl = 'http://${ApiEndpoint.HOST}:${ApiEndpoint.PORT_TRANSACTION}';

    _expenseSocket = IO.io(
      '$expenseUrl/groups', // namespace /groups
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setExtraHeaders(token != null ? {'Authorization': 'Bearer $token'} : {})
          .build(),
    );

    _expenseSocket!.onConnect((_) {
      print('🔌 WebSocket Expense Service connected: $expenseUrl/groups');
      _isExpenseConnected = true;

      // Rejoin room nếu đã có groupId trước đó
      if (_currentGroupId != null) {
        _joinExpenseRoomInternal(_currentGroupId!);
      }
    });

    _expenseSocket!.onDisconnect((_) {
      print('🔌 WebSocket Expense Service disconnected');
      _isExpenseConnected = false;
    });

    _expenseSocket!.onConnectError((error) {
      print('❌ WebSocket Expense Service connection error: $error');
    });

    _expenseSocket!.onError((error) {
      print('❌ WebSocket Expense Service error: $error');
    });

    // Đăng ký lắng nghe các EXPENSE EVENTS
    _registerExpenseEventListeners();
  }

  void _registerGroupEventListeners() {
    if (_groupSocket == null) return;

    // ========== GROUP EVENTS (từ Group Service - port 3004) ==========

    _groupSocket!.on('group:member_joined', (data) {
      print('🔔 [Group] Member joined: $data');
      onMemberJoined?.call(_parseData(data));
    });

    _groupSocket!.on('group:member_left', (data) {
      print('🔔 [Group] Member left: $data');
      onMemberLeft?.call(_parseData(data));
    });

    _groupSocket!.on('group:member_added', (data) {
      print('🔔 [Group] Member added: $data');
      onMemberAdded?.call(_parseData(data));
    });

    _groupSocket!.on('group:member_removed', (data) {
      print('🔔 [Group] Member removed: $data');
      onMemberRemoved?.call(_parseData(data));
    });

    _groupSocket!.on('group:ownership_transferred', (data) {
      print('🔔 [Group] Ownership transferred: $data');
      onOwnershipTransferred?.call(_parseData(data));
    });

    _groupSocket!.on('group:deleted', (data) {
      print('🔔 [Group] Group deleted: $data');
      onGroupDeleted?.call(_parseData(data));
    });

    // Event khi user được thêm vào nhóm mới
    _groupSocket!.on('user:added_to_group', (data) {
      print('🔔 [User] Added to group: $data');
      onAddedToGroup?.call(_parseData(data));
    });

    // ========== INVITATION EVENTS ==========

    // Khi user nhận được lời mời vào nhóm
    _groupSocket!.on('user:group_invitation', (data) {
      print('🔔 [User] Group invitation: $data');
      onGroupInvitation?.call(_parseData(data));
    });

    // Khi lời mời bị hủy
    _groupSocket!.on('user:invitation_cancelled', (data) {
      print('🔔 [User] Invitation cancelled: $data');
      onInvitationCancelled?.call(_parseData(data));
    });

    // Khi lời mời được chấp nhận (gửi cho owner/người mời)
    _groupSocket!.on('invitation:accepted', (data) {
      print('🔔 [Invitation] Accepted: $data');
      onInvitationAccepted?.call(_parseData(data));
    });

    // Khi lời mời bị từ chối (gửi cho owner/người mời)
    _groupSocket!.on('invitation:rejected', (data) {
      print('🔔 [Invitation] Rejected: $data');
      onInvitationRejected?.call(_parseData(data));
    });
  }

  void _registerExpenseEventListeners() {
    if (_expenseSocket == null) return;

    // ========== EXPENSE EVENTS (từ Transaction Service - port 3001) ==========

    _expenseSocket!.on('expense:created', (data) {
      print('🔔 [Expense] Expense created: $data');
      onExpenseCreated?.call(_parseData(data));
    });

    _expenseSocket!.on('expense:share_paid', (data) {
      print('🔔 [Expense] Share marked paid: $data');
      onShareMarkedPaid?.call(_parseData(data));
    });
  }

  Map<String, dynamic> _parseData(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }

  // ========== INTERNAL JOIN METHODS ==========

  void _joinGroupRoomInternal(String groupId, {String? userId}) {
    if (_groupSocket == null || !_isGroupConnected) return;

    _groupSocket!.emit('group:join_room', {
      'groupId': groupId,
      'userId': userId,
    });
    print('📥 Joined group room (Group Service): $groupId');
  }

  void _joinUserRoomInternal(String userId) {
    if (_groupSocket == null || !_isGroupConnected) return;

    _groupSocket!.emit('user:join_room', {
      'userId': userId,
    });
    print('📥 Joined user room (Group Service): $userId');
  }

  void _joinExpenseRoomInternal(String groupId) {
    if (_expenseSocket == null || !_isExpenseConnected) return;

    _expenseSocket!.emit('expense:join_room', {
      'groupId': groupId,
    });
    print('📥 Joined expense room (Expense Service): $groupId');
  }

  // ========== PUBLIC METHODS ==========

  /// Tham gia user room để nhận thông báo khi được thêm vào nhóm mới
  void joinUserRoom(String userId) {
    _currentUserId = userId;

    if (!_isGroupConnected) {
      print('⏳ WebSocket Group Service not connected, will join user room when connected');
      return;
    }

    _joinUserRoomInternal(userId);
  }

  /// Rời khỏi user room
  void leaveUserRoom(String userId) {
    if (_groupSocket != null && _isGroupConnected) {
      _groupSocket!.emit('user:leave_room', {
        'userId': userId,
      });
      print('📤 Left user room (Group Service): $userId');
    }

    if (_currentUserId == userId) {
      _currentUserId = null;
    }
  }

  /// Tham gia room của group để nhận realtime updates (Group Service)
  void joinGroupRoom(String groupId, {String? userId}) {
    _currentGroupId = groupId;

    if (!_isGroupConnected) {
      print('⏳ WebSocket Group Service not connected, will join when connected');
      return;
    }

    _joinGroupRoomInternal(groupId, userId: userId);
  }

  /// Rời khỏi room của group (Group Service)
  void leaveGroupRoom(String groupId) {
    if (_groupSocket != null && _isGroupConnected) {
      _groupSocket!.emit('group:leave_room', {
        'groupId': groupId,
      });
      print('📤 Left group room (Group Service): $groupId');
    }

    if (_currentGroupId == groupId) {
      _currentGroupId = null;
    }
  }

  /// Tham gia room expense để nhận updates về chi tiêu (Transaction Service)
  void joinExpenseRoom(String groupId) {
    _currentGroupId = groupId;

    if (!_isExpenseConnected) {
      print('⏳ WebSocket Expense Service not connected, will join when connected');
      return;
    }

    _joinExpenseRoomInternal(groupId);
  }

  /// Rời khỏi room expense (Transaction Service)
  void leaveExpenseRoom(String groupId) {
    if (_expenseSocket != null && _isExpenseConnected) {
      _expenseSocket!.emit('expense:leave_room', {
        'groupId': groupId,
      });
      print('📤 Left expense room (Expense Service): $groupId');
    }
  }

  /// Ngắt kết nối cả 2 services
  void disconnect() {
    _groupSocket?.disconnect();
    _groupSocket?.dispose();
    _groupSocket = null;
    _isGroupConnected = false;

    _expenseSocket?.disconnect();
    _expenseSocket?.dispose();
    _expenseSocket = null;
    _isExpenseConnected = false;

    _currentGroupId = null;
    _currentUserId = null;
    print('🔌 WebSocket disconnected all services');
  }

  /// Xóa tất cả callbacks
  void clearCallbacks() {
    onMemberJoined = null;
    onMemberLeft = null;
    onMemberAdded = null;
    onMemberRemoved = null;
    onOwnershipTransferred = null;
    onGroupDeleted = null;
    onExpenseCreated = null;
    onShareMarkedPaid = null;
    onAddedToGroup = null;
    // Invitation callbacks
    onGroupInvitation = null;
    onInvitationCancelled = null;
    onInvitationAccepted = null;
    onInvitationRejected = null;
  }

  /// Xóa callbacks liên quan đến group (KHÔNG xóa onAddedToGroup và invitation callbacks)
  /// Dùng cho các page con như ViewMembersPage, TransactionGroupPage
  void clearGroupCallbacks() {
    onMemberJoined = null;
    onMemberLeft = null;
    onMemberAdded = null;
    onMemberRemoved = null;
    onOwnershipTransferred = null;
    onGroupDeleted = null;
    onExpenseCreated = null;
    onShareMarkedPaid = null;
    // KHÔNG xóa onAddedToGroup - để SharePage vẫn nhận được event
    // KHÔNG xóa invitation callbacks - để SharePage vẫn nhận được lời mời
  }

  // ========== GETTERS ==========

  bool get isConnected => _isGroupConnected || _isExpenseConnected;
  bool get isGroupConnected => _isGroupConnected;
  bool get isExpenseConnected => _isExpenseConnected;
  String? get currentGroupId => _currentGroupId;
}
