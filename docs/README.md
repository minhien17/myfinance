# My Finance App - Tài liệu kiến trúc

## Tổng quan

Ứng dụng quản lý tài chính cá nhân với các chức năng:
- Đăng nhập/Đăng ký
- Xem giao dịch theo tháng
- Thêm/Sửa/Xóa giao dịch
- Thống kê chi tiêu
- Quản lý nhóm chi tiêu

---

## 1. Sơ đồ lớp thực thể (Entity Class Diagram)

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    ENTITY CLASS DIAGRAM                                      │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────┐         ┌─────────────────────────────┐
│          User               │         │     TransactionModel        │
├─────────────────────────────┤         ├─────────────────────────────┤
│ + id: String                │         │ - _id: String?              │
│ + username: String          │ 1     * │ - _amount: double?          │
│ + email: String             │────────>│ - _category: String?        │
│ + role: String              │  owns   │ - _note: String?            │
│ + createdAt: DateTime       │         │ - _dateTime: DateTime?      │
└─────────────────────────────┘         │ - _owner: String?           │
         │                              ├─────────────────────────────┤
         │                              │ + fromJson(Map): void       │
         │ 1                            │ + toJson(): Map             │
         │                              │ + get id: String            │
         ▼ *                            │ + get amount: double        │
┌─────────────────────────────┐         │ + get category: String      │
│         Account             │         │ + get formattedDate: String │
├─────────────────────────────┤         └─────────────────────────────┘
│ + id: String                │                      │
│ + name: String              │                      │ *
│ + balance: int              │                      │ aggregates
├─────────────────────────────┤                      ▼ 1
│ + fromJson(Map): Account    │         ┌─────────────────────────────┐
│ + toJson(): Map             │         │     TopExpenseModel         │
└─────────────────────────────┘         ├─────────────────────────────┤
         │                              │ + category: String          │
         │ 1                            │ + amount: double            │
         │                              │ + color: Color              │
         ▼ *                            └─────────────────────────────┘
┌─────────────────────────────┐
│          Group              │
├─────────────────────────────┤
│ + id: String                │
│ + name: String              │
│ + number: int               │
│ + members: List<String>     │
├─────────────────────────────┤
│ + fromJson(Map): Group      │
│ + toJson(): Map             │
└─────────────────────────────┘
```

---

## 2. Sơ đồ cấu trúc Pages (UI Structure)

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    UI NAVIGATION FLOW                                        │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

                                    ┌─────────────────┐
                                    │   LoadingPage   │
                                    └────────┬────────┘
                                             │
                                    ┌────────▼────────┐
                                    │  Token exists?  │
                                    └────────┬────────┘
                           ┌─────────────────┴─────────────────┐
                           │ NO                                │ YES
                  ┌────────▼────────┐                 ┌────────▼────────┐
                  │   OnboardPage   │                 │    MainPage     │
                  └────────┬────────┘                 └────────┬────────┘
                           │                                   │
              ┌────────────┴────────────┐         ┌────────────┴────────────┬────────────┬────────────┐
              │                         │         │                         │            │            │
     ┌────────▼────────┐      ┌─────────▼───────┐ │                         │            │            │
     │   SignInPage    │◄────►│   SignUpPage    │ │                         │            │            │
     └────────┬────────┘      └─────────────────┘ │                         │            │            │
              │                                   │                         │            │            │
              │ Success                           │                         │            │            │
              └───────────────────────────────────┘                         │            │            │
                                                                            │            │            │
                  ┌─────────────────────────────────────────────────────────┘            │            │
                  │                                                                      │            │
         ┌────────▼────────┐                                                             │            │
         │    HomePage     │                                                             │            │
         │   (Dashboard)   │                                                             │            │
         └─────────────────┘                                                             │            │
                                                                                         │            │
                  ┌──────────────────────────────────────────────────────────────────────┘            │
                  │                                                                                   │
         ┌────────▼────────┐                                                                          │
         │ TransactionPage │                                                                          │
         └────────┬────────┘                                                                          │
                  │                                                                                   │
     ┌────────────┼────────────┐                                                                      │
     │            │            │                                                                      │
┌────▼────┐ ┌─────▼─────┐ ┌────▼────┐                                                                 │
│ AddPage │ │ EditPage  │ │ReportPg │                                                                 │
└─────────┘ └───────────┘ └─────────┘                                                                 │
                                                                                                      │
                  ┌───────────────────────────────────────────────────────────────────────────────────┘
                  │
         ┌────────▼────────┐
         │   SharePage     │
         └────────┬────────┘
                  │
         ┌────────▼────────────────┐
         │  TransactionGroupPage   │
         └────────┬────────────────┘
                  │
     ┌────────────┼────────────────────┐
     │            │                    │
┌────▼─────┐ ┌────▼─────┐ ┌────────────▼──────┐
│  AddTxn  │ │ EditTxn  │ │   ViewReportPage  │
│ GroupPg  │ │ GroupPg  │ │                   │
└──────────┘ └──────────┘ └───────────────────┘
```

