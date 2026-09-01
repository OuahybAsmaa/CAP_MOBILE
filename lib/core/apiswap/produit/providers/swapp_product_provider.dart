// =============================================================================
// CapMobile — API Swapp — Provider produit (Riverpod)
// -----------------------------------------------------------------------------
// Fonctionnalité : État global produit Swapp — chargement, erreur, ProductStockView.
// Design         : StateNotifier + copyWith ; consommé par DetailProduitPage(s).
// UI             : swappProductProvider.product → _ProductHeroCard + tableau ;
//                  isLoading → CircularProgressIndicator ; error → bannière rouge.
// Spécifications : [fetchModele] appelle SwappApiService puis ProductStockMapper ;
//                  providers swappApiServiceProvider + swappProductProvider.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cap_mobile/core/apiswap/produit/mappers/product_stock_mapper.dart';
import 'package:cap_mobile/core/apiswap/shared/config/swapp_api_constants.dart';
import 'package:cap_mobile/core/apiswap/shared/services/swapp_api_service.dart';
import 'package:cap_mobile/swapp/models/product_stock_view.dart';

/// État du produit courant dans le module Swapp.
class SwappProductState {
  final ProductStockView? product;
  final bool isLoading;
  final String? error;
  final String? lastScannedGencode;

  const SwappProductState({
    this.product,
    this.isLoading = false,
    this.error,
    this.lastScannedGencode,
  });

  SwappProductState copyWith({
    ProductStockView? product,
    bool? isLoading,
    String? error,
    String? lastScannedGencode,
    bool clearProduct = false,
    bool clearError = false,
    bool clearLastScanned = false,
  }) {
    return SwappProductState(
      product: clearProduct ? null : product ?? this.product,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      lastScannedGencode: clearLastScanned
          ? null
          : lastScannedGencode ?? this.lastScannedGencode,
    );
  }
}

/// Notifier — fetch modèle global et map vers ProductStockView.
class SwappProductNotifier extends StateNotifier<SwappProductState> {
  SwappProductNotifier(this._service) : super(const SwappProductState());

  final SwappApiService _service;

  Future<void> fetchModele({
    required String codeModele,
    int codeMag = SwappApiConstants.defaultCodeMag,
    String? scannedGencode,
  }) async {
    final code = codeModele.trim();
    if (code.isEmpty) return;

    final scan = scannedGencode?.trim();
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      lastScannedGencode: (scan != null && scan.isNotEmpty)
          ? scan
          : state.lastScannedGencode,
    );

    try {
      final model = await _service.fetchModeleGlobal(
        codeModele: code,
        codeMag: codeMag,
      );
      var product = ProductStockMapper.fromModeleGlobal(model);
      final gencode = scan ?? state.lastScannedGencode;
      if (gencode != null && gencode.isNotEmpty && product.gencode != gencode) {
        product = product.copyWith(gencode: gencode);
      }
      state = state.copyWith(product: product, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clear() {
    state = const SwappProductState();
  }
}

final swappApiServiceProvider = Provider<SwappApiService>((ref) {
  return SwappApiService();
});

final swappProductProvider =
    StateNotifierProvider<SwappProductNotifier, SwappProductState>((ref) {
      final service = ref.watch(swappApiServiceProvider);
      return SwappProductNotifier(service);
    });
