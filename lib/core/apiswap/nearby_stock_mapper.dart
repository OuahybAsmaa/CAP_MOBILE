// =============================================================================
// CapMobile — API Swapp — Mapper stock alentours → stockBySize
// -----------------------------------------------------------------------------
// Fonctionnalité : Convertit stocks nearby en map taille → métriques (comme Stock Mag).
// Design         : stockMag → dispo ; autres rubriques à 0 (non fournies par l'API).
// UI        // =============================================================================
// CapMobile — API Swapp — Mapper stock alentours → stockBySize
// -----------------------------------------------------------------------------
// Fonctionnalité : Convertit stocks nearby en map taille → métriques (comme Stock Mag).
// Design         : stockMag → dispo ; autres rubriques à 0 (non fournies par l'API).
// UI             : toStockBySize → _StockTable onglet Alentours.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'models/nearby_stock_item.dart';

/// Transformation stock magasin alentour vers structure tableau stock Swapp.
class NearbyStockMapper {
  NearbyStockMapper._();

  static Map<String, Map<String, int>> toStockBySize(List<NearbyStockLine> lines) {
    final stockBySize = <String, Map<String, int>>{};
    for (final item in lines) {
      if (item.taille.isEmpty) continue;
      stockBySize[item.taille] = {
        'dispo': item.stockMag,
        'transit': 0,
        'picking': 0,
        'vols': 0,
        'nv': 0,
        'ew': 0,
        'resas': 0,
        'resaPlus': 0,
        'depot': 0,
      };
    }
    return stockBySize;
  }
}
     : toStockBySize → _StockTable onglet Alentours.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'models/nearby_stock_item.dart';

/// Transformation stock magasin alentour vers structure tableau stock Swapp.
class NearbyStockMapper {
  NearbyStockMapper._();

  static Map<String, Map<String, int>> toStockBySize(List<NearbyStockLine> lines) {
    final stockBySize = <String, Map<String, int>>{};
    for (final item in lines) {
      if (item.taille.isEmpty) continue;
      stockBySize[item.taille] = {
        'dispo': item.stockMag,
        'transit': 0,
        'picking': 0,
        'vols': 0,
        'nv': 0,
        'ew': 0,
        'resas': 0,
        'resaPlus': 0,
        'depot': 0,
      };
    }
    return stockBySize;
  }
}
// =============================================================================
// CapMobile — API Swapp — Mapper stock alentours → stockBySize
// -----------------------------------------------------------------------------
// Fonctionnalité : Convertit stocks nearby en map taille → métriques (comme Stock Mag).
// Design         : stockMag → dispo ; autres rubriques à 0 (non fournies par l'API).
// UI             : toStockBySize → _StockTable onglet Alentours.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'models/nearby_stock_item.dart';

/// Transformation stock magasin alentour vers structure tableau stock Swapp.
class NearbyStockMapper {
  NearbyStockMapper._();

  static Map<String, Map<String, int>> toStockBySize(List<NearbyStockLine> lines) {
    final stockBySize = <String, Map<String, int>>{};
    for (final item in lines) {
      if (item.taille.isEmpty) continue;
      stockBySize[item.taille] = {
        'dispo': item.stockMag,
        'transit': 0,
        'picking': 0,
        'vols': 0,
        'nv': 0,
        'ew': 0,
        'resas': 0,
        'resaPlus': 0,
        'depot': 0,
      };
    }
    return stockBySize;
  }
}
