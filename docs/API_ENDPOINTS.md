# 📡 API ENDPOINTS DOCUMENTATION

## Cấu hình Backend Services

```dart
// File: lib/api/api_end_point.dart
HOST = "10.241.110.56"
TRANSACTION_SERVICE = "10.241.110.56:3001"  // 🔷 Transaction Service
GROUP_SERVICE = "10.241.110.56:3004"        // 🔶 Group Service
```

---

## 🔷 TRANSACTION SERVICE (Port 3001)

### 1. Personal Transactions

#### 1.1 Lấy danh sách tháng có dữ liệu
```http
GET http://localhost:3001/months
Headers: Authorization: Bearer {token}
```
**File sử dụng:**
- `lib/pages/transaction/transaction_page.dart:467` - Lấy danh sách tháng có transactions

**Response:**
```json
["12/2025", "11/2025", "10/2025", "09/2025"]
```

**Format:** `"MM/YYYY"`

**Cách xử lý:**
- API trả về List<String> các tháng đã có transactions
- Sort theo năm và tháng tăng dần
- Hiển thị danh sách tháng để user chọn
- Nếu empty → fallback về 13 tháng gần đây (-6 đến +6)

---

#### 1.2 Lấy transactions theo tháng
```http
GET http://localhost:3001/months?month={month}&year={year}
Headers: Authorization: Bearer {token}
```
**File sử dụng:**
- `lib/pages/home/home_page.dart:456` - Tính tổng thu/chi, top 5 chi tiêu
- `lib/pages/transaction/transaction_page.dart:492` - Hiển thị danh sách transactions

**Response:** Giống như 1.1

---

#### 1.3 Tạo transaction mới
```http
POST http://localhost:3001/
Headers: Authorization: Bearer {token}
Body: {
  "amount": 100000,
  "category": "Food",
  "note": "Lunch at restaurant",
  "dateTime": "2025-12-23T10:00:00Z"
}
```
**File sử dụng:**
- `lib/pages/add/add_page.dart:270` - Thêm transaction mới
- `lib/pages/share/child_page/edit_transation_group_page.dart:342` - Thêm transaction từ group expense

**Response:** Transaction object đã tạo

---

#### 1.4 Cập nhật transaction
```http
PATCH http://localhost:3001/{id}
Headers: Authorization: Bearer {token}
Body: { /* partial transaction object */ }
```
**File sử dụng:**
- `lib/pages/add/edit_page.dart:334` - Sửa transaction

**Response:** Updated transaction

---

#### 1.5 Xóa transaction
```http
DELETE http://localhost:3001/{id}
Headers: Authorization: Bearer {token}
```
**File sử dụng:**
- `lib/pages/add/edit_page.dart:386` - Xóa transaction

**Response:**
```json
{ "message": "Deleted" }
```

---

### 2. Account Balance

#### 2.1 Lấy số dư tài khoản
```http
GET http://localhost:3001/account/balance
Headers: Authorization: Bearer {token}
```
**File sử dụng:**
- `lib/pages/home/home_page.dart:444` - Hiển thị số dư trang chủ
- `lib/pages/transaction/transaction_page.dart:117` - Hiển thị số dư trang transaction

**Response:**
```json
{
  "userId": "uuid",
  "balance": 1500000,
  "name": "Main Account"
}
```

---

### 3. Group Expenses

#### 3.1 Tạo group expense
```http
POST http://localhost:3001/groups/{groupId}/expenses
Headers: Authorization: Bearer {token}
Body (Equal Split): {
  "title": "Tiền ăn trưa",
  "amount": 300000,
  "paidByMemberId": "33",
  "splitType": "equal",
  "participantMemberIds": ["33", "34", "35"]
}
```
**File sử dụng:**
- `lib/pages/share/child_page/add_transation_group_page.dart:128` - Thêm chi tiêu nhóm

