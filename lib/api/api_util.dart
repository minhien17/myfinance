import 'dart:async';
import 'dart:convert';
// import 'package:http_parser/http_parser.dart';
import 'package:http/http.dart' as http;
import 'package:my_finance/shared_preference.dart';

class ApiUtil {
  bool IS_SHOW_LOG = false;
  static ApiUtil? _mInstance;

  static ApiUtil? getInstance() {
    _mInstance ??= ApiUtil();
    return _mInstance;
  }

  ApiUtil();

  Future<void> get(
      {required String url,
      Map<String, dynamic> params = const {},
      Map<String, String>? headers,
      required Function(BaseResponse response) onSuccess,
      required Function(dynamic error) onError,
      bool isCancel = false}) async {
    String token = await SharedPreferenceUtil.getToken();
    var uri = Uri.parse(url).replace(
        queryParameters:
            params.map((key, value) => MapEntry(key, value.toString())));
    try {
      print('--- GET Request ---');
      print('URL: $uri');
      print('Token: $token');

      // Merge default headers with custom headers
      final Map<String, String> finalHeaders = {
        "Authorization": 'Bearer $token',
        "content-type": 'application/json; charset=UTF-8',
        ...?headers, // Spread custom headers if provided
      };

      var res = await http.get(
        uri,
        headers: finalHeaders,
      ).timeout(const Duration(seconds: 10));
      print('--- GET Response ---');
      print('Status code: ${res.statusCode}');
      // print('Body: ${res.body}');
      var data = jsonDecode(res.body);
      if (res.statusCode >= 400) {
        // var r = ErrorResponse.from(data: data, statusCode: res.statusCode);
        // var a = ErrorApi.from(response: r);
        final message = data['message'] ?? 'Lỗi không xác định';
        onError(message); // chỉ truyền Strings
      } else {
        if (onSuccess != null) onSuccess(getBaseResponse2(res));
      }
    } catch (e) {
      // No specified type, handles all
      print('Something really unknown: $e');
      if (onError != null) onError(e);
    }
  }

  Future<void> put({
    required String url,
    Map<String, dynamic>? body,
    Map<String, dynamic> params = const {},
    required Function(BaseResponse response) onSuccess,
    required Function(dynamic error) onError,
  }) async {
    String token = await SharedPreferenceUtil.getToken();

    var uri = Uri.parse(url).replace(
        queryParameters:
            params.map((key, value) => MapEntry(key, value.toString())));
    try {
      var res = await http.put(
        uri,
        body: jsonEncode(body),
        headers: {
          "Authorization": 'Bearer $token',
          "content-type": 'application/json; charset=UTF-8'
        },
      ).timeout(const Duration(seconds: 10));
      var data = jsonDecode(res.body);
      if (res.statusCode >= 400) {
        // var r = ErrorResponse.from(data: data, statusCode: res.statusCode);
        // var a = ErrorApi.from(response: r);
        final message = data['message'] ?? 'Lỗi không xác định';
        onError(message); // chỉ truyền String
      } else {
        if (onSuccess != null) onSuccess(getBaseResponse2(res));
      }
    } catch (e) {
      // No specified type, handles all
      print('Something really unknown: $e');
      if (onError != null) onError(e);
    }
  }

  void post({
    required String url,
    Map<String, dynamic>? body,
    Map<String, dynamic> params = const {},
    bool isDetect = false,
    required Function(BaseResponse response) onSuccess,
    required Function(dynamic error) onError,
  }) async {
    String token = await SharedPreferenceUtil.getToken();
    var uri = Uri.parse(url).replace(
        queryParameters:
            params.map((key, value) => MapEntry(key, value.toString())));
    try {
      print('---Post request ---');
      print('URL: $uri');

      var res = await http.post(
        uri,
        body: jsonEncode(body),
        headers: {
          "Authorization": 'Bearer $token',
          "content-type": 'application/json; charset=UTF-8'
        },
      ).timeout(const Duration(seconds: 10));

      print('--- Post Response ---');
      print('Status code: ${res.statusCode}');
      // print('Body: ${res.body}');

      var data = jsonDecode(res.body);
      if (res.statusCode >= 400) {
        // var r = ErrorResponse.from(data: data, statusCode: res.statusCode);
        // var a = ErrorApi.from(response: r);
        final message = data['message'] ?? 'Lỗi không xác định';
        onError(message); // chỉ truyền String
      } else {
        if (onSuccess != null) onSuccess(getBaseResponse2(res));
      }
    } catch (e) {
      // No specified type, handles all
      print('Something really unknown: $e');
      if (onError != null) onError(e);
    }
  }

