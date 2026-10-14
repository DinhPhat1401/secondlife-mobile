import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/sl_badge.dart';
import '../../domain/negotiation_model.dart';
import '../negotiation_providers.dart';

class SellerNegotiationsScreen extends ConsumerStatefulWidget {
  const SellerNegotiationsScreen({super.key});

  @override
  ConsumerState<SellerNegotiationsScreen> createState() => _SellerNegotiationsScreenState();
}

class _SellerNegotiationsScreenState extends ConsumerState<SellerNegotiationsScreen> {
  String _activeFilter = 'ALL'; // ALL, PENDING, ACCEPTED, REJECTED

  final NumberFormat _currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerNegotiationsNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Thương Lượng Giá',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(sellerNegotiationsNotifierProvider.notifier).fetchNegotiations(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: _buildBody(state),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(NegotiationsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text('Lỗi: ${state.errorMessage}', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  ref.read(sellerNegotiationsNotifierProvider.notifier).fetchNegotiations(),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    final filtered = state.negotiations.where((item) {
      if (_activeFilter == 'ALL') return true;
      return item.status.toUpperCase() == _activeFilter;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.handshake_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'Chưa có yêu cầu thương lượng nào',
              style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          ref.read(sellerNegotiationsNotifierProvider.notifier).fetchNegotiations(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildNegotiationCard(filtered[index]);
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'Tất cả', 'value': 'ALL'},
      {'label': 'Chờ phản hồi', 'value': 'PENDING'},
      {'label': 'Đã đồng ý', 'value': 'ACCEPTED'},
      {'label': 'Đã từ chối', 'value': 'REJECTED'},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = _activeFilter == f['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(f['label']!),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                backgroundColor: AppColors.background,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                onSelected: (_) => setState(() => _activeFilter = f['value']!),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNegotiationCard(NegotiationModel n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: n.productImageUrl != null && n.productImageUrl!.isNotEmpty
                    ? Image.network(
                        n.productImageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.postTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          n.buyerName,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildStatusBadge(n.status),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (n.originalPrice != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Giá niêm yết:', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text(
                      _currencyFormatter.format(n.originalPrice),
                      style: const TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.lineThrough,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Giá đề xuất mặc cả:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  Row(
                    children: [
                      Text(
                        _currencyFormatter.format(n.offeredPrice),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (n.discountPercentage != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.errorLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '-${n.discountPercentage!.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.error),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (n.isPending) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _handleReject(n.id),
                    child: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () => _handleAccept(n.id),
                    child: const Text('Đồng ý bán', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ] else if (n.isAccepted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn đã đồng ý mức giá này. Chờ người mua thanh toán đặt cọc.',
                      style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w500),
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

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      color: AppColors.divider,
      child: const Icon(Icons.kitchen_outlined, color: AppColors.textMuted, size: 28),
    );
  }

  Widget _buildStatusBadge(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return SlBadge.warning('Chờ phản hồi');
      case 'ACCEPTED':
        return SlBadge.success('Đã đồng ý');
      case 'REJECTED':
        return SlBadge.error('Đã từ chối');
      case 'CANCELLED':
        return SlBadge.neutral('Đã hủy');
      case 'EXPIRED':
        return SlBadge.neutral('Hết hạn');
      default:
        return SlBadge.neutral(status);
    }
  }

  Future<void> _handleAccept(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chấp thuận giá thương lượng?'),
        content: const Text('Người mua sẽ được phép thanh toán đơn hàng với mức giá đề xuất này.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đồng ý', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(sellerNegotiationsNotifierProvider.notifier).acceptNegotiation(id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã chấp thuận thương lượng thành công!'), backgroundColor: AppColors.success),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể chấp thuận thương lượng'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _handleReject(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối giá thương lượng?'),
        content: const Text('Yêu cầu trả giá này sẽ bị hủy bỏ.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Đóng')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Từ chối', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(sellerNegotiationsNotifierProvider.notifier).rejectNegotiation(id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã từ chối đề xuất thương lượng'), backgroundColor: AppColors.textSecondary),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Có lỗi xảy ra khi từ chối thương lượng'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }
}
