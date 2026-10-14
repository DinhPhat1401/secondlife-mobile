import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/features/onboarding/presentation/onboarding_providers.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_text_field.dart';

class EmailVerifyStep extends ConsumerStatefulWidget {
  const EmailVerifyStep({super.key});

  @override
  ConsumerState<EmailVerifyStep> createState() => _EmailVerifyStepState();
}

class _EmailVerifyStepState extends ConsumerState<EmailVerifyStep> {
  final _otpController = TextEditingController();
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        t.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đủ 6 chữ số OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(onboardingNotifierProvider.notifier).verifyShopOtp(otp);
    if (!success && mounted) {
      final err = ref.read(onboardingNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Mã xác thực không hợp lệ'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleResend() async {
    if (_countdown > 0) return;
    try {
      final repo = ref.read(onboardingRepositoryProvider);
      await repo.sendShopEmailOtp();
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lại mã xác thực mới vào email shop.'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingNotifierProvider);
    final email = state.onboarding?.email ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bước 2: Xác nhận Email Cửa hàng',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Mã OTP 6 số đã được gửi tới email:\n$email',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),

          SlTextField(
            label: 'Mã xác thực OTP',
            hint: '123456',
            controller: _otpController,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.security_outlined, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),

          SlButton(
            text: 'Xác thực & Sang bước eKYC',
            isLoading: state.isLoading,
            onPressed: _handleVerify,
          ),
          const SizedBox(height: 16),

          Center(
            child: TextButton(
              onPressed: _countdown == 0 ? _handleResend : null,
              child: Text(
                _countdown > 0 ? 'Gửi lại mã sau ${_countdown}s' : 'Gửi lại mã xác thực OTP',
                style: TextStyle(
                  color: _countdown > 0 ? AppColors.textMuted : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Quay lại sửa thông tin shop'),
              onPressed: () => ref.read(onboardingNotifierProvider.notifier).goToStep(0),
            ),
          ),
        ],
      ),
    );
  }
}
