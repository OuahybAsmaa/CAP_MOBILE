// =============================================================================
// CapMobile — Provider Riverpod recherche client
// -----------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'client_service.dart';
import 'models/client_item.dart';

class ClientSearchState {
  final List<ClientItem> results;
  final bool isLoading;
  final bool hasSearched;
  final String? error;
  final ClientSearchQuery? lastQuery;

  const ClientSearchState({
    this.results = const [],
    this.isLoading = false,
    this.hasSearched = false,
    this.error,
    this.lastQuery,
  });

  ClientSearchState copyWith({
    List<ClientItem>? results,
    bool? isLoading,
    bool? hasSearched,
    String? error,
    ClientSearchQuery? lastQuery,
    bool clearError = false,
    bool clearResults = false,
  }) {
    return ClientSearchState(
      results: clearResults ? const [] : results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      hasSearched: hasSearched ?? this.hasSearched,
      error: clearError ? null : error ?? this.error,
      lastQuery: lastQuery ?? this.lastQuery,
    );
  }
}

class ClientSearchNotifier extends StateNotifier<ClientSearchState> {
  ClientSearchNotifier(this._service) : super(const ClientSearchState());

  final ClientService _service;

  Future<void> search(ClientSearchQuery query) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      lastQuery: query,
      hasSearched: true,
    );

    try {
      final results = await _service.searchClients(query);
      state = state.copyWith(
        results: results,
        isLoading: false,
        hasSearched: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasSearched: true,
        error: e.toString().replaceFirst('Exception: ', ''),
        clearResults: true,
      );
    }
  }

  void reset() {
    state = const ClientSearchState();
  }

  /// Retour au formulaire sans effacer les champs saisis (page parent).
  void backToForm() {
    state = state.copyWith(
      hasSearched: false,
      clearError: true,
    );
  }
}

final clientServiceProvider = Provider<ClientService>((ref) {
  return ClientService();
});

final clientSearchProvider =
    StateNotifierProvider<ClientSearchNotifier, ClientSearchState>((ref) {
  return ClientSearchNotifier(ref.watch(clientServiceProvider));
});
