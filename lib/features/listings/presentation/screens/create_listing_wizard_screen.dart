import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import '../create_listing_providers.dart';
import 'steps/step1_photos_init.dart';
import 'steps/step2_ai_chat.dart';
import 'steps/step3_product_specs.dart';
import 'steps/step4_ai_pricing.dart';
import 'steps/step5_shipping_package.dart';
import 'steps/step6_review_submit.dart';

class CreateListingWizardScreen extends ConsumerWidget {
  const CreateListingWizardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createListingNotifierProvider);

    return PopScope(
      canPop: state.step == 0 || state.isSubmitted,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && state.step > 0) {
          ref.read(createListingNotifierProvider.notifier).goToStep(state.step - 1);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Đăng Bán Đồ Gia Dụng'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (state.step > 0 && !state.isSubmitted) {
                ref.read(createListingNotifierProvider.notifier).goToStep(state.step - 1);
              } else {
                context.pop();
              }
            },
          ),
          actions: [
            if (!state.isSubmitted)
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Làm mới từ đầu',
                onPressed: () {
                  ref.read(createListingNotifierProvider.notifier).reset();
                },
              ),
          ],
        ),
        body: Column(
          children: [
            if (!state.isSubmitted) _buildStepperHeader(state.step),
            Expanded(child: _buildStepContent(state.step)),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader(int currentStep) {
    final stepLabels = [
      'Ảnh',
      'AI Chat',
      'Thông số',
      'Định giá',
      'Đóng gói',
      'Đăng bài',
    ];

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: List.generate(stepLabels.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIdx = index ~/ 2;
            final isPassed = currentStep > stepIdx;
            return Expanded(
              child: Container(
                height: 2,
                color: isPassed ? AppColors.primary : AppColors.divider,
              ),
            );
          }

          final stepIdx = index ~/ 2;
          final isCurrent = currentStep == stepIdx;
          final isCompleted = currentStep > stepIdx;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? AppColors.primary
                      : isCurrent
                          ? AppColors.primaryLight
                          : AppColors.divider,
                  border: Border.all(
                    color: (isCompleted || isCurrent) ? AppColors.primary : AppColors.border,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text(
                          '${stepIdx + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                stepLabels[stepIdx],
                style: TextStyle(
                  fontSize: 10,
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

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return const Step1PhotosInit();
      case 1:
        return const Step2AiChat();
      case 2:
        return const Step3ProductSpecs();
      case 3:
        return const Step4AiPricing();
      case 4:
        return const Step5ShippingPackage();
      case 5:
      default:
        return const Step6ReviewSubmit();
    }
  }
}
