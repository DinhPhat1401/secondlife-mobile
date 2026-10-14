import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/features/auth/presentation/auth_providers.dart';
import '../data/order_repository.dart';
import '../domain/order_models.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return OrderRepository(client: client);
});

class OrderListState {
  final bool isLoading;
  final String? errorMessage;
  final OrderStatus? selectedStatus;
  final List<SellerOrderModel> orders;

  const OrderListState({
    this.isLoading = false,
    this.errorMessage,
    this.selectedStatus,
    this.orders = const [],
  });

  OrderListState copyWith({
    bool? isLoading,
    String? errorMessage,
    OrderStatus? selectedStatus,
    bool clearStatus = false,
    List<SellerOrderModel>? orders,
  }) {
    return OrderListState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      orders: orders ?? this.orders,
    );
  }
}

class OrderListNotifier extends Notifier<OrderListState> {
  @override
  OrderListState build() {
    Future.microtask(() => loadOrders());
    return const OrderListState(isLoading: true);
  }

  OrderRepository get _repo => ref.read(orderRepositoryProvider);

  Future<void> loadOrders({OrderStatus? status}) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      selectedStatus: status,
      clearStatus: status == null,
    );
    try {
      final page = await _repo.getSellerOrders(status: status, page: 0, size: 50);
      state = state.copyWith(
        isLoading: false,
        orders: page.items,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> markAsShipped(String orderId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.markAsShipped(orderId);
      await loadOrders(status: state.selectedStatus);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> cancelOrder(String orderId, [String? reason]) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repo.cancelOrder(orderId, reason);
      await loadOrders(status: state.selectedStatus);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final orderListNotifierProvider =
    NotifierProvider<OrderListNotifier, OrderListState>(OrderListNotifier.new);
