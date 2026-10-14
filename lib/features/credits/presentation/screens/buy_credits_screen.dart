import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_button.dart';
import 'package:secondlife_app_seller/features/credits/presentation/credit_providers.dart';

class BuyCreditsScreen extends ConsumerStatefulWidget {
  const BuyCreditsScreen({super.key});

  @override
  ConsumerState<BuyCreditsScreen> createState() => _BuyCreditsScreenState();
}

class _BuyCreditsScreenState extends ConsumerState<BuyCreditsScreen> {
  int _listingQty = 5;
  int _valuationQty = 5;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(creditNotifierProvider.notifier).updateQuote(
            listingQty: _listingQty,
            valuationQty: _valuationQty,
          );
    });
  }

  void _updateQuantity(int newListing, int newValuation) {
    setState(() {
      _listingQty = newListing.clamp(0, 100);
      _valuationQty = newValuation.clamp(0, 100);
    });
    ref.read(creditNotifierProvider.notifier).updateQuote(
          listingQty: _listingQty,
          valuationQty: _valuationQty,
        );
  }

  void _applyCombo(int listing, int valuation) {
    _updateQuantity(listing, valuation);
  }

  Future<void> _handlePurchase() async {
    if (_listingQty == 0 && _valuationQty == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất 1 lượt đăng tin hoặc định giá'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final purchase = await ref.read(creditNotifierProvider.notifier).purchaseCredits(
          listingQty: _listingQty,
          valuationQty: _valuationQty,
        );

    if (purchase != null && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppColors.success, size: 28),
              SizedBox(width: 10),
              Text('Mua gói thành công!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bạn đã bổ sung thành công:',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                '• +$_listingQty lượt đăng bài gia dụng',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '• +$_valuationQty lượt định giá AI thông minh',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Tổng chi phí: ${_currencyFormat.format(purchase.snapshot.finalFee)}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.pop(); // Go back to caller
              },
              child: const Text('Đồng ý', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else if (mounted) {
      final err = ref.read(creditNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Lỗi khi thanh toán gói tín dụng'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(creditNotifierProvider);
    final quote = state.quote;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mua Gói Tín Dụng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Lịch sử biến động tín dụng',
            onPressed: () => context.push('/credits/ledger'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current Balance Card
            _buildBalanceCard(state.balance),
            const SizedBox(height: 20),

            // Combo Packages
            const Text(
              'Gói Combo Đề Xuất (Ưu đãi chiết khấu)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildComboRow(),
            const SizedBox(height: 24),

            // Custom Quantities
            const Text(
              'Tùy chỉnh số lượng theo nhu cầu',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCounterItem(
              title: 'Lượt Đăng Tin Bán Đồ Gia Dụng',
              subtitle: 'Đơn giá: ${_currencyFormat.format(quote.listingUnitPrice)} / lượt',
              icon: Icons.post_add_rounded,
              value: _listingQty,
              onChanged: (val) => _updateQuantity(val, _valuationQty),
            ),
            const SizedBox(height: 12),
            _buildCounterItem(
              title: 'Lượt Định Giá AI Thông Minh',
              subtitle: 'Đơn giá: ${_currencyFormat.format(quote.valuationUnitPrice)} / lượt',
              icon: Icons.psychology_outlined,
              value: _valuationQty,
              onChanged: (val) => _updateQuantity(_listingQty, val),
            ),
            const SizedBox(height: 24),

            // Quote Breakdown
            _buildQuoteCard(quote),
            const SizedBox(height: 24),

            // Submit Button
            SlButton(
              text: 'Xác Nhận Mua Gói (${_currencyFormat.format(quote.finalFee)})',
              icon: const Icon(Icons.shopping_cart_checkout, color: Colors.white, size: 20),
              isLoading: state.isLoading,
              onPressed: _handlePurchase,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(dynamic balance) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Số dư tín dụng khả dụng',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.post_add, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${balance.postCredits}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text('Lượt đăng bài', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppColors.info, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${balance.valuationCredits}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text('Lượt định giá AI', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComboRow() {
    final combos = [
      {'name': 'Gói Khởi Đầu', 'listing': 5, 'valuation': 5, 'tag': null},
      {'name': 'Gói Tiết Kiệm', 'listing': 10, 'valuation': 10, 'tag': 'Giảm 10%'},
      {'name': 'Gói Chuyên Nghiệp', 'listing': 20, 'valuation': 20, 'tag': 'Giảm 15%'},
    ];

    return Row(
      children: combos.map((c) {
        final isSelected = _listingQty == c['listing'] && _valuationQty == c['valuation'];
        return Expanded(
          child: GestureDetector(
            onTap: () => _applyCombo(c['listing'] as int, c['valuation'] as int),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Column(
                children: [
                  if (c['tag'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c['tag'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  Text(
                    c['name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${c['listing']} bài + ${c['valuation']} AI',
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCounterItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required int value,
    required Function(int) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: value > 0 ? AppColors.textPrimary : AppColors.textMuted,
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
              ),
              Text(
                '$value',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(dynamic quote) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tạm tính', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              Text(_currencyFormat.format(quote.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          if (quote.discountRate > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chiết khấu combo (${(quote.discountRate * 100).round()}%)',
                  style: const TextStyle(color: AppColors.success, fontSize: 13),
                ),
                Text(
                  '-${_currencyFormat.format(quote.discountAmount)}',
                  style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng thanh toán',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                _currencyFormat.format(quote.finalFee),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