**Body (Exact Split):**
```json
{
  "title": "Tiền ăn",
  "amount": 300000,
  "paidByMemberId": "33",
  "splitType": "exact",
  "exactSplits": [
    { "memberId": "33", "amount": 100000 },
    { "memberId": "34", "amount": 150000 },
    { "memberId": "35", "amount": 50000 }
  ]
}
```

**Body (Percent Split):**
```json
{
  "title": "Tiền ăn",
  "amount": 300000,
  "paidByMemberId": "33",
  "splitType": "percent",
  "percentSplits": [
    { "memberId": "33", "percent": 40 },
    { "memberId": "34", "percent": 30 },
    { "memberId": "35", "percent": 30 }
  ]
}
```

**Response:**
```json
{
  "id": "uuid",
  "groupId": "uuid",
  "title": "Tiền ăn trưa",
  "amount": 300000,
  "paidByMemberId": "33",
  "splitType": "equal",
  "createdAt": "2025-12-23T10:00:00Z",
  "shares": [
    {
      "id": "uuid",
      "memberId": "33",
      "amount": 100000,
      "isPaid": true,
      "userId": "uuid-bob"
    },
    {
      "id": "uuid",
      "memberId": "34",
      "amount": 100000,
      "isPaid": false,
      "userId": "uuid-alice"
    }
  ]
}
```

---

#### 3.2 Lấy tất cả expenses của group
```http
GET http://localhost:3001/groups/{groupId}/expenses
Headers: Authorization: Bearer {token}
```
**File sử dụng:**
- `lib/pages/share/child_page/transation_group_page.dart:572` - Hiển thị danh sách chi tiêu nhóm

**Response:** Array of expense objects

---

#### 3.3 Xem nợ của tôi ⭐
```http
GET http://localhost:3001/groups/{groupId}/expenses/my-debts
Headers: Authorization: Bearer {token}
```
**File sử dụng:**
- `lib/pages/share/child_page/transation_group_page.dart:56` - Tab "Nợ của tôi"

**Response:**
```json
[
  {
    "shareId": "uuid",
    "expenseId": "uuid",
    "expenseTitle": "Tiền ăn trưa",
    "totalAmount": 300000,
    "myShare": 100000,
    "paidByMemberId": "33",
    "createdAt": "2025-12-23T10:00:00Z",
    "splitType": "equal",
    "isPaid": false
  }
]
```

---

#### 3.4 Xem ai đang nợ tôi ⭐
```http
GET http://localhost:3001/groups/{groupId}/expenses/owed-to-me
Headers: Authorization: Bearer {token}
```
**File sử dụng:**
- `lib/pages/share/child_page/transation_group_page.dart:68` - Tab "Nợ tôi"

**Response:**
```json
[
  {
    "shareId": "uuid",
    "expenseId": "uuid",
    "expenseTitle": "Tiền ăn trưa",
    "totalAmount": 300000,
    "shareAmount": 100000,
    "debtorMemberId": "34",
    "createdAt": "2025-12-23T10:00:00Z",
    "isPaid": false
  }
]
```

---

#### 3.5 Đánh dấu đã trả ⭐
```http
POST http://localhost:3001/groups/{groupId}/expenses/mark-paid
Headers: Authorization: Bearer {token}
Body: {
  "shareId": "uuid-from-owed-to-me"
}
```
**File sử dụng:**
- `lib/pages/share/child_page/transation_group_page.dart:82` - Nút "Đã trả" trong danh sách nợ

**Response:**
```json
{
  "shareId": "uuid",
  "isPaid": true,
  "paidAt": "2025-12-23T15:30:00Z",
  "debtorTransactionId": "uuid",
  "payerTransactionId": "uuid"
}
```

**Side effects:**
- Tạo transaction `-100k` cho debtor
- Tạo transaction `+100k` cho payer
- Update `isPaid=true` trong Share

---

### 4. Group Balances