---

## 3. Sơ đồ lớp API (API Class Diagram)

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    API CLASS DIAGRAM                                         │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────┐
│            ApiUtil                │
├───────────────────────────────────┤
│ - IS_SHOW_LOG: bool               │
│ - _mInstance: ApiUtil?            │
├───────────────────────────────────┤
│ + getInstance(): ApiUtil?         │
│ + get(url, params, onSuccess,     │
│       onError): Future<void>      │
│ + post(url, body, onSuccess,      │
│        onError): void             │
│ + put(url, body, onSuccess,       │
│       onError): Future<void>      │
│ + patch(url, body, onSuccess,     │
│         onError): Future<void>    │
│ + delete(url, onSuccess,          │
│          onError): void           │
│ - getBaseResponse2(): BaseResponse│
└──────────────┬────────────────────┘
               │ uses
               ▼
┌───────────────────────────────────┐       ┌───────────────────────────────────┐
│      SharedPreferenceUtil         │       │          ApiEndpoint              │
├───────────────────────────────────┤       ├───────────────────────────────────┤
│ + saveToken(String): Future       │       │ + HOST: String                    │
│ + saveUsername(String): Future    │       │ + DOMAIN: String                  │
│ + saveEmail(String): Future       │       │ + transacions: String             │
│ + getToken(): Future<String>      │       │ + login: String                   │
│ + getUsername(): Future<String>   │       │ + signup: String                  │
│ + getEmail(): Future<String>      │       │ + userInfor: String               │
│ + clearToken(): Future<void>      │       └───────────────────────────────────┘
└───────────────────────────────────┘
               │
               │ returns
               ▼
