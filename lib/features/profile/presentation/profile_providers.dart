import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/profile_repository.dart';
import '../domain/profile_models.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProfileRepository(client: client);
});

class ProfileState {
  final SellerProfileModel? profile;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  ProfileState copyWith({
    SellerProfileModel? profile,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    Future.microtask(() => loadProfile());
    return const ProfileState(isLoading: true);
  }

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _repository.getProfile();
      state = state.copyWith(profile: res, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải thông tin hồ sơ người bán.',
      );
    }
  }

  Future<bool> updateProfile(UpdateProfileRequestModel req) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      final updated = await _repository.updateProfile(req);
      state = state.copyWith(
        profile: updated,
        isSaving: false,
        successMessage: 'Đã cập nhật thông tin cửa hàng thành công!',
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Cập nhật thất bại. Vui lòng kiểm tra lại kết nối.',
      );
      return false;
    }
  }

  Future<bool> updatePickupAddress({
    required String address,
    required double lat,
    required double lng,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      await _repository.updatePickupAddress(address: address, lat: lat, lng: lng);
      final updatedProfile = state.profile?.copyWith(
        streetAddress: address,
        latitude: lat,
        longitude: lng,
      );
      state = state.copyWith(
        profile: updatedProfile,
        isSaving: false,
        successMessage: 'Đã cập nhật kho lấy hàng Lalamove thành công!',
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Không thể cập nhật địa chỉ kho.',
      );
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      final success = await _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (success) {
        state = state.copyWith(
          isSaving: false,
          successMessage: 'Đổi mật khẩu thành công! Các phiên đăng nhập cũ đã được thu hồi an toàn.',
        );
        return true;
      }
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Mật khẩu hiện tại không chính xác.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Đổi mật khẩu thất bại. Vui lòng thử lại.',
      );
      return false;
    }
  }
}

final profileNotifierProvider = NotifierProvider<ProfileNotifier, ProfileState>(
  ProfileNotifier.new,
);
