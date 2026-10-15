import 'dart:io';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/error_handler.dart';
import '../domain/seller_onboarding_model.dart';
import '../domain/seller_verification_model.dart';

class OnboardingRepository {
  final ApiClient client;

  OnboardingRepository({required this.client});

  Future<SellerOnboardingModel> getOnboardingInfo() async {
    final response = await client.get<Map<String, dynamic>>(
      ApiEndpoints.sellerOnboardingMe,
    );
    if (response.data == null) {
      return SellerOnboardingModel(
        emailVerified: false,
        canStartEkyc: false,
        nextStep: 'SHOP_INFORMATION',
      );
    }
    return SellerOnboardingModel.fromJson(response.data!);
  }

  Future<SellerOnboardingModel> updateShopInfo({
    required String shopName,
    required String email,
    required String phone,
    required PickupAddressModel pickupAddress,
  }) async {
    final response = await client.put<Map<String, dynamic>>(
      ApiEndpoints.sellerOnboardingMe,
      data: {
        'shopName': shopName.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'pickupAddress': pickupAddress.toJson(),
      },
    );
    return SellerOnboardingModel.fromJson(response.data!);
  }

  Future<ReverseGeocodeResult> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.reverseGeocode,
      data: {
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return ReverseGeocodeResult.fromJson(response.data!);
  }

  Future<void> sendShopEmailOtp() async {
    await client.post(ApiEndpoints.sellerOnboardingSendCode);
  }

  Future<bool> verifyShopEmailOtp(String otp) async {
    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.sellerOnboardingVerify,
      data: {'otp': otp.trim()},
    );
    return response.success;
  }

  Future<SellerVerificationModel?> getMyVerification() async {
    try {
      final response = await client.get<Map<String, dynamic>>(
        ApiEndpoints.sellerVerificationsMe,
      );
      if (response.data == null) return null;
      return SellerVerificationModel.fromJson(response.data!);
    } on AppException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<SellerVerificationModel> submitVerification({
    required String documentNumber,
    required String documentFrontUrl,
    required String documentBackUrl,
    required String selfieUrl,
    String verificationType = 'CITIZEN_ID',
  }) async {
    final clientSession = '${Platform.operatingSystem}_App_1.0_${DateTime.now().millisecondsSinceEpoch}';
    final token = const Uuid().v4();

    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.sellerVerifications,
      data: {
        'verificationType': verificationType,
        'documentNumber': documentNumber.trim(),
        'documentFrontUrl': documentFrontUrl,
        'documentBackUrl': documentBackUrl,
        'selfieUrl': selfieUrl,
        'clientSession': clientSession,
        'token': token,
      },
    );

    return SellerVerificationModel.fromJson(response.data!);
  }

  Future<SellerVerificationModel> resubmitVerification({
    required String verificationId,
    required String documentFrontUrl,
    required String documentBackUrl,
    String? selfieUrl,
  }) async {
    final clientSession = '${Platform.operatingSystem}_Resubmit_1.0_${DateTime.now().millisecondsSinceEpoch}';
    final token = const Uuid().v4();

    final response = await client.post<Map<String, dynamic>>(
      ApiEndpoints.sellerVerificationResubmit(verificationId),
      data: {
        'documentFrontUrl': documentFrontUrl,
        'documentBackUrl': documentBackUrl,
        'selfieUrl': ?selfieUrl,
        'clientSession': clientSession,
        'token': token,
      },
    );

    return SellerVerificationModel.fromJson(response.data!);
  }
}