┌───────────────────────────────────┐
│          BaseResponse             │
├───────────────────────────────────┤
│ + message: String?                │
│ + code: int?                      │
│ + data: dynamic                   │
│ + status: int?                    │
│ + errMessage: String?             │
├───────────────────────────────────┤
│ + get isSuccess: bool             │
│ + get isStatusSuccess: bool       │
└───────────────────────────────────┘
```

---

## 4. Sơ đồ tuần tự - Xem giao dịch theo tháng (Sequence Diagram)

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                         SEQUENCE DIAGRAM: XEM GIAO DỊCH THEO THÁNG                           │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

┌──────┐     ┌─────────────────┐     ┌──────────┐     ┌─────────────────┐     ┌─────────────┐
│ User │     │ TransactionPage │     │  ApiUtil │     │SharedPrefUtil   │     │ Backend API │
└──┬───┘     └────────┬────────┘     └────┬─────┘     └────────┬────────┘     └──────┬──────┘
   │                  │                   │                    │                     │
   │  Mở màn hình     │                   │                    │                     │
   │─────────────────>│                   │                    │                     │
   │                  │                   │                    │                     │
   │                  │   initState()     │                    │                     │
   │                  │──────────────────>│                    │                     │
   │                  │                   │                    │                     │
   │                  │                   │                    │                     │
   │  ╔═══════════════╧═══════════════════╧════════════════════╧═════════════════════╧══════╗
   │  ║                           1. GỌI API LẤY DANH SÁCH THÁNG                            ║
   │  ╚═══════════════╤═══════════════════╤════════════════════╤═════════════════════╤══════╝
   │                  │                   │                    │                     │
   │                  │  getListMonth()   │                    │                     │
   │                  │──────────────────>│                    │                     │
   │                  │                   │                    │                     │
   │                  │                   │   getToken()       │                     │
   │                  │                   │───────────────────>│                     │
   │                  │                   │                    │                     │
   │                  │                   │   return JWT Token │                     │
   │                  │                   │<───────────────────│                     │
   │                  │                   │                    │                     │
   │                  │                   │                    │  HTTP GET           │
   │                  │                   │                    │  /months            │
   │                  │                   │                    │  Header:            │
   │                  │                   │                    │  Authorization:     │
   │                  │                   │                    │  Bearer <JWT>       │
   │                  │                   │────────────────────────────────────────>│
   │                  │                   │                    │                     │
   │                  │                   │                    │    Kong Gateway     │
   │                  │                   │                    │    verify JWT       │
   │                  │                   │                    │    add x-user-id    │
   │                  │                   │                    │                     │
   │                  │                   │   Response 200 OK  │                     │
   │                  │                   │   ["10/2025",      │                     │
   │                  │                   │    "11/2025",      │                     │
   │                  │                   │    "12/2025"]      │                     │
   │                  │                   │<────────────────────────────────────────│
   │                  │                   │                    │                     │
   │                  │  onSuccess(months)│                    │                     │
   │                  │<──────────────────│                    │                     │
   │                  │                   │                    │                     │
   │                  │  setState(months) │                    │                     │
   │                  │  Hiển thị dropdown│                    │                     │
   │                  │  chọn tháng       │                    │                     │
   │                  │                   │                    │                     │
   │                  │                   │                    │                     │
   │  ╔═══════════════╧═══════════════════╧════════════════════╧═════════════════════╧══════╗
   │  ║                       2. GỌI API LẤY GIAO DỊCH THEO THÁNG                           ║
   │  ╚═══════════════╤═══════════════════╤════════════════════╤═════════════════════╤══════╝
   │                  │                   │                    │                     │
   │                  │  getListTransaction("12/2025")         │                     │
   │                  │──────────────────>│                    │                     │
   │                  │                   │                    │                     │
   │                  │                   │   getToken()       │                     │
   │                  │                   │───────────────────>│                     │
   │                  │                   │                    │                     │
   │                  │                   │   return JWT Token │                     │
   │                  │                   │<───────────────────│                     │
   │                  │                   │                    │                     │
   │                  │                   │                    │  HTTP GET           │
   │                  │                   │                    │  /?monthYear=       │
   │                  │                   │                    │  12/2025            │
   │                  │                   │                    │  Header:            │
   │                  │                   │                    │  Authorization:     │
   │                  │                   │                    │  Bearer <JWT>       │
   │                  │                   │────────────────────────────────────────>│
   │                  │                   │                    │                     │
   │                  │                   │   Response 200 OK  │                     │
   │                  │                   │   [{id, amount,    │                     │
   │                  │                   │     category...},  │                     │
   │                  │                   │    {...}]          │                     │
   │                  │                   │<────────────────────────────────────────│
   │                  │                   │                    │                     │
   │                  │  onSuccess(txns)  │                    │                     │
   │                  │<──────────────────│                    │                     │
   │                  │                   │                    │                     │
   │                  │  setState(lists)  │                    │                     │
   │  Hiển thị danh   │  Hiển thị giao    │                    │                     │
   │  sách giao dịch  │  dịch theo tháng  │                    │                     │
   │<─────────────────│                   │                    │                     │
   │                  │                   │                    │                     │
   │                  │                   │                    │                     │
   │  ╔═══════════════╧═══════════════════╧════════════════════╧═════════════════════╧══════╗
   │  ║                           3. CHỌN THÁNG KHÁC                                        ║
   │  ╚═══════════════╤═══════════════════╤════════════════════╤═════════════════════╤══════╝
   │                  │                   │                    │                     │
   │  Chọn tháng      │                   │                    │                     │
   │  "11/2025"       │                   │                    │                     │
   │─────────────────>│                   │                    │                     │
   │                  │                   │                    │                     │
   │                  │  getListTransaction("11/2025")         │                     │
   │                  │──────────────────>│                    │                     │
   │                  │                   │                    │                     │
   │                  │                   │   getToken()       │                     │
   │                  │                   │───────────────────>│                     │
   │                  │                   │   return JWT Token │                     │
   │                  │                   │<───────────────────│                     │
   │                  │                   │                    │                     │
   │                  │                   │                    │  HTTP GET           │
   │                  │                   │                    │  /?monthYear=       │
   │                  │                   │                    │  11/2025            │
   │                  │                   │────────────────────────────────────────>│
   │                  │                   │                    │                     │
   │                  │                   │   Response 200 OK  │                     │
   │                  │                   │   [Transactions...]│                     │
   │                  │                   │<────────────────────────────────────────│
   │                  │                   │                    │                     │
   │                  │  onSuccess(txns)  │                    │                     │
   │                  │<──────────────────│                    │                     │
   │                  │                   │                    │                     │
   │  Cập nhật danh   │                   │                    │                     │
   │  sách giao dịch  │                   │                    │                     │
   │<─────────────────│                   │                    │                     │
   │                  │                   │                    │                     │
```

