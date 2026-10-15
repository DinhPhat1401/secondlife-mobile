import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/negotiation_repository.dart';
import '../domain/negotiation_model.dart';

class NegotiationsState {
  final bool isLoading;
  final String? errorMessage;
  final List<NegotiationModel> negotiations;

  const NegotiationsState({
    this.isLoading = false,
    this.errorMessage,
    this.negotiations = const [],
  });

  NegotiationsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<NegotiationModel>? negotiations,
  }) {
    return NegotiationsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      negotiations: negotiations ?? this.negotiations,
    );
  }
}

final sellerNegotiationsNotifierProvider =
    NotifierProvider<SellerNegotiationsNotifier, NegotiationsState>(SellerNegotiationsNotifier.new);

class SellerNegotiationsNotifier extends Notifier<NegotiationsState> {
  @override
  NegotiationsState build() {
    final userId = ref.watch(authNotifierProvider.select((s) => s.user?.id));
    if (userId != null && userId.isNotEmpty) {
      Future.microtask(() => fetchNegotiations());
      return const NegotiationsState(isLoading: true);
    }
    return const NegotiationsState();
  }

  NegotiationRepository get _repository => ref.read(negotiationRepositoryProvider);

  Future<void> fetchNegotiations() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repository.getSellerNegotiations();
      state = state.copyWith(isLoading: false, negotiations: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> acceptNegotiation(String id) async {
    try {
      final updated = await _repository.acceptNegotiation(id);
      final updatedList =
          state.negotiations.map((item) => item.id == id ? updated : item).toList();
      state = state.copyWith(negotiations: updatedList);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectNegotiation(String id) async {
    try {
      final updated = await _repository.rejectNegotiation(id);
      final updatedList =
          state.negotiations.map((item) => item.id == id ? updated : item).toList();
      state = state.copyWith(negotiations: updatedList);
      return true;
    } catch (e) {
      return false;
    }
  }
}
