import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/features/credits/presentation/credit_providers.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_text_field.dart';
import 'package:secondlife_app_seller/features/listings/presentation/create_listing_providers.dart';

class Step4AiPricing extends ConsumerStatefulWidget {
  const Step4AiPricing({super.key});

  @override
  ConsumerState<Step4AiPricing> createState() => _Step4AiPricingState();
}

class _Step4AiPricingState extends ConsumerState<Step4AiPricing> {
  final _priceController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    final state = ref.read(createListingNotifierProvider);
    if (state.userPriceVnd > 0) {
      _priceController.text = state.userPriceVnd.toInt().toString();
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _applyPrice(double price) {
    setState(() {
      _priceController.text = price.toInt().toString();
    });
    ref.read(createListingNotifierProvider.notifier).setUserPrice(price);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createListingNotifierProvider);
    final creditState = ref.watch(creditNotifierProvider);
    final est = state.priceEstimation;
    final hasValuationCredits = creditState.balance.valuationCredits > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Credits status banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: hasValuationCredits ? AppColors.infoLight : AppColors.warningLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasValuationCredits ? AppColors.info : AppColors.warning,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasValuationCredits ? Icons.auto_awesome : Icons.warning_amber_rounded,
                  color: hasValuationCredits ? AppColors.info : AppColors.warning,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Số dư: ${creditState.balance.valuationCredits} lượt định giá AI',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        hasValuationCredits
                            ? 'Mỗi lần chạy thuật toán định giá sẽ sử dụng 1 Valuation Credit.'
                            : 'Bạn đã hết lượt định giá AI. Vui lòng nạp thêm để tiếp tục.',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!hasValuationCredits)
                  TextButton(
                    onPressed: () => context.push('/credits/buy'),
                    child: const Text('Mua thêm', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Run AI Estimation Button
          SlButton(
            text: est == null ? 'Chạy Định Giá AI Thị Trường (-1 Credit)' : 'Định Giá Lại (-1 Credit)',
            icon: const Icon(Icons.psychology_outlined, color: Colors.white, size: 20),
            isLoading: state.isLoading,
            onPressed: hasValuationCredits
                ? () async {
                    await ref.read(createListingNotifierProvider.notifier).estimatePrice();
                    final updatedEst = ref.read(createListingNotifierProvider).priceEstimation;
                    if (updatedEst != null && updatedEst.estimatedPrice > 0) {
                      _applyPrice(updatedEst.estimatedPrice);
                    }
                  }
                : null,
          ),
          const SizedBox(height: 20),

          // AI Estimation Results Card
          if (est != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Kết Quả Định Giá AI',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Độ tin cậy ${(est.confidence * 100).round()}%',
                          style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Recommended Price
                  Center(
                    child: Column(
                      children: [
                        const Text(
                          'Giá khuyến nghị thanh lý nhanh',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currencyFormat.format(est.estimatedPrice),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Min-Max Range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Khoảng giá thấp', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            _currencyFormat.format(est.priceMin),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward, size: 16, color: AppColors.textMuted),
                      Column(
                        children: [
                          const Text('Khoảng giá cao', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            _currencyFormat.format(est.priceMax),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),

                  if (est.reasoning.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Phân tích: ${est.reasoning}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Áp dụng mức giá khuyến nghị này'),
                      onPressed: () => _applyPrice(est.estimatedPrice),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          SlTextField(
            label: 'Giá Bán Mong Muốn Của Bạn (VNĐ) *',
            hint: 'VD: 850000',
            controller: _priceController,
            keyboardType: TextInputType.number,
            onChanged: (val) {
              final num = double.tryParse(val) ?? 0.0;
              ref.read(createListingNotifierProvider.notifier).setUserPrice(num);
            },
          ),
          const SizedBox(height: 24),

          // Next Step Button
          SlButton(
            text: 'Tiếp Tục: Kích Thước Kiện Hàng',
            icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            onPressed: () {
              final price = double.tryParse(_priceController.text) ?? 0.0;
              if (price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập giá bán lớn hơn 0'), backgroundColor: AppColors.error),
                );
                return;
              }
              ref.read(createListingNotifierProvider.notifier).setUserPrice(price);
              ref.read(createListingNotifierProvider.notifier).goToStep(4);
            },
          ),
        ],
      ),
    );
  }
}