---

## 5. Sơ đồ tuần tự - Đăng nhập (Login Sequence)

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                              SEQUENCE DIAGRAM: ĐĂNG NHẬP                                     │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

┌──────┐     ┌────────────┐     ┌──────────┐     ┌─────────────────┐     ┌──────────────┐
│ User │     │ SignInPage │     │  ApiUtil │     │SharedPrefUtil   │     │ Auth Service │
└──┬───┘     └─────┬──────┘     └────┬─────┘     └────────┬────────┘     └──────┬───────┘
   │               │                 │                    │                     │
   │  Enter email  │                 │                    │                     │
   │  & password   │                 │                    │                     │
   │──────────────>│                 │                    │                     │
   │               │                 │                    │                     │
   │  Click Login  │                 │                    │                     │
   │──────────────>│                 │                    │                     │
   │               │                 │                    │                     │
   │               │  _login()       │                    │                     │
   │               │────────────────>│                    │                     │
   │               │                 │                    │                     │
   │               │  Validate Input │                    │                     │
   │               │<────────────────│                    │                     │
   │               │                 │                    │                     │
   │               │  showLoading()  │                    │                     │
   │               │────────────────>│                    │                     │
   │               │                 │                    │                     │
   │               │  post(login,    │                    │                     │
   │               │  {email,pass})  │                    │                     │
   │               │────────────────>│                    │                     │
   │               │                 │                    │                     │
   │               │                 │  POST /auth/login  │                     │
   │               │                 │  {email, password} │                     │
   │               │                 │────────────────────────────────────────>│
   │               │                 │                    │                     │
   │               │                 │  {accessToken,     │                     │
   │               │                 │   user: {...}}     │                     │
   │               │                 │<────────────────────────────────────────│
   │               │                 │                    │                     │
   │               │  onSuccess()    │                    │                     │
   │               │<────────────────│                    │                     │
   │               │                 │                    │                     │
   │               │  hideLoading()  │                    │                     │
   │               │────────────────>│                    │                     │
   │               │                 │                    │                     │
   │               │  saveToken(token)                    │                     │
   │               │─────────────────────────────────────>│                     │
   │               │                 │                    │                     │
   │               │  saveUsername(username)              │                     │
   │               │─────────────────────────────────────>│                     │
   │               │                 │                    │                     │
   │               │  saveEmail(email)                    │                     │
   │               │─────────────────────────────────────>│                     │
   │               │                 │                    │                     │
   │               │  Navigate to    │                    │                     │
   │               │  MainPage       │                    │                     │
   │               │────────────────>│                    │                     │
   │               │                 │                    │                     │
   │  Show Home    │                 │                    │                     │
   │<──────────────│                 │                    │                     │
   │               │                 │                    │                     │
