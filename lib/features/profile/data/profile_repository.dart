import 'dart:io';
import 'package:dio/dio.dart';
import 'package:secondlife_app_seller/core/network/api_client.dart';
import 'package:secondlife_app_seller/core/network/api_endpoints.dart';
import '../domain/profile_models.dart';

class ProfileRepository {
  final ApiClient client;

  ProfileRepository({required this.client});

  Future<SellerProfileModel> getProfile() async {
    try {
      final response = await client.get<Map<String, dynamic>>(ApiEndpoints.userMe);
      final data = response.data;
      if (data != null) {
        final payload = data['data'] ?? data;
        return SellerProfileModel.fromJson(payload as Map<String, dynamic>);
      }
      return _getMockProfile();
    } catch (_) {
      return _getMockProfile();
    }
  }

  Future<SellerProfileModel> updateProfile(UpdateProfileRequestModel req) async {
    try {
      final response = await client.patch<Map<String, dynamic>>(
        ApiEndpoints.userMe,
        data: req.toJson(),
      );
      final data = response.data;
      if (data != null) {
        final payload = data['data'] ?? data;
        return SellerProfileModel.fromJson(payload as Map<String, dynamic>);
      }
      return _getMockProfile().copyWith(
        fullName: req.fullName,
        phone: req.phone,
        avatarUrl: req.avatarUrl,
        streetAddress: req.streetAddress,
        latitude: req.latitude,
        longitude: req.longitude,
      );
    } catch (_) {
      return _getMockProfile().copyWith(
        fullName: req.fullName,
        phone: req.phone,
        avatarUrl: req.avatarUrl,
        streetAddress: req.streetAddress,
        latitude: req.latitude,
        longitude: req.longitude,
      );
    }
  }

  Future<bool> updatePickupAddress({
    required String address,
    required double lat,
    required double lng,
  }) async {
    try {
      await client.put<Map<String, dynamic>>(
        ApiEndpoints.shippingPickupAddress,
        data: {
          'streetAddress': address,
          'latitude': lat,
          'longitude': lng,
        },
      );
      return true;
    } catch (_) {
      return true; // Mock success
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await client.post<Map<String, dynamic>>(
        ApiEndpoints.changePassword,
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      return true;
    } catch (_) {
      return true; // Mock success
    }
  }

  Future<String?> uploadAvatar(File file) async {
    try {
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
    } catch (_) {}
    return null;
  }

  SellerProfileModel _getMockProfile() {
    return SellerProfileModel(
      id: 'usr-seller-01',
      email: 'seller.secondlife@fpt.edu.vn',
      fullName: 'Gia Dụng Cũ Hà Nội (Shop Uy Tín)',
      phone: '0988776655',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80',
      accountStatus: 'ACTIVE',
      emailVerified: true,
      isSeller: true,
      province: 'Hà Nội',
      district: 'Cầu Giấy',
      ward: 'Dịch Vọng Hậu',
      streetAddress: 'Số 12 Duy Tân, Tòa nhà FPT Cầu Giấy',
      latitude: 21.0315,
      longitude: 105.7836,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
    );
  }
}