#### 4.1 Tính toán balances giữa các members
```http
GET http://localhost:3001/groups/{groupId}/balances
Headers: Authorization: Bearer {token}
```
**File sử dụng:**
- `lib/pages/share/child_page/view_report_page.dart:38` - Trang xem báo cáo settlement

**Response:**
```json
{
  "balances": [
    {
      "memberId": "33",
      "memberName": "Bob",
      "balance": 200000,
      "owes": [],
      "owedBy": [
        { "memberId": "34", "amount": 100000 },
        { "memberId": "35", "amount": 100000 }
      ]
    },
    {
      "memberId": "34",
      "memberName": "Alice",
      "balance": -100000,
      "owes": [{ "memberId": "33", "amount": 100000 }],
      "owedBy": []
    }
  ],
  "settlements": [
    { "from": "34", "to": "33", "amount": 100000 },
    { "from": "35", "to": "33", "amount": 100000 }
  ]
}
```

---

## 🔶 GROUP SERVICE (Port 3004)

### 1. Group Management

#### 1.1 Tạo group mới
```http
POST http://localhost:3004/
Headers: Authorization: Bearer {token}
Body: {
  "name": "Family Budget",
  "ownerName": "Bob",
  "memberNames": ["Alice", "Eny"]
}
```
**File sử dụng:**
- `lib/pages/share/create_group_page.dart:139` - Tạo nhóm mới

**Response:**
```json
{
  "id": "uuid",
  "name": "Family Budget",
  "code": "ABC123",
  "createdByUserId": "uuid",
  "isLocked": false,
  "members": [
    {
      "id": 33,
      "name": "Bob",
      "userId": "uuid-bob",
      "joined": true,
      "joinedAt": "2025-12-23T10:00:00Z"
    },
    {
      "id": 34,
      "name": "Alice",
      "userId": null,
      "joined": false,
      "joinedAt": null
    }
  ]
}
```

---

#### 1.2 Lấy thông tin group bằng code
```http
GET http://localhost:3004/join/{code}
```
**File sử dụng:**
- `lib/pages/share/join_group_page.dart:47` - Kiểm tra mã nhóm khi join

**Response:**
```json
{
  "groupId": "uuid",
  "name": "Family Budget",
  "code": "ABC123",
  "isLocked": false,
  "members": [
    {
      "id": 33,
      "name": "Bob",
      "userId": "uuid",
      "joined": true
    },
    {
      "id": 34,
      "name": "Alice",
      "userId": null,
      "joined": false
    }
  ]
}
```

---

#### 1.3 Join group
```http
POST http://localhost:3004/join
Headers: Authorization: Bearer {token}
Body: {
  "groupCode": "ABC123",
  "memberId": "34"
}
```
**File sử dụng:**
- `lib/pages/share/join_group_page.dart:114` - Tham gia nhóm

**Response:**
```json
{
  "groupId": "uuid",
  "memberId": 34,
  "name": "Alice",
  "userId": "uuid",
  "joined": true,
  "joinedAt": "2025-12-23T11:00:00Z"
}
```

---

#### 1.4 Lấy tất cả groups của tôi
```http
GET http://localhost:3004/my
Headers: Authorization: Bearer {token}
```
**File sử dụng:**
- `lib/pages/share/share_page.dart:55` - Hiển thị danh sách nhóm

**Response:**
```json
[
  {
    "id": "uuid",
    "name": "Family Budget",
    "code": "ABC123",
    "memberCount": 3,
    "joinedMemberCount": 2
  }
]
```

---

### 2. Member Queries

#### 2.1 Lấy member ID của tôi
```http
GET http://localhost:3004/{groupId}/my-member-id
Headers: Authorization: Bearer {token}
```
**File sử dụng:** Chưa có (có thể dùng trong tương lai)

**Response:**
```json
{
  "memberId": 33,
  "name": "Bob",
  "joined": true
}
```