```

---

## 6. Authentication Flow

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│                              AUTHENTICATION FLOW                                             │
└─────────────────────────────────────────────────────────────────────────────────────────────┘

                              ┌─────────────┐
                              │  App Start  │
                              └──────┬──────┘
                                     │
                                     ▼
                              ┌─────────────┐
                              │ LoadingPage │
                              └──────┬──────┘
                                     │
                                     ▼
                          ┌─────────────────────┐
                          │    Check Token      │
                          │  in SharedPrefs?    │
                          └──────────┬──────────┘
                                     │
                    ┌────────────────┴────────────────┐
                    │ NO                              │ YES
                    ▼                                 ▼
           ┌─────────────────┐               ┌─────────────────┐
           │   OnboardPage   │               │    MainPage     │
           └────────┬────────┘               └────────┬────────┘
                    │                                 │
                    ▼                                 ▼
           ┌─────────────────┐               ┌─────────────────┐
           │   SignInPage    │               │    API Call     │
           └────────┬────────┘               └────────┬────────┘
                    │                                 │
                    ▼                                 ▼
           ┌─────────────────┐               ┌─────────────────┐
           │   Login API     │               │  Add Header:    │
           │                 │               │  Authorization: │
           └────────┬────────┘               │  Bearer <token> │
                    │                        └────────┬────────┘
         ┌──────────┴──────────┐                      │
         │ Success             │ Failed               ▼
         ▼                     ▼              ┌─────────────────┐
┌─────────────────┐   ┌─────────────────┐     │  Kong Gateway   │
│  Save Token to  │   │   Show Error    │     │   (Port 8000)   │
│ SharedPrefs     │   │   Message       │     └────────┬────────┘
└────────┬────────┘   └────────┬────────┘              │
         │                     │                       ▼
         ▼                     │              ┌─────────────────┐
┌─────────────────┐            │              │   Verify JWT    │
│    MainPage     │<───────────┘              └────────┬────────┘
└─────────────────┘                                    │
                                                       ▼
                                              ┌─────────────────┐
                                              │ Add x-user-id   │
                                              │ Header          │
                                              └────────┬────────┘
                                                       │
                                                       ▼
                                              ┌─────────────────┐
                                              │ Backend Service │
                                              │   (Port 3001)   │
                                              └─────────────────┘
```

---

## 7. Cấu trúc thư mục

```
lib/
├── api/
│   ├── api_end_point.dart      # Định nghĩa API endpoints
│   └── api_util.dart           # HTTP client utilities
│
├── common/
│   ├── flutter_toast.dart      # Toast notifications
│   └── loading_dialog.dart     # Loading indicators
│
├── models/
│   ├── account_model.dart      # Account entity
│   ├── group_model.dart        # Group entity
│   ├── transaction_model.dart  # Transaction entity
│   ├── icon.dart               # Icon model
│   └── list_icon.dart          # Category icons
│
├── pages/
│   ├── add/
│   │   ├── add_page.dart       # Thêm giao dịch
│   │   └── edit_page.dart      # Sửa giao dịch
│   │
│   ├── home/
│   │   ├── home.dart           # Main navigation (BottomNav)
│   │   └── home_page.dart      # Dashboard
│   │
│   ├── setting/                # Cài đặt tài khoản
│   │
│   ├── share/                  # Nhóm chi tiêu
│   │   └── child_page/
│   │       ├── transation_group_page.dart
│   │       ├── add_transation_group_page.dart
│   │       ├── edit_transation_group_page.dart
│   │       └── view_report_page.dart
│   │
│   ├── signin/
│   │   ├── onboard_page.dart   # Welcome screen
│   │   ├── signin_page.dart    # Đăng nhập
│   │   └── signup_page.dart    # Đăng ký
│   │
│   ├── transaction/
│   │   ├── transaction_page.dart   # Danh sách giao dịch
│   │   └── report_page.dart        # Báo cáo thống kê
│   │
│   └── loading_page.dart       # Splash screen / Auth check
│
├── res/
│   ├── app_colors.dart         # Color constants
│   └── app_styles.dart         # Text styles
│
├── notification/
│   └── timezone.dart           # Notification scheduling
│
├── shared_preference.dart      # Local storage utilities
├── constants.dart              # App constants
├── size_config.dart            # Responsive sizing
├── theme.dart                  # App theme
├── utils.dart                  # Utility functions
└── main.dart                   # Entry point
```

