// Donnees de test de la couche API Swapp.

import 'package:cap_mobile/swapp/models/colis_non_valide_item.dart';

/// Données démo — 26 colis de livraison (capture) et 1 colis de transfert.
abstract final class ColisNonValideDemoData {
  static const _depot = 'Dépôt VGM TREMERY';

  /// Quantités des colis ANM0237000582 → 596 relevées sur la capture ; les
  /// colis suivants complètent le compteur « Livraisons (26) ».
  static const _quantites = <double>[
    1,
    1,
    1,
    10,
    3,
    1,
    3,
    1,
    1,
    30,
    2,
    1,
    1,
    1,
    1,
    1,
    1,
    2,
    1,
    1,
    5,
    1,
    1,
    1,
    4,
    1,
  ];

  static List<ColisNonValideItem> items() => [
    for (var i = 0; i < _quantites.length; i++)
      ColisNonValideItem(
        expediteur: _depot,
        numColis: 'ANM0237000${582 + i}',
        quantite: _quantites[i],
        flux: ColisNonValideFlux.livraison,
      ),
    const ColisNonValideItem(
      expediteur: 'Magasin 495 LE MANS LA CHAPELLE',
      numColis: 'TRF0237000021',
      quantite: 2,
      flux: ColisNonValideFlux.transfert,
    ),
  ];
}
