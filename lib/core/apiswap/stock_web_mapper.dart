// =============================================================================
// CapMobile — API Swapp — Mapper stock web → stockBySize
// -----------------------------------------------------------------------------
// Fonctionnalité : Convertit liste StockWebItem en map taille → {dispo}.
// Design         : Utilitaire statique ; totalDispo pour ligne récapitulative.
// UI             : toStockBySize → cellules « Dispo » _StockTable onglet Stock Web.
// Spécifications : Clé 'dispo' alignée sur StockColumnDef mode web.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'models/stock_web_item.dart';

/// Transformation stock web SFS vers structure tableau stock Swapp.
class StockWebMapper {
  StockWebMapper._();

  static Map<String, Map<String, int>> toStockBySize(List<StockWebItem> items) {
    final stockBySize = <String, Map<String, int>>{};
    for (final item in items) {
      if (item.taille.isEmpty) continue;
      stockBySize[item.taille] = {'dispo': item.stock};
    }
    return stockBySize;
  }

  static int totalDispo(Map<String, Map<String, int>> stockBySize) {
    var total = 0;
    for (final line in stockBySize.values) {
      total += line['dispo'] ?? 0;
    }
    return total;
  }
}
