// Donnees de test de la couche API Swapp.

import 'package:cap_mobile/swapp/models/colis_reassort_item.dart';

/// File de colis démo — chaque appui sur « Scanner » bipe le colis suivant.
abstract final class ColisReassortDemoData {
  static List<ColisReassortItem> file() => const [
    ColisReassortItem(
      numColis: 'C0237000901',
      numBl: '0237000140',
      quantite: 12,
      etat: ColisReassortEtat.accepte,
    ),
    ColisReassortItem(
      numColis: 'C0237000902',
      numBl: '0237000140',
      quantite: 8,
      etat: ColisReassortEtat.accepte,
    ),
    ColisReassortItem(
      numColis: 'C0237000903',
      numBl: '0237000141',
      quantite: 15,
      etat: ColisReassortEtat.accepte,
    ),
    ColisReassortItem(
      numColis: 'C0237000904',
      numBl: '0237000199',
      quantite: 6,
      etat: ColisReassortEtat.refuse,
      motif: 'BL non attendu sur ce magasin',
    ),
    ColisReassortItem(
      numColis: 'C0237000905',
      numBl: '0237000141',
      quantite: 10,
      etat: ColisReassortEtat.accepte,
    ),
    ColisReassortItem(
      numColis: 'C0237000906',
      numBl: '0237000141',
      quantite: 4,
      etat: ColisReassortEtat.refuse,
      motif: 'Colis déjà réceptionné',
    ),
  ];
}
