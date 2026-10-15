import 'dart:io';
import 'package:dio/dio.dart';
import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/network/api_endpoints.dart';
import 'package:secondlife_app_seller/core/network/error_handler.dart';
import '../domain/profile_models.dart';

class ProfileRepository {
  final ApiClient client;

  ProfileRepository({required this.client});

  Future<SellerProfileModel> getProfile() async {
    final response = await client.get<Map<String, dynamic>>(ApiEndpoints.userMe);
    final data = response.data;
    if (data == null) {
      throw AppException(message: 'Không nhận được dữ liệu hồ sơ từ máy chủ');
    }
    final payload = data['data'] ?? data;
    return SellerProfileModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<SellerProfileModel> updateProfile(UpdateProfileRequestModel req) async {
    final response = await client.patch<Map<String, dynamic>>(
      ApiEndpoints.userMe,
      data: req.toJson(),
    );
    final data = response.data;
    if (data == null) {
      throw AppException(message: 'Cập nhật hồ sơ thất bại');
    }
    final payload = data['data'] ?? data;
    return SellerProfileModel.fromJson(payload as Map<String, dynamic>);
  }

  Future<bool> updatePickupAddress({
    required String address,
    required double lat,
    required double lng,
  }) async {
    await client.put<Map<String, dynamic>>(
      ApiEndpoints.shippingPickupAddress,
      data: {
        'streetAddress': address,
        'latitude': lat,
        'longitude': lng,
      },
    );
    return true;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await client.post<Map<String, dynamic>>(
      ApiEndpoints.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
    return true;
  }

  Future<String?> uploadAvatar(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.mediaUpload,
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    final data = response.data;
    if (data != null) {
      final payload = data['data'] ?? data;
      return payload['url']?.toString() ?? payload['secure_url']?.toString();
    }
    throw AppException(message: 'Tải ảnh đại diện thất bại');
  }
}