---

## 8. API Endpoints

```
┌──────────┬────────────────────────┬─────────────────────────────────────────┐
│  Method  │       Endpoint         │              Mô tả                      │
├──────────┼────────────────────────┼─────────────────────────────────────────┤
│  POST    │  /auth/login           │  Đăng nhập                              │
│  POST    │  /auth/signup          │  Đăng ký tài khoản mới                  │
├──────────┼────────────────────────┼─────────────────────────────────────────┤
│  GET     │  /months               │  Lấy danh sách tháng có giao dịch       │
│  GET     │  /?monthYear=MM/YYYY   │  Lấy giao dịch theo tháng               │
│  POST    │  /                     │  Tạo giao dịch mới                      │
│  PATCH   │  /:id                  │  Cập nhật giao dịch                     │
│  DELETE  │  /:id                  │  Xóa giao dịch                          │
└──────────┴────────────────────────┴─────────────────────────────────────────┘
```

---

## 9. Công nghệ sử dụng

```
┌─────────────────────┬────────────────────────────┐
│       Layer         │        Technology          │
├─────────────────────┼────────────────────────────┤
│  Frontend           │  Flutter / Dart            │
│  State Management   │  setState                  │
│  Local Storage      │  SharedPreferences         │
│  HTTP Client        │  http package              │
│  API Gateway        │  Kong                      │
│  Backend            │  NestJS                    │
│  Database           │  PostgreSQL                │
│  Authentication     │  JWT (JSON Web Token)      │
└─────────────────────┴────────────────────────────┘
```

---

## 10. Request/Response Flow

```
                    ┌─────────────────────────────────────────────────────────────┐
                    │                    REQUEST FLOW                              │
                    └─────────────────────────────────────────────────────────────┘

    ┌──────────────┐        ┌──────────────┐        ┌──────────────┐        ┌──────────────┐
    │   Flutter    │        │    Kong      │        │   NestJS     │        │  PostgreSQL  │
    │     App      │        │   Gateway    │        │   Backend    │        │   Database   │
    └──────┬───────┘        └──────┬───────┘        └──────┬───────┘        └──────┬───────┘
           │                       │                       │                       │
           │  GET /months          │                       │                       │
           │  Authorization:       │                       │                       │
           │  Bearer <JWT>         │                       │                       │
           │──────────────────────>│                       │                       │
           │                       │                       │                       │
           │                       │  Verify JWT           │                       │
           │                       │  Extract userId       │                       │
           │                       │  from token           │                       │
           │                       │                       │                       │
           │                       │  Add x-user-id        │                       │
           │                       │  header               │                       │
           │                       │──────────────────────>│                       │
           │                       │                       │                       │
           │                       │                       │  SELECT months        │
           │                       │                       │  WHERE userId = ?     │
           │                       │                       │──────────────────────>│
           │                       │                       │                       │
           │                       │                       │  ["10/2025", ...]     │
           │                       │                       │<──────────────────────│
           │                       │                       │                       │
           │                       │  ["10/2025", ...]     │                       │
           │                       │<──────────────────────│                       │
           │                       │                       │                       │
           │  200 OK               │                       │                       │
           │  ["10/2025", ...]     │                       │                       │
           │<──────────────────────│                       │                       │
           │                       │                       │                       │
```
