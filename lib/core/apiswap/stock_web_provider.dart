// =============================================================================
// CapMobile — API Swapp — Provider stock web (Riverpod)
// -----------------------------------------------------------------------------
// Fonctionnalité : Cache stock web SFS par code modèle ; map taille → dispo.
// Design         : StateNotifier ; évite re-fetch si même code déjà chargé.
// UI             : stockBySize → _StockTable onglet 1 (Stock Web, 2 colonnes) ;
//                  isLoading/error → loader ou bannière selon _navIndex.
// Spécifications : [fetchStockWeb] avec option force ; StockWebMapper.toStockBySize ;
//                  provider stockWebProvider.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'stock_web_mapper.dart';
import 'swapp_api_service.dart';
import 'swapp_product_provider.dart';

/// État du stock web (Ship From Store) pour l'onglet Stock Web.
class StockWebState {
  final Map<String, Map<String, int>> stockBySize;
  final bool isLoading;
  final String? error;
  final String? loadedCode;

  const StockWebState({
    this.stockBySize = const {},
    this.isLoading = false,
    this.error,
    this.loadedCode,
  });

  StockWebState copyWith({
    Map<String, Map<String, int>>? stockBySize,
    bool? isLoading,
    String? error,
    String? loadedCode,
    bool clearError = false,
    bool clearData = false,
  }) {
    return StockWebState(
      stockBySize: clearData ? const {} : stockBySize ?? this.stockBySize,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      loadedCode: clearData ? null : loadedCode ?? this.loadedCode,
    );
  }
}

/// Notifier — fetch stock web et conversion en structure stockBySize.
class StockWebNotifier extends StateNotifier<StockWebState> {
  StockWebNotifier(this._service) : super(const StockWebState());

  final SwappApiService _service;

  Future<void> fetchStockWeb(String codeModele, {bool force = false}) async {
    final code = codeModele.trim();
    if (code.isEmpty) return;

    if (!force &&
        state.loadedCode == code &&
        state.stockBySize.isNotEmpty &&
        !state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final items = await _service.fetchStockWeb(codeModele: code);
      state = state.copyWith(
        stockBySize: StockWebMapper.toStockBySize(items),
        isLoading: false,
        loadedCode: code,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clear() {
    state = const StockWebState();
  }
}

final stockWebProvider =
    StateNotifierProvider<StockWebNotifier, StockWebState>((ref) {
  final service = ref.watch(swappApiServiceProvider);
  return StockWebNotifier(service);
});
