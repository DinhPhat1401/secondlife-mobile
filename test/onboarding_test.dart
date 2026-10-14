import 'package:flutter_test/flutter_test.dart';
import 'package:secondlife_app_seller/features/onboarding/domain/seller_onboarding_model.dart';
import 'package:secondlife_app_seller/features/onboarding/domain/seller_verification_model.dart';
import 'package:secondlife_app_seller/features/onboarding/presentation/onboarding_providers.dart';

void main() {
  group('SellerOnboardingModel & PickupAddressModel Tests', () {
    test('Parses complete onboarding JSON with Lalamove GPS address correctly', () {
      final json = {
        'id': 'onb-123',
        'shopName': 'Gia Dụng Xanh Sài Gòn',
        'email': 'shop@secondlife.vn',
        'phone': '0901234567',
        'emailVerified': true,
        'canStartEkyc': true,
        'nextStep': 'EKYC_SUBMISSION',
        'pickupAddress': {
          'id': 'addr-001',
          'name': 'Nguyễn Văn Phát',
          'phone': '0901234567',
          'address': 'Lô E2a-7, Đường D1, Đ. D1, Long Thạnh Mỹ, TP. Thủ Đức, TP.HCM',
          'latitude': 10.8411,
          'longitude': 106.8099,
          'isDefault': true,
        },
      };

      final model = SellerOnboardingModel.fromJson(json);

      expect(model.shopName, 'Gia Dụng Xanh Sài Gòn');
      expect(model.email, 'shop@secondlife.vn');
      expect(model.phone, '0901234567');
      expect(model.emailVerified, true);
      expect(model.canStartEkyc, true);
      expect(model.nextStep, 'EKYC_SUBMISSION');
      expect(model.pickupAddress, isNotNull);
      expect(model.pickupAddress!.latitude, 10.8411);
      expect(model.pickupAddress!.longitude, 106.8099);
      expect(model.pickupAddress!.name, 'Nguyễn Văn Phát');
    });

    test('Parses onboarding JSON with missing optional fields gracefully', () {
      final json = <String, dynamic>{};
      final model = SellerOnboardingModel.fromJson(json);

      expect(model.shopName, isNull);
      expect(model.emailVerified, false);
      expect(model.canStartEkyc, false);
      expect(model.pickupAddress, isNull);
    });
  });

  group('SellerVerificationModel & VerificationStatus Tests', () {
    test('Correctly maps status string to VerificationStatus enum', () {
      expect(VerificationStatus.fromString('SUBMITTED'), VerificationStatus.submitted);
      expect(VerificationStatus.fromString('EKYC_PENDING'), VerificationStatus.ekycPending);
      expect(VerificationStatus.fromString('NEEDS_REVIEW'), VerificationStatus.needsReview);
      expect(VerificationStatus.fromString('APPROVED'), VerificationStatus.approved);
      expect(VerificationStatus.fromString('RESUBMIT_REQUIRED'), VerificationStatus.resubmitRequired);
      expect(VerificationStatus.fromString('REJECTED'), VerificationStatus.rejected);
      expect(VerificationStatus.fromString('INVALID_STATUS'), VerificationStatus.unknown);
    });

    test('Parses verification JSON correctly', () {
      final json = {
        'id': 'verif-777',
        'userId': 'usr-001',
        'shopName': 'Bếp Việt SecondLife',
        'verificationType': 'CITIZEN_ID',
        'documentNumber': '079201009999',
        'documentNumberMasked': '******009999',
        'documentFrontUrl': 'https://res.cloudinary.com/front.jpg',
        'documentBackUrl': 'https://res.cloudinary.com/back.jpg',
        'selfieUrl': 'https://res.cloudinary.com/selfie.jpg',
        'status': 'RESUBMIT_REQUIRED',
        'reasonCodeDescription': 'Mặt sau bị mờ góc dưới bên phải',
        'submittedAt': '2026-10-14 10:00:00',
        'resubmissionCount': 1,
      };

      final model = SellerVerificationModel.fromJson(json);

      expect(model.id, 'verif-777');
      expect(model.status, VerificationStatus.resubmitRequired);
      expect(model.rejectionReason, 'Mặt sau bị mờ góc dưới bên phải');
      expect(model.resubmissionCount, 1);
      expect(model.documentNumberMasked, '******009999');
    });
  });

  group('OnboardingFlowState Tests', () {
    test('Flow state copyWith updates fields correctly', () {
      const state = OnboardingFlowState(step: 0, isLoading: false);
      final updated = state.copyWith(step: 2, isLoading: true);

      expect(updated.step, 2);
      expect(updated.isLoading, true);
    });
  });
}