---

#### 2.2 Lấy userId từ memberId ⭐
```http
GET http://localhost:3004/members/{memberId}/user-id
```
**File sử dụng:** Chưa có (dùng cho settlement trong tương lai)

**Response:**
```json
{
  "userId": "uuid-or-null"
}
```

---

## 📊 TỔNG HỢP THỐNG KÊ

### Transaction Service (Port 3001)
- **9 endpoints chính**
- **3 endpoints settlement mới:** `my-debts`, `owed-to-me`, `mark-paid`
- **Files sử dụng:** 8 files

### Group Service (Port 3004)
- **6 endpoints**
- **1 endpoint settlement support:** `members/:memberId/user-id`
- **Files sử dụng:** 3 files

---

## 🔥 CÁC THAY ĐỔI ĐÃ THỰC HIỆN

### 1. API Configuration
- ✅ Thêm `TRANSACTION_SERVICE` và `GROUP_SERVICE` vào `api_end_point.dart`
- ✅ Tách biệt rõ ràng 2 services

### 2. Hard-coded Data → API
- ✅ **home_page.dart:** Giữ `fakeTransactions` cho biểu đồ pie chart
- ✅ **edit_transation_group_page.dart:** Thay hard-coded `members` bằng `widget.members` từ Group API
- ✅ **transation_group_page.dart:** Truyền `widget.group.members` vào EditTransactionGroupPage
- ✅ **transaction_page.dart:** Thay hard-coded months (-6 to +6) bằng `GET /months` API
- ✅ **transation_group_page.dart:** Thay hard-coded months bằng `GET /groups/{id}/expenses` API

### 3. Danh sách tháng động từ API
- ✅ **transaction_page.dart:** Gọi `GET /months` để lấy tất cả transactions → parse ra danh sách tháng
- ✅ **transation_group_page.dart:** Gọi `GET /groups/{id}/expenses` → parse ra danh sách tháng
- ✅ Fallback về hard-coded months nếu API lỗi

### 4. Code đã giữ lại (commented)
```dart
// ⚠️ BACKUP: Hard-coded members (giữ lại cho trường hợp cần)
// List<String> members = ["Hiển", "Trọng", "Đạt"];

// ⚠️ Fake data cho biểu đồ pie (giữ lại để hiển thị)
Map<String, dynamic> fakeTransactions = { ... };
```

---

## 🎯 LUỒNG HOẠT ĐỘNG CHÍNH

### A. Personal Transaction Flow
1. User tạo transaction → `POST /` (add_page.dart)
2. View transactions → `GET /months` (transaction_page.dart)
3. Edit transaction → `PATCH /{id}` (edit_page.dart)
4. Delete transaction → `DELETE /{id}` (edit_page.dart)

### B. Group Expense Flow
1. Tạo group → `POST http://localhost:3004/` (create_group_page.dart)
2. Join group → `POST http://localhost:3004/join` (join_group_page.dart)
3. Tạo expense → `POST /groups/{groupId}/expenses` (add_transation_group_page.dart)
4. Xem expenses → `GET /groups/{groupId}/expenses` (transation_group_page.dart)

### C. Settlement Flow ⭐
1. Debtor xem nợ → `GET /groups/{groupId}/expenses/my-debts`
2. Payer xem ai nợ → `GET /groups/{groupId}/expenses/owed-to-me`
3. Payer đánh dấu đã trả → `POST /groups/{groupId}/expenses/mark-paid`
   - Auto tạo transactions cho cả 2 bên
   - Update `isPaid=true`

### D. Balance Report Flow
1. Xem balance → `GET /groups/{groupId}/balances` (view_report_page.dart)
2. Hiển thị settlements cần thực hiện

---

## 🚀 READY FOR PRODUCTION!

Tất cả endpoints đã được tích hợp vào ứng dụng Flutter và sẵn sàng để test end-to-end.
