// Donnees de test de la reserve produit.

import 'package:cap_mobile/swapp/models/reserve_sku_item.dart';

/// Données mock — compteurs et listes SKU réserve.
class ReserveMockData {
  ReserveMockData._();

  static const String sectionNonRange = 'non_range';
  static const String sectionPasDeLoge = 'pas_de_loge';

  static const String labelNonRange = 'NON RANGE';
  static const String labelPasDeLoge = 'PAS DE LOGE';

  /// Jeu de test — articles en attente de rangement.
  static const List<ReserveSkuItem> sampleItems = [
    ReserveSkuItem(
      sku: '36330033010240',
      label: 'BLEU · 24',
      sectionId: sectionNonRange,
    ),
    ReserveSkuItem(
      sku: '36330033010250',
      label: 'BLEU · 25',
      sectionId: sectionNonRange,
    ),
    ReserveSkuItem(
      sku: '36330033010260',
      label: 'BLEU · 26',
      sectionId: sectionNonRange,
    ),
    ReserveSkuItem(
      sku: '36330033010270',
      label: 'BLEU · 27',
      sectionId: sectionNonRange,
    ),
    ReserveSkuItem(
      sku: '36330033010280',
      label: 'BLEU · 28',
      sectionId: sectionNonRange,
    ),
  ];

  static List<ReserveSkuItem> itemsForSection(
    String sectionId, {
    required List<ReserveSkuItem> source,
  }) {
    return source
        .where((e) => e.sectionId == sectionId)
        .toList(growable: false);
  }

  static int countForSection(String sectionId, List<ReserveSkuItem> source) {
    return itemsForSection(sectionId, source: source).length;
  }
}
