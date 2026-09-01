// Donnees de test de la couche API Swapp.

import 'package:cap_mobile/swapp/models/info_transfert_item.dart';

/// Jeu de données test — reproduction écrans Transfert legacy.
abstract final class InfoTransfertDemoData {
  static InfoTransfertFiche fichePour(int codeMag, {String? nomMag}) {
    return InfoTransfertFiche(
      codeMagDest: codeMag,
      nomMagDest: nomMag ?? 'CAP ${codeMag.toString().padLeft(3, '0')}',
      typesAutorises: const ['INTER', 'SFS', 'C&C'],
      reservations: const [
        InfoTransfertReservation(
          codeArticle: '52330008',
          quantite: 1,
          statut: 'Réservé',
        ),
        InfoTransfertReservation(
          codeArticle: '53522028',
          quantite: 2,
          statut: 'En attente',
        ),
      ],
      ots: const [
        InfoTransfertOtLine(
          otId: 'OT-2026-0142',
          codeArticle: '52330008',
          quantite: 3,
        ),
        InfoTransfertOtLine(
          otId: 'OT-2026-0158',
          codeArticle: '53522025',
          quantite: 2,
        ),
      ],
      lignes: const [
        InfoTransfertLine(
          codeArticle: '52330008',
          libelle: 'Basket running homme',
          quantite: 2,
          statut: 'À préparer',
        ),
        InfoTransfertLine(
          codeArticle: '53522024',
          libelle: 'Casque audio sport',
          quantite: 1,
          statut: 'Expédié',
        ),
      ],
      clickAndCollectAEmballer: 1,
    );
  }
}
