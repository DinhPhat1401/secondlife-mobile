import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/features/onboarding/domain/seller_verification_model.dart';
import 'package:secondlife_app_seller/features/onboarding/presentation/onboarding_providers.dart';
import 'package:secondlife_app_seller/features/onboarding/presentation/screens/steps/ekyc_camera_step.dart';
import 'package:secondlife_app_seller/features/onboarding/presentation/screens/steps/ekyc_status_view.dart';
import 'package:secondlife_app_seller/features/onboarding/presentation/screens/steps/email_verify_step.dart';
import 'package:secondlife_app_seller/features/onboarding/presentation/screens/steps/shop_info_step.dart';

class SellerOnboardingWizardScreen extends ConsumerWidget {
  const SellerOnboardingWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);

    return PopScope(
      canPop: state.step == 0 || state.step == 3,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // Go back one step
          ref.read(onboardingNotifierProvider.notifier).goToStep(state.step - 1);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Định danh Người bán'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (state.step > 0 && state.step < 3) {
                ref.read(onboardingNotifierProvider.notifier).goToStep(state.step - 1);
              } else {
                context.pop();
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Tải lại',
              onPressed: () => ref.read(onboardingNotifierProvider.notifier).loadState(),
            ),
          ],
        ),
        body: state.isLoading && state.onboarding == null
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải thông tin hồ sơ...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              )
            : Column(
                children: [
                  _buildStepperHeader(context, state.step),
                  Expanded(
                    child: _buildCurrentStepView(state),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStepperHeader(BuildContext context, int currentStep) {
    final steps = [
      {'title': 'Thông tin', 'subtitle': 'Kho hàng'},
      {'title': 'Xác thực', 'subtitle': 'Email'},
      {'title': 'eKYC', 'subtitle': 'CCCD & Mặt'},
      {'title': 'Trạng thái', 'subtitle': 'Xét duyệt'},
    ];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            final isPassed = currentStep > stepIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isPassed ? AppColors.primary : AppColors.border,
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isCurrent = currentStep == stepIndex;
          final isCompleted = currentStep > stepIndex;
          final step = steps[stepIndex];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.primary
                      : isCurrent
                          ? AppColors.primaryLight
                          : AppColors.divider,
                  border: Border.all(
                    color: (isCompleted || isCurrent)
                        ? AppColors.primary
                        : AppColors.border,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '${stepIndex + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isCurrent
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                step['title']!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent
                      ? AppColors.primary
                      : isCompleted
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepView(OnboardingFlowState state) {
    switch (state.step) {
      case 0:
        return const ShopInfoStep();
      case 1:
        return const EmailVerifyStep();
      case 2:
        return EkycCameraStep(
          isResubmit: state.verification?.status == VerificationStatus.resubmitRequired,
          verificationId: state.verification?.id,
        );
      case 3:
      default:
        return const EkycStatusView();
    }
  }
}
