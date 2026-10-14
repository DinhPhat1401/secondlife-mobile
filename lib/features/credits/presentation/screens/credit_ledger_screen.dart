import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/features/credits/presentation/credit_providers.dart';

class CreditLedgerScreen extends ConsumerStatefulWidget {
  const CreditLedgerScreen({super.key});

  @override
  ConsumerState<CreditLedgerScreen> createState() => _CreditLedgerScreenState();
}

class _CreditLedgerScreenState extends ConsumerState<CreditLedgerScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(creditNotifierProvider.notifier).loadLedger();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creditNotifierProvider);
    final ledger = state.ledger;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lịch Sử Biến Động Tín Dụng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () => ref.read(creditNotifierProvider.notifier).loadLedger(),
          ),
        ],
      ),
      body: state.isLoading && ledger.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ledger.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_toggle_off_rounded, size: 48, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text(
                        'Chưa có lịch sử giao dịch tín dụng nào',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: ledger.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = ledger[index];
                    final isListing = item.creditType == 'LISTING';
                    final isPositive = item.isPositive;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.warning.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPositive ? Icons.add_rounded : Icons.remove_rounded,
                              color: isPositive ? AppColors.success : AppColors.warning,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.entryTypeLabel,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Loại: ${isListing ? "Lượt đăng tin" : "Định giá AI"} • Sau GD: ${item.balanceAfter}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                if (item.createdAt.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.createdAt,
                                    style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            isPositive ? '+${item.quantityDelta}' : '${item.quantityDelta}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPositive ? AppColors.success : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
