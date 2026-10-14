import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;

  AppException({
    required this.message,
    this.statusCode,
    this.errorCode,
  });

  @override
  String toString() => message;

  factory AppException.fromDio(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return AppException(
        message: 'Kết nối máy chủ quá hạn. Vui lòng kiểm tra lại mạng.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return AppException(
        message: 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra cổng mạng (8080).',
      );
    }

    final response = error.response;
    if (response != null) {
      final statusCode = response.statusCode;
      String? message;
      String? errorCode;

      if (response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        message = data['message'] ?? data['error'];
        errorCode = data['errorCode'] ?? data['code'];
      } else if (response.data is String && (response.data as String).isNotEmpty) {
        message = response.data;
      }

      // Map domain error code
      if (errorCode != null && _errorCodeMessages.containsKey(errorCode)) {
        return AppException(
          message: _errorCodeMessages[errorCode]!,
          statusCode: statusCode,
          errorCode: errorCode,
        );
      }

      if (statusCode == 401) {
        final path = error.requestOptions.path;
        final isLogin = path.contains('/api/auth/login');
        return AppException(
          message: isLogin
              ? (message ?? 'Email hoặc mật khẩu không chính xác.')
              : 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
          statusCode: 401,
        );
      }

      if (statusCode == 403) {
        return AppException(
          message: 'Bạn không có quyền thực hiện thao tác này.',
          statusCode: 403,
        );
      }

      return AppException(
        message: message ?? 'Có lỗi xảy ra (Mã lỗi $statusCode)',
        statusCode: statusCode,
        errorCode: errorCode,
      );
    }

    return AppException(message: error.message ?? 'Đã xảy ra sự cố không xác định');
  }

  static const Map<String, String> _errorCodeMessages = {
    'EMAIL_ALREADY_EXISTS': 'Email này đã được đăng ký tài khoản khác.',
    'INVALID_CREDENTIALS': 'Email hoặc mật khẩu không chính xác.',
    'SELLER_NOT_VERIFIED': 'Tài khoản của bạn chưa hoàn tất định danh người bán eKYC.',
    'LISTING_CREDIT_EXHAUSTED': 'Bạn đã hết lượt đăng tin. Vui lòng mua thêm gói lượt đăng.',
    'VALUATION_CREDIT_EXHAUSTED': 'Bạn đã hết lượt định giá AI. Vui lòng mua thêm gói định giá.',
    'SIMILAR_LISTING_COOLDOWN': 'Bạn vừa đăng một sản phẩm tương tự trong 24h qua. Hãy sử dụng tính năng Đẩy tin (Re-up).',
    'WALLET_INSUFFICIENT_BALANCE': 'Số dư trong ví không đủ để thực hiện giao dịch này.',
    'INSPECTION_RESULT_IMMUTABLE': 'Biên bản kiểm định này đã nộp và không thể chỉnh sửa.',
  };
}
