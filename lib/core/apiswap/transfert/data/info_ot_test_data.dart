// Donnees de test de la couche API Swapp.

import 'package:cap_mobile/swapp/models/info_ot_item.dart';

/// Jeu de données test — reproduction écran « Info OT » legacy.
abstract final class InfoOtDemoData {
  static List<InfoOtItem> items() => const [
    InfoOtItem(
      otId: 'OT-2026-0142',
      codeArticle: '52330008',
      libelle: 'Basket running homme',
      quantite: 3,
      codeMagasin: 42,
      libelleMagasin: 'CAP 042 Paris',
    ),
    InfoOtItem(
      otId: 'OT-2026-0142',
      codeArticle: '53522024',
      libelle: 'Casque audio sport',
      quantite: 1,
      codeMagasin: 42,
      libelleMagasin: 'CAP 042 Paris',
    ),
    InfoOtItem(
      otId: 'OT-2026-0158',
      codeArticle: '53522028',
      libelle: 'Chaussure trail',
      quantite: 5,
      codeMagasin: 17,
      libelleMagasin: 'CAP 017 Lyon',
    ),
    InfoOtItem(
      otId: 'OT-2026-0158',
      codeArticle: '53522025',
      libelle: 'Sac à dos 25L',
      quantite: 2,
      codeMagasin: 17,
      libelleMagasin: 'CAP 017 Lyon',
    ),
    InfoOtItem(
      otId: 'OT-2026-0163',
      codeArticle: '53522026',
      libelle: 'Gants ski',
      quantite: 4,
      codeMagasin: 88,
      libelleMagasin: 'CAP 088 Lille',
    ),
    InfoOtItem(
      otId: 'OT-2026-0163',
      codeArticle: '53522027',
      libelle: 'Masque ski',
      quantite: 2,
      codeMagasin: 88,
      libelleMagasin: 'CAP 088 Lille',
    ),
    InfoOtItem(
      otId: 'OT-2026-0171',
      codeArticle: '52330008',
      libelle: 'Basket running homme',
      quantite: 1,
      codeMagasin: 3,
      libelleMagasin: 'CAP 003 Bordeaux',
    ),
  ];
}
