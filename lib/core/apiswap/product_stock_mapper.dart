// =============================================================================
// CapMobile — API Swapp — Mapper ModeleGlobal → ProductStockView
// -----------------------------------------------------------------------------
// Fonctionnalité : Transforme la réponse API modèle global en vue UI Swapp.
// Design         : Classe utilitaire statique ; parsing libProduit en 3 tokens.
// UI             : fromModeleGlobal produit les champs affichés dans hero + tableau :
//                  libProduit→ref/colorway/size ; forme→model ; prixVente→Pill ;
//                  resteALiver→ReassortChip ; listePrix→stockBySize rows.
// Spécifications : listePrix → stockBySize (dispo, transit, picking, vols…) ;
//                  totaux resa/preResa ; URL photo via SwappApiConstants.
// Auteur         : H.AMIZIANI
// =============================================================================

import '../../swapp/models/product_stock_view.dart';
import 'models/modele_global_model.dart';
import 'swapp_api_constants.dart';

/// Mapping JSON store-api → [ProductStockView] pour les écrans produit.
class ProductStockMapper {
  ProductStockMapper._();

  static ProductStockView fromModeleGlobal(ModeleGlobalModel model) {
    final (reference, colorway, size) = _parseLibProduit(model.libProduit);

    final stockBySize = <String, Map<String, int>>{};
    var totalResa = 0;
    var totalPreResa = 0;

    for (final item in model.listePrix) {
      if (item.taille.isEmpty) continue;
      stockBySize[item.taille] = {
        'dispo': item.stockMag,
        'transit': item.stockTransit,
        'picking': item.stockPicking,
        'vols': item.stockVol,
        'nv': item.stockNonVendable,
        'ew': item.stockEcartWeb,
        'resas': item.stockResa,
        'resaPlus': item.stockPreResa,
        'depot': item.stockDepot,
      };
      totalResa += item.stockResa;
      totalPreResa += item.stockPreResa;
    }

    final category = model.libFamille.isNotEmpty
        ? model.libFamille
        : (model.libTheme.isNotEmpty ? model.libTheme : model.libRayon);

    final segment = [
      if (model.libRayon.isNotEmpty) model.libRayon.toUpperCase(),
      if (model.libSaison.isNotEmpty) model.libSaison,
    ].join(' / ');

    return ProductStockView(
      reference: reference.isNotEmpty ? reference : model.codeModele,
      gencode: _resolveGencode(model, size),
      colorway: colorway.toUpperCase(),
      size: size,
      sizeRange: model.libTaille,
      category: category,
      model: model.forme.trim(),
      segment: segment,
      price: model.prixVente,
      reassortOk: model.resteALiver,
      photoUrl: SwappApiConstants.productPhotoUrl(model.codeModele),
      cartQty: totalResa,
      orderedQty: totalPreResa,
      stockBySize: stockBySize,
      libPlusProduit: model.libPlusProduit?.trim(),
    );
  }

  static String _resolveGencode(ModeleGlobalModel model, String size) {
    if (size.isNotEmpty) {
      for (final item in model.listePrix) {
        if (item.taille == size && item.gencode.isNotEmpty) {
          return item.gencode;
        }
      }
    }
    for (final item in model.listePrix) {
      if (item.gencode.isNotEmpty) return item.gencode;
    }
    return '';
  }

  /// Parse "REF COLORWAY SIZE" depuis libProduit API.
  static (String reference, String colorway, String size) _parseLibProduit(
    String libProduit,
  ) {
    final trimmed = libProduit.trim();
    if (trimmed.isEmpty) return ('', '', '');

    final match = RegExp(r'^(\S+)\s+(.+?)\s+(\S+)$').firstMatch(trimmed);
    if (match != null) {
      return (match.group(1)!, match.group(2)!, match.group(3)!);
    }

    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return (parts.first, '', '');
    if (parts.length == 2) return (parts[0], parts[1], '');
    return (
      parts.first,
      parts.sublist(1, parts.length - 1).join(' '),
      parts.last,
    );
  }
}
