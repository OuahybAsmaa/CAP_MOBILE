// Donnees de test de la couche API Swapp.

import 'package:cap_mobile/swapp/models/bl_collection_item.dart';

/// Données démo — reproduction capture « Scan Support » (11 BL, 11 supports).
abstract final class BlCollectionDemoData {
  static List<BlCollectionItem> items() => [
    BlCollectionItem(
      numBl: '0237000103',
      date: DateTime(2026, 3, 25),
      total: 1,
      restant: 1,
    ),
    BlCollectionItem(
      numBl: '0237000104',
      date: DateTime(2026, 3, 25),
      total: 1,
      restant: 1,
    ),
    BlCollectionItem(
      numBl: '0237000105',
      date: DateTime(2026, 3, 31),
      total: 1,
      restant: 1,
    ),
    BlCollectionItem(
      numBl: '0237000106',
      date: DateTime(2026, 4, 8),
      total: 1,
      restant: 1,
    ),
    BlCollectionItem(
      numBl: '0237000120',
      date: DateTime(2026, 6, 16),
      total: 1,
      restant: 1,
    ),
    BlCollectionItem(
      numBl: '0237000127',
      date: DateTime(2026, 7, 21),
      total: 1,
      restant: 1,
    ),
    BlCollectionItem(
      numBl: '0237000128',
      date: DateTime(2026, 7, 21),
      total: 1,
      restant: 1,
    ),
    BlCollectionItem(
      numBl: '0237000130',
      date: DateTime(2026, 8, 18),
      total: 1,
      restant: 1,
    ),
    BlCollectionItem(
      numBl: '0237000131',
      date: DateTime(2026, 8, 18),
      total: 1,
      restant: 1,
    ),
    BlCollectionItem(
      numBl: '0237000132',
      date: DateTime(2026, 8, 18),
      total: 1,
      restant: 1,
    ),
    BlCollectionItem(
      numBl: '0237000133',
      date: DateTime(2026, 8, 18),
      total: 1,
      restant: 1,
    ),
  ];
}
