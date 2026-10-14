import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/features/onboarding/domain/seller_verification_model.dart';
import 'package:secondlife_app_seller/features/onboarding/presentation/onboarding_providers.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';

class EkycStatusView extends ConsumerWidget {
  const EkycStatusView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingNotifierProvider);
    final verification = state.verification;
    final status = verification?.status ?? VerificationStatus.unknown;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStatusHeader(context, status, verification),
          const SizedBox(height: 24),
          _buildDetailsCard(context, verification),
          const SizedBox(height: 24),
          _buildActionButtons(context, ref, status, verification),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(
    BuildContext context,
    VerificationStatus status,
    SellerVerificationModel? verification,
  ) {
    Color iconColor;
    Color bgColor;
    IconData iconData;
    String title;
    String subtitle;

    switch (status) {
      case VerificationStatus.approved:
        iconColor = AppColors.success;
        bgColor = AppColors.success.withValues(alpha: 0.12);
        iconData = Icons.check_circle_rounded;
        title = 'Đã phê duyệt người bán';
        subtitle =
            'Chúc mừng! Tài khoản của bạn đã được chứng thực. Bạn đã có đầy đủ quyền đăng bán và quản lý đơn hàng.';
        break;

      case VerificationStatus.resubmitRequired:
        iconColor = AppColors.warning;
        bgColor = AppColors.warning.withValues(alpha: 0.12);
        iconData = Icons.report_problem_rounded;
        title = 'Cần nộp lại ảnh giấy tờ';
        subtitle = verification?.rejectionReason ??
            'Hình ảnh giấy tờ hoặc chân dung chưa đạt chuẩn (mờ, lóa sáng hoặc mất góc). Vui lòng chụp lại.';
        break;

      case VerificationStatus.rejected:
        iconColor = AppColors.error;
        bgColor = AppColors.error.withValues(alpha: 0.12);
        iconData = Icons.cancel_rounded;
        title = 'Hồ sơ bị từ chối';
        subtitle = verification?.rejectionReason ??
            'Hồ sơ của bạn không đáp ứng điều kiện tiêu chuẩn người bán SecondLife.';
        break;

      case VerificationStatus.needsReview:
        iconColor = const Color(0xFF3B82F6);
        bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.12);
        iconData = Icons.assignment_turned_in_rounded;
        title = 'Chờ thẩm định thủ công';
        subtitle =
            'Hồ sơ của bạn đang được chuyên viên SecondLife xem xét kỹ lưỡng. Dự kiến hoàn tất trong 2-4 giờ làm việc.';
        break;

      case VerificationStatus.submitted:
      case VerificationStatus.ekycPending:
      default:
        iconColor = AppColors.primary;
        bgColor = AppColors.primary.withValues(alpha: 0.12);
        iconData = Icons.hourglass_top_rounded;
        title = 'Đang kiểm tra AI eKYC';
        subtitle =
            'Hệ thống AI đang tự động phân tích và đối soát khuôn mặt với ảnh CCCD của bạn. Vui lòng chờ giây lát.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(iconData, size: 48, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    SellerVerificationModel? verification,
  ) {
    if (verification == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin thẩm định hồ sơ',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Divider(height: 24),
          _buildInfoRow('Mã hồ sơ', '#${verification.id.isNotEmpty ? verification.id.substring(0, verification.id.length.clamp(0, 8)) : "---"}'),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Số CCCD/CMND',
            verification.documentNumberMasked ??
                (verification.documentNumber.length > 4
                    ? '******${verification.documentNumber.substring(verification.documentNumber.length - 4)}'
                    : verification.documentNumber),
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Trạng thái', verification.status.label),
          if (verification.submittedAt != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow('Thời gian gửi', verification.submittedAt!),
          ],
          if (verification.resubmissionCount > 0) ...[
            const SizedBox(height: 10),
            _buildInfoRow('Số lần nộp lại', '${verification.resubmissionCount} lần'),
          ],
          if (verification.rejectionReason != null &&
              verification.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lý do từ chối: ${verification.rejectionReason}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    VerificationStatus status,
    SellerVerificationModel? verification,
  ) {
    final state = ref.watch(onboardingNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status == VerificationStatus.approved) ...[
          SlButton(
            text: 'Vào Trang Bán Hàng',
            icon: const Icon(Icons.dashboard_outlined, size: 20, color: Colors.white),
            onPressed: () => context.go('/dashboard'),
          ),
          const SizedBox(height: 12),
          SlButton(
            text: 'Đăng Sản Phẩm Mới',
            type: SlButtonType.outline,
            icon: const Icon(Icons.add_photo_alternate_outlined, size: 20, color: AppColors.primary),
            onPressed: () => context.push('/create-listing'),
          ),
        ] else if (status == VerificationStatus.resubmitRequired) ...[
          SlButton(
            text: 'Chụp Lại Ảnh Ngay',
            icon: const Icon(Icons.camera_alt_outlined, size: 20, color: Colors.white),
            onPressed: () {
              // Go to step 2 with resubmit state
              ref.read(onboardingNotifierProvider.notifier).goToStep(2);
            },
          ),
          const SizedBox(height: 12),
          SlButton(
            text: 'Về Trang Chủ',
            type: SlButtonType.outline,
            onPressed: () => context.go('/dashboard'),
          ),
        ] else if (status == VerificationStatus.rejected) ...[
          SlButton(
            text: 'Bắt Đầu Lại Từ Bước 1',
            icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
            onPressed: () {
              ref.read(onboardingNotifierProvider.notifier).goToStep(0);
            },
          ),
          const SizedBox(height: 12),
          SlButton(
            text: 'Về Trang Chủ',
            type: SlButtonType.outline,
            onPressed: () => context.go('/dashboard'),
          ),
        ] else ...[
          // Pending or Needs Review
          SlButton(
            text: 'Cập Nhật Trạng Thái',
            icon: const Icon(Icons.refresh, size: 20, color: Colors.white),
            isLoading: state.isLoading,
            onPressed: () =>
                ref.read(onboardingNotifierProvider.notifier).loadState(),
          ),
          const SizedBox(height: 12),
          SlButton(
            text: 'Về Trang Chủ',
            type: SlButtonType.outline,
            onPressed: () => context.go('/dashboard'),
          ),
        ],
      ],
    );
  }
}
