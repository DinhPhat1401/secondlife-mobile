import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:secondlife_app_seller/core/theme/app_colors.dart';
import 'package:secondlife_app_seller/shared/widgets/sl_badge.dart';
import '../../domain/order_models.dart';
import '../order_providers.dart';

class SellerOrdersScreen extends ConsumerStatefulWidget {
  const SellerOrdersScreen({super.key});

  @override
  ConsumerState<SellerOrdersScreen> createState() => _SellerOrdersScreenState();
}

class _SellerOrdersScreenState extends ConsumerState<SellerOrdersScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  final List<({String label, OrderStatus? status})> _tabs = [
    (label: 'Tất cả', status: null),
    (label: 'Chờ xử lý', status: OrderStatus.pending),
    (label: 'Đang giao', status: OrderStatus.shipping),
    (label: 'Hoàn tất', status: OrderStatus.delivered),
    (label: 'Đã hủy', status: OrderStatus.cancelled),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        final selectedTab = _tabs[_tabController.index];
        ref.read(orderListNotifierProvider.notifier).loadOrders(status: selectedTab.status);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showCancelDialog(BuildContext context, String orderId) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hủy Đơn Hàng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bạn có chắc chắn muốn hủy đơn hàng này? Tiền ký quỹ sẽ được hoàn trả 100% cho người mua.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do hủy (hết hàng, người mua đổi ý)...',
                hintStyle: TextStyle(fontSize: 12),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(orderListNotifierProvider.notifier)
                  .cancelOrder(orderId, reasonController.text.trim());
              if (context.mounted && !success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lỗi khi hủy đơn hàng'), backgroundColor: AppColors.error),
                );
              }
            },
            child: const Text('Xác nhận hủy', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderListNotifierProvider);
    final orders = state.orders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quản Lý Đơn Hàng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () {
              final selectedTab = _tabs[_tabController.index];
              ref.read(orderListNotifierProvider.notifier).loadOrders(status: selectedTab.status);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: state.isLoading && orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Không có đơn hàng nào trong mục này',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return _buildOrderCard(order);
                  },
                ),
    );
  }

  Widget _buildOrderCard(SellerOrderModel order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Code & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đơn #${order.orderNumber ?? (order.id.length > 8 ? order.id.substring(0, 8) : order.id)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              _buildStatusBadge(order.status),
            ],
          ),
          const Divider(height: 20),

          // Product Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: order.postThumbnail != null
                    ? Image.network(
                        order.postThumbnail!,
                        width: 64,
                        height: 64,
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
                      order.postTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Người mua: ${order.buyerName} • ${order.buyerPhone}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    if (order.deliveryAddress != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Giao tới: ${order.deliveryAddress!.fullAddressText}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Payout Calculation Row
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Giá bán hàng', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text(_currencyFormat.format(order.itemPrice), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Phí sàn', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text('-${_currencyFormat.format(order.platformFee)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.error)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Thực nhận vào Ví', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                    Text(_currencyFormat.format(order.netPayout), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (order.status == OrderStatus.pending) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onPressed: () => _showCancelDialog(context, order.id),
                  child: const Text('Hủy Đơn', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.local_shipping_outlined, color: Colors.white, size: 16),
                  label: const Text('Bàn Giao Shipper', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  onPressed: () async {
                    final success = await ref
                        .read(orderListNotifierProvider.notifier)
                        .markAsShipped(order.id);
                    if (mounted && success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã cập nhật trạng thái giao cho shipper'), backgroundColor: AppColors.success),
                      );
                    }
                  },
                ),
              ] else if (order.status == OrderStatus.shipping || order.status == OrderStatus.delivered) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  icon: const Icon(Icons.route_outlined, color: Colors.white, size: 16),
                  label: const Text('Theo Dõi Vận Đơn', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  onPressed: () {
                    final shipmentId = order.shipmentId ?? order.id;
                    context.push('/shipments/$shipmentId/tracking');
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.divider,
      child: const Icon(Icons.kitchen_outlined, color: AppColors.textMuted, size: 28),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return SlBadge.warning('Chờ xác nhận');
      case OrderStatus.confirmed:
        return SlBadge.info('Đã xác nhận');
      case OrderStatus.shipping:
        return SlBadge.info('Đang giao hàng');
      case OrderStatus.delivered:
        return SlBadge.success('Đã giao thành công');
      case OrderStatus.cancelled:
        return SlBadge.error('Đã hủy');
      default:
        return SlBadge.neutral(status.label);
    }
  }
}
