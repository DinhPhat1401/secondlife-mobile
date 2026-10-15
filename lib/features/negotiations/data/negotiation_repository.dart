import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secondlife_app_seller/features/auth/presentation/auth_providers.dart';
import '../../../core/network/api_client.dart';
import '../domain/negotiation_model.dart';

final negotiationRepositoryProvider = Provider<NegotiationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NegotiationRepository(apiClient);
});

class NegotiationRepository {
  final ApiClient _client;

  NegotiationRepository(this._client);

  Future<List<NegotiationModel>> getSellerNegotiations({int page = 0, int size = 20}) async {
    final response = await _client.get('/api/v1/negotiations/seller?page=$page&size=$size');
    final raw = response.data;
    final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;

    List list = [];
    if (data is Map && data.containsKey('content') && data['content'] is List) {
      list = data['content'] as List;
    } else if (data is Map && data.containsKey('items') && data['items'] is List) {
      list = data['items'] as List;
    } else if (data is List) {
      list = data;
    }

    return list.map((item) => NegotiationModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<NegotiationModel> acceptNegotiation(String negotiationId) async {
    final response = await _client.put('/api/v1/negotiations/$negotiationId/accept');
    final raw = response.data;
    final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
    return NegotiationModel.fromJson(data as Map<String, dynamic>);
  }

  Future<NegotiationModel> rejectNegotiation(String negotiationId) async {
    final response = await _client.put('/api/v1/negotiations/$negotiationId/reject');
    final raw = response.data;
    final data = (raw is Map && raw.containsKey('data')) ? raw['data'] : raw;
    return NegotiationModel.fromJson(data as Map<String, dynamic>);
  }
}
