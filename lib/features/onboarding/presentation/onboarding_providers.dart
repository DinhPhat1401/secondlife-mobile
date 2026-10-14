import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/media_repository.dart';
import '../data/onboarding_repository.dart';
import '../domain/seller_onboarding_model.dart';
import '../domain/seller_verification_model.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return MediaRepository(client: client);
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return OnboardingRepository(client: client);
});

class OnboardingFlowState {
  final bool isLoading;
  final String? errorMessage;
  final SellerOnboardingModel? onboarding;
  final SellerVerificationModel? verification;
  final int step; // 0: Shop Info, 1: Email OTP, 2: eKYC Capture, 3: Status View

  const OnboardingFlowState({
    this.isLoading = false,
    this.errorMessage,
    this.onboarding,
    this.verification,
    this.step = 0,
  });

  OnboardingFlowState copyWith({
    bool? isLoading,
    String? errorMessage,
    SellerOnboardingModel? onboarding,
    SellerVerificationModel? verification,
    int? step,
  }) {
    return OnboardingFlowState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      onboarding: onboarding ?? this.onboarding,
      verification: verification ?? this.verification,
      step: step ?? this.step,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingFlowState> {
  @override
  OnboardingFlowState build() {
    Future.microtask(() => loadState());
    return const OnboardingFlowState(isLoading: true);
  }

  OnboardingRepository get _repo => ref.read(onboardingRepositoryProvider);
  MediaRepository get _mediaRepo => ref.read(mediaRepositoryProvider);

  Future<void> loadState() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final onboarding = await _repo.getOnboardingInfo();
      final verification = await _repo.getMyVerification();

      int initialStep = 0;
      if (verification != null &&
          verification.status != VerificationStatus.unknown) {
        initialStep = 3; // View status
      } else if (onboarding.canStartEkyc && onboarding.emailVerified) {
        initialStep = 2; // eKYC step
      } else if (onboarding.nextStep == 'EMAIL_VERIFICATION') {
        initialStep = 1; // Email OTP step
      } else {
        initialStep = 0; // Shop information step
      }

      state = state.copyWith(
        isLoading: false,
        onboarding: onboarding,
        verification: verification,
        step: initialStep,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> saveShopInfo({
    required String shopName,
    required String email,
    required String phone,
    required PickupAddressModel pickupAddress,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _repo.updateShopInfo(
        shopName: shopName,
        email: email,
        phone: phone,
        pickupAddress: pickupAddress,
      );

      final nextStep = updated.emailVerified ? 2 : 1;
      state = state.copyWith(
        isLoading: false,
        onboarding: updated,
        step: nextStep,
      );

      if (!updated.emailVerified) {
        await _repo.sendShopEmailOtp();
      }
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> verifyShopOtp(String otp) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final success = await _repo.verifyShopEmailOtp(otp);
      if (success) {
        final updated = await _repo.getOnboardingInfo();
        state = state.copyWith(
          isLoading: false,
          onboarding: updated,
          step: 2, // Proceed to eKYC
        );
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Mã xác thực không hợp lệ',
      );
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> submitEkyc({
    required String documentNumber,
    required File frontImage,
    required File backImage,
    required File selfieImage,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      // 1. Upload 3 photos to Cloudinary
      final frontUrl = await _mediaRepo.uploadImage(frontImage);
      final backUrl = await _mediaRepo.uploadImage(backImage);
      final selfieUrl = await _mediaRepo.uploadImage(selfieImage);

      // 2. Submit verification document
      final result = await _repo.submitVerification(
        documentNumber: documentNumber,
        documentFrontUrl: frontUrl,
        documentBackUrl: backUrl,
        selfieUrl: selfieUrl,
      );

      // 3. Update state
      state = state.copyWith(
        isLoading: false,
        verification: result,
        step: 3, // Status View
      );

      // 4. Refresh user profile to check if auto-approved
      await ref.read(authNotifierProvider.notifier).checkAuth();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> resubmitEkyc({
    required String verificationId,
    required File frontImage,
    required File backImage,
    File? selfieImage,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final frontUrl = await _mediaRepo.uploadImage(frontImage);
      final backUrl = await _mediaRepo.uploadImage(backImage);
      String? selfieUrl;
      if (selfieImage != null) {
        selfieUrl = await _mediaRepo.uploadImage(selfieImage);
      }

      final result = await _repo.resubmitVerification(
        verificationId: verificationId,
        documentFrontUrl: frontUrl,
        documentBackUrl: backUrl,
        selfieUrl: selfieUrl,
      );

      state = state.copyWith(
        isLoading: false,
        verification: result,
        step: 3,
      );

      await ref.read(authNotifierProvider.notifier).checkAuth();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void goToStep(int step) {
    state = state.copyWith(step: step);
  }
}

final onboardingNotifierProvider =
    NotifierProvider<OnboardingNotifier, OnboardingFlowState>(OnboardingNotifier.new);