  void delete({
    required String url,
    Map<String, dynamic> params = const {},
    required Function(BaseResponse response) onSuccess,
    required Function(dynamic error) onError,
    bool isCancel = false,
  }) async {
    String token = await SharedPreferenceUtil.getToken();
    var uri = Uri.parse(url).replace(
        queryParameters:
            params.map((key, value) => MapEntry(key, value.toString())));
    try {
      print('--- DELETE Request ---');
      print('URL: $uri');
      var res = await http.delete(
        uri,
        headers: {
          "Authorization": 'Bearer $token',
          "content-type": 'application/json; charset=UTF-8'
        },
      ).timeout(const Duration(seconds: 10));
      print('--- DELETE Response ---');
      print('Status code: ${res.statusCode}');
      print('Body: ${res.body}');
      var data = jsonDecode(res.body);
      if (res.statusCode >= 400) {
        final message = data['message'] ?? 'Lỗi không xác định';
        onError(message); // chỉ truyền Strings
      } else {
        if (onSuccess != null) onSuccess(getBaseResponse2(res));
      }
    } catch (e) {
      print('Something really unknown: $e');
      if (onError != null) onError(e);
    }
  }

  Future<void> patch({
    required String url,
    Map<String, dynamic>? body,
    Map<String, dynamic> params = const {},
    required Function(BaseResponse response) onSuccess,
    required Function(dynamic error) onError,
  }) async {
    String token = await SharedPreferenceUtil.getToken();
    var uri = Uri.parse(url).replace(
        queryParameters:
            params.map((key, value) => MapEntry(key, value.toString())));
    try {
      print('--- PATCH Request ---');
      print(body);
      print('URL: $uri');
      var res = await http.patch(
        uri,
        body: jsonEncode(body),
        headers: {
          "Authorization": 'Bearer $token',
          "content-type": 'application/json; charset=UTF-8'
        },
      ).timeout(const Duration(seconds: 10));
      print('--- PATCH Response ---');
      print('Status code: ${res.statusCode}');
      print('Body: ${res.body}');
      var data = jsonDecode(res.body);
      if (res.statusCode >= 400) {
        final message = data['message'] ?? 'Lỗi không xác định';
        onError(message); // chỉ truyền String
      } else {
        if (onSuccess != null) onSuccess(getBaseResponse2(res));
      }
    } catch (e) {
      print('Something really unknown: $e');
      if (onError != null) onError(e);
    }
  }

  BaseResponse getBaseResponse2(http.Response response) {
    return BaseResponse.success(
      data: jsonDecode(response.body) ?? "",
      code: response.statusCode,
      message: response.reasonPhrase,
      // status: jsonDecode(response.body)['status']
    );
  }
}

class BaseResponse {
  String? message;
  int? code;
  dynamic data;
  int? status;
  String? errMessage;

  BaseResponse.success(
      {this.data, this.code, this.message, this.status, this.errMessage});

  BaseResponse.error(this.message, {this.data, this.code});

  bool get isSuccess => code != null && code == 200;
  bool get isStatusSuccess => status == 200;
}

class ErrorResponse {
  dynamic data;
  int? statusCode;

  ErrorResponse({this.data, this.statusCode});

  ErrorResponse.from({this.data, this.statusCode});
}

class ErrorApi {
  dynamic response;

  ErrorApi({this.response});

  ErrorApi.from({this.response});

  String get message {
    if (response.data is Map && response.data['message'] != null) {
      return response.data['message'];
    }
    return "Lỗi không xác định (${response.statusCode})";
  }

  @override
  String toString() => response;
}

ErrorApi getBaseErrorResponse(http.Response response) {
  final body = jsonDecode(response.body);

  final errorResponse = ErrorResponse(
    statusCode: response.statusCode,
    data: body,
  );

  return ErrorApi(response: errorResponse);
}
