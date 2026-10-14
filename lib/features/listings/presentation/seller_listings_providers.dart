import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/post_repository.dart';
import '../domain/post_models.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return PostRepository(client: client);
});

class SellerListingsState {
  final List<SellerListingItemModel> listings;
  final bool isLoading;
  final String selectedStatus;
  final String searchQuery;
  final String? errorMessage;
  final String? actionSuccessMessage;

  const SellerListingsState({
    this.listings = const [],
    this.isLoading = false,
    this.selectedStatus = 'ALL',
    this.searchQuery = '',
    this.errorMessage,
    this.actionSuccessMessage,
  });

  SellerListingsState copyWith({
    List<SellerListingItemModel>? listings,
    bool? isLoading,
    String? selectedStatus,
    String? searchQuery,
    String? errorMessage,
    String? actionSuccessMessage,
  }) {
    return SellerListingsState(
      listings: listings ?? this.listings,
      isLoading: isLoading ?? this.isLoading,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      actionSuccessMessage: actionSuccessMessage,
    );
  }

  List<SellerListingItemModel> get filteredListings {
    if (searchQuery.trim().isEmpty) return listings;
    final q = searchQuery.toLowerCase().trim();
    return listings.where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.description.toLowerCase().contains(q);
    }).toList();
  }
}

class SellerListingsNotifier extends Notifier<SellerListingsState> {
  @override
  SellerListingsState build() {
    Future.microtask(() => loadListings());
    return const SellerListingsState(isLoading: true);
  }

  PostRepository get _repository => ref.read(postRepositoryProvider);

  Future<void> loadListings({String? status}) async {
    final targetStatus = status ?? state.selectedStatus;
    state = state.copyWith(isLoading: true, selectedStatus: targetStatus, errorMessage: null);
    try {
      final items = await _repository.getMyPosts(status: targetStatus);
      state = state.copyWith(listings: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Không thể tải danh sách tin đăng. Vui lòng thử lại.',
      );
    }
  }

  void filterByStatus(String status) {
    loadListings(status: status);
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> boostListing(String postId) async {
    try {
      await _repository.boostListing(postId);
      state = state.copyWith(
        actionSuccessMessage: 'Đã đẩy tin thành công! Tin đăng được ưu tiên tiếp cận người mua.',
      );
      await loadListings();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteListing(String postId) async {
    try {
      await _repository.deletePost(postId);
      state = state.copyWith(
        listings: state.listings.where((item) => item.id != postId).toList(),
        actionSuccessMessage: 'Đã gỡ bài đăng thành công.',
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

final sellerListingsNotifierProvider =
    NotifierProvider<SellerListingsNotifier, SellerListingsState>(
  SellerListingsNotifier.new,
);
