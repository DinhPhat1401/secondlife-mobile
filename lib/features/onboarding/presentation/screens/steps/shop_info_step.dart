import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/features/auth/presentation/auth_providers.dart';
import 'package:secondlife_app_seller/features/onboarding/domain/seller_onboarding_model.dart';
import 'package:secondlife_app_seller/features/onboarding/presentation/onboarding_providers.dart';
import 'package:secondlife_app_seller/features/onboarding/presentation/screens/address_map_picker_screen.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_text_field.dart';

class ShopInfoStep extends ConsumerStatefulWidget {
  const ShopInfoStep({super.key});

  @override
  ConsumerState<ShopInfoStep> createState() => _ShopInfoStepState();
}

class _ShopInfoStepState extends ConsumerState<ShopInfoStep> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _contactNameController = TextEditingController();

  double? _latitude;
  double? _longitude;
  String? _address;

  @override
  void initState() {
    super.initState();
    final onboarding = ref.read(onboardingNotifierProvider).onboarding;
    final user = ref.read(authNotifierProvider).user;

    _shopNameController.text = onboarding?.shopName ?? '';
    _emailController.text = onboarding?.email ?? user?.email ?? '';
    _phoneController.text = onboarding?.phone ?? user?.phone ?? '';
    _contactNameController.text = onboarding?.pickupAddress?.name ?? user?.fullName ?? '';

    final pickupAddress = onboarding?.pickupAddress;
    if (pickupAddress != null) {
      _latitude = pickupAddress.latitude;
      _longitude = pickupAddress.longitude;
      _address = pickupAddress.address;
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _contactNameController.dispose();
    super.dispose();
  }

  Future<void> _pickLocationOnMap() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => AddressMapPickerScreen(
          initialLat: _latitude,
          initialLng: _longitude,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _latitude = result['latitude'] as double;
        _longitude = result['longitude'] as double;
        _address = result['address'] as String;
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn vị trí kho lấy hàng trên bản đồ'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final pickup = PickupAddressModel(
      name: _contactNameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _address,
      latitude: _latitude!,
      longitude: _longitude!,
    );

    final success = await ref.read(onboardingNotifierProvider.notifier).saveShopInfo(
          shopName: _shopNameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          pickupAddress: pickup,
        );

    if (!success && mounted) {
      final err = ref.read(onboardingNotifierProvider).errorMessage;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bước 1: Thông tin Cửa hàng',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Cung cấp tên shop và vị trí kho để tài xế Lalamove tới nhận kiện hàng.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Shop Name
            SlTextField(
              label: 'Tên Cửa hàng / Shop',
              hint: 'Ví dụ: Shop Gia Dụng Nhật Bãi',
              controller: _shopNameController,
              prefixIcon: const Icon(Icons.storefront_outlined, color: AppColors.textMuted),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên shop';
                if (v.trim().length > 30) return 'Tên shop tối đa 30 ký tự';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Contact Person
            SlTextField(
              label: 'Người liên hệ giao hàng',
              hint: 'Nguyễn Văn A',
              controller: _contactNameController,
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập người liên hệ';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            SlTextField(
              label: 'Số điện thoại lấy hàng',
              hint: '0912345678',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textMuted),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập số điện thoại';
                if (v.trim().length < 9) return 'Số điện thoại không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email Shop
            SlTextField(
              label: 'Email thông báo đơn hàng',
              hint: 'shop@example.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                if (!v.contains('@')) return 'Email không hợp lệ';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Pickup Location Map Selector
            const Text(
              'Vị trí kho lấy hàng (GPS)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickLocationOnMap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _latitude != null ? AppColors.primary : AppColors.border,
                    width: _latitude != null ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.map_outlined, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _latitude != null ? 'Đã chọn vị trí trên bản đồ' : 'Chạm để chọn điểm lấy hàng',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _address ?? 'Hệ thống dùng tọa độ GPS để tính phí ship Lalamove chuẩn xác',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Submit Button
            SlButton(
              text: 'Lưu & Tiếp tục xác thực',
              isLoading: state.isLoading,
              onPressed: _handleSave,
            ),
          ],
        ),
      ),
    );
  }
}
