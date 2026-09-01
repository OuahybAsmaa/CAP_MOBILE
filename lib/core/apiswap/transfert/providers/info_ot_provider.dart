// =============================================================================
// CapMobile — API Swapp — Provider Info OT
// -----------------------------------------------------------------------------
// Fonctionnalité : État liste ordres de transfert (OT) par magasin.
// Design         : StateNotifier Riverpod — prêt pour branchement API.
// UI             : infoOtProvider → InfoOtPage (table Article · Qté · Magasin).
// Spécifications : [fetchItems] utilise démo ; remplacer par
//                  SwappApiService.fetchInfoOts() quand endpoint prêt.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cap_mobile/swapp/models/info_ot_item.dart';

import '../services/transfert_api_service.dart';
import 'transfert_api_provider.dart';

/// État écran Info OT.
class InfoOtState {
  final List<InfoOtItem> items;
  final bool isLoading;
  final String? error;
  final String? searchQuery;

  const InfoOtState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
  });

  /// Lignes visibles après recherche (scan ou saisie).
  List<InfoOtItem> get visibleItems {
    final q = searchQuery?.trim();
    if (q == null || q.isEmpty) return items;
    return items
        .where(
          (i) =>
              i.codeArticle.contains(q) ||
              i.otId.contains(q) ||
              i.libelleMagasin.toLowerCase().contains(q.toLowerCase()),
        )
        .toList(growable: false);
  }

  InfoOtState copyWith({
    List<InfoOtItem>? items,
    bool? isLoading,
    String? error,
    String? searchQuery,
    bool clearError = false,
    bool clearSearch = false,
  }) {
    return InfoOtState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      searchQuery: clearSearch ? null : searchQuery ?? this.searchQuery,
    );
  }
}

/// Notifier — charge les OT (démo → API).
class InfoOtNotifier extends StateNotifier<InfoOtState> {
  InfoOtNotifier(this._service) : super(const InfoOtState());

  final TransfertApiService _service;

  /// Charge la liste OT — démo locale, puis API store.
  Future<void> fetchItems({int? codeMag}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // TODO(API) : remplacer par _service.fetchInfoOts(codeMag: codeMag)
      await Future<void>.delayed(const Duration(milliseconds: 350));
      final items = await _service.fetchOts(codeMag: codeMag);
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setSearchQuery(String? query) {
    state = state.copyWith(
      searchQuery: query,
      clearSearch: query == null || query.trim().isEmpty,
    );
  }
}

final infoOtProvider = StateNotifierProvider<InfoOtNotifier, InfoOtState>((
  ref,
) {
  return InfoOtNotifier(ref.watch(transfertApiServiceProvider));
});
