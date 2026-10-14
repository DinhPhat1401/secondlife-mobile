import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/features/onboarding/presentation/onboarding_providers.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_text_field.dart';

class EkycCameraStep extends ConsumerStatefulWidget {
  final bool isResubmit;
  final String? verificationId;

  const EkycCameraStep({
    super.key,
    this.isResubmit = false,
    this.verificationId,
  });

  @override
  ConsumerState<EkycCameraStep> createState() => _EkycCameraStepState();
}

class _EkycCameraStepState extends ConsumerState<EkycCameraStep> {
  final _docNumberController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _frontImage;
  File? _backImage;
  File? _selfieImage;

  @override
  void dispose() {
    _docNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, Function(File) onSelected) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          onSelected(File(picked.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _showImageSourceDialog(Function(File) onSelected) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Chụp ảnh mới bằng Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera, onSelected);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Chọn ảnh từ Thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery, onSelected);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    final docNumber = _docNumberController.text.trim();
    if (!widget.isResubmit && (docNumber.length < 9 || docNumber.length > 12)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đúng số CMND (9 số) hoặc CCCD (12 số)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_frontImage == null || _backImage == null || _selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chụp đủ 3 ảnh: Mặt trước, Mặt sau và Chân dung Selfie'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    bool success;
    if (widget.isResubmit && widget.verificationId != null) {
      success = await ref.read(onboardingNotifierProvider.notifier).resubmitEkyc(
            verificationId: widget.verificationId!,
            frontImage: _frontImage!,
            backImage: _backImage!,
            selfieImage: _selfieImage,
          );
    } else {
      success = await ref.read(onboardingNotifierProvider.notifier).submitEkyc(
            documentNumber: docNumber,
            frontImage: _frontImage!,
            backImage: _backImage!,
            selfieImage: _selfieImage!,
          );
    }

    if (!success && mounted) {
      final err = ref.read(onboardingNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Lỗi khi nộp hồ sơ eKYC'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isResubmit ? 'Nộp lại Ảnh eKYC' : 'Bước 3: Định danh eKYC',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hệ thống đối soát ảnh CCCD với chân dung để cấp quyền Người bán uy tín.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          if (!widget.isResubmit) ...[
            SlTextField(
              label: 'Số Căn cước công dân (CCCD)',
              hint: '12 chữ số trên thẻ CCCD gắn chip',
              controller: _docNumberController,
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
          ],

          // 3 Photo Upload Cards
          _buildPhotoCard(
            title: '1. Ảnh CCCD Mặt Trước',
            subtitle: 'Rõ họ tên, số thẻ, không bị lóa đèn flash',
            file: _frontImage,
            icon: Icons.credit_card_rounded,
            onTap: () => _showImageSourceDialog((f) => _frontImage = f),
          ),
          const SizedBox(height: 14),

          _buildPhotoCard(
            title: '2. Ảnh CCCD Mặt Sau',
            subtitle: 'Rõ đặc điểm nhận dạng và mã vạch MRZ',
            file: _backImage,
            icon: Icons.credit_card_outlined,
            onTap: () => _showImageSourceDialog((f) => _backImage = f),
          ),
          const SizedBox(height: 14),

          _buildPhotoCard(
            title: '3. Ảnh Chân dung Selfie',
            subtitle: 'Chụp trực diện khuôn mặt, không đeo kính râm, đủ sáng',
            file: _selfieImage,
            icon: Icons.face_rounded,
            onTap: () => _showImageSourceDialog((f) => _selfieImage = f),
          ),
          const SizedBox(height: 28),

          SlButton(
            text: widget.isResubmit ? 'Nộp lại hồ sơ' : 'Gửi hồ sơ duyệt eKYC',
            isLoading: state.isLoading,
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard({
    required String title,
    required String subtitle,
    required File? file,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: file != null ? AppColors.success : AppColors.border,
            width: file != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 56,
              decoration: BoxDecoration(
                color: file != null ? null : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(10),
                image: file != null
                    ? DecorationImage(image: FileImage(file), fit: BoxFit.cover)
                    : null,
              ),
              child: file == null
                  ? Icon(icon, color: AppColors.primary, size: 28)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(
              file != null ? Icons.check_circle : Icons.camera_alt_outlined,
              color: file != null ? AppColors.success : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
