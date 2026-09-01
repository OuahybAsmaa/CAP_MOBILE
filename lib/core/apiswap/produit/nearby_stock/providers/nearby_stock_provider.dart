// =============================================================================
// CapMobile — API Swapp — Provider stock alentours (Riverpod)
// -----------------------------------------------------------------------------
// Fonctionnalité : Cache magasins proches + stock par magasin sélectionné.
// Design         : StateNotifier ; clé cache gencode/codeMag référence.
// UI             : stores → showNearbyStorePickerDialog ; stockBySize → _StockTable.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cap_mobile/core/apiswap/models/nearby_stock_item.dart';
import 'package:cap_mobile/core/apiswap/produit/nearby_stock/mappers/nearby_stock_mapper.dart';
import 'package:cap_mobile/core/apiswap/produit/providers/swapp_product_provider.dart';
import 'package:cap_mobile/core/apiswap/shared/config/swapp_api_constants.dart';
import 'package:cap_mobile/core/apiswap/shared/services/swapp_api_service.dart';

/// État du stock alentours pour l'onglet Alentours.
class NearbyStockState {
  final List<NearbyStoreStock> stores;
  final int? selectedCodeMag;
  final bool isLoading;
  final String? error;
  final String? loadedKey;

  const NearbyStockState({
    this.stores = const [],
    this.selectedCodeMag,
    this.isLoading = false,
    this.error,
    this.loadedKey,
  });

  Map<String, Map<String, int>> get selectedStockBySize {
    for (final store in stores) {
      if (store.codeMag == selectedCodeMag) {
        return NearbyStockMapper.toStockBySize(store.stocks);
      }
    }
    if (stores.isNotEmpty) {
      return NearbyStockMapper.toStockBySize(stores.first.stocks);
    }
    return const {};
  }

  NearbyStoreStock? get selectedStore {
    if (selectedCodeMag == null) return stores.isNotEmpty ? stores.first : null;
    for (final store in stores) {
      if (store.codeMag == selectedCodeMag) return store;
    }
    return stores.isNotEmpty ? stores.first : null;
  }

  NearbyStockState copyWith({
    List<NearbyStoreStock>? stores,
    int? selectedCodeMag,
    bool? isLoading,
    String? error,
    String? loadedKey,
    bool clearError = false,
    bool clearData = false,
    bool clearSelection = false,
  }) {
    return NearbyStockState(
      stores: clearData ? const [] : stores ?? this.stores,
      selectedCodeMag: clearSelection
          ? null
          : selectedCodeMag ?? this.selectedCodeMag,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      loadedKey: clearData ? null : loadedKey ?? this.loadedKey,
    );
  }
}

/// Notifier — fetch stock alentours et sélection magasin.
class NearbyStockNotifier extends StateNotifier<NearbyStockState> {
  NearbyStockNotifier(this._service) : super(const NearbyStockState());

  final SwappApiService _service;

  Future<void> fetchNearbyStock({
    required String codeArticle,
    required int codeMag,
    bool force = false,
  }) async {
    final article = codeArticle.trim();
    if (article.isEmpty) return;

    final mag = SwappApiConstants.resolveCodeMag(codeMag);
    final key = '$article/$mag';
    if (!force &&
        state.loadedKey == key &&
        state.stores.isNotEmpty &&
        !state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final stores = await _service.fetchNearbyStock(
        codeArticle: article,
        codeMag: mag,
      );
      final selected = state.selectedCodeMag;
      final stillValid =
          selected != null && stores.any((store) => store.codeMag == selected);

      state = state.copyWith(
        stores: stores,
        selectedCodeMag: stillValid
            ? selected
            : (stores.isNotEmpty ? stores.first.codeMag : null),
        isLoading: false,
        loadedKey: key,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void selectStore(int codeMag) {
    if (state.selectedCodeMag == codeMag) return;
    state = state.copyWith(selectedCodeMag: codeMag);
  }

  void clear() {
    state = const NearbyStockState();
  }
}

final nearbyStockProvider =
    StateNotifierProvider<NearbyStockNotifier, NearbyStockState>((ref) {
      final service = ref.watch(swappApiServiceProvider);
      return NearbyStockNotifier(service);
    });
