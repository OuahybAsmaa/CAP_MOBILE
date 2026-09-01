// Donnees de test de la couche API Swapp.

import 'package:cap_mobile/swapp/models/info_tarif_item.dart';

/// Données démo — reproduction capture « Info Tarif » legacy.
abstract final class InfoTarifDemoData {
  static List<InfoTarifItem> operations() => [
    InfoTarifItem(
      code: '3133',
      label: 'OP DEFAUTS',
      dateDebut: _d(2023, 3, 7),
      dateFin: _d(2026, 9, 7),
    ),
    InfoTarifItem(
      code: '3605',
      label: 'RENTREE DES CLASSES 2026',
      dateDebut: _d(2026, 8, 3),
      dateFin: _d(2026, 9, 6),
    ),
    InfoTarifItem(
      code: '3717',
      label: 'PROMOS ESTIVALES',
      dateDebut: _d(2026, 7, 29),
      dateFin: _d(2026, 8, 16),
    ),
    InfoTarifItem(
      code: '3725',
      label: 'OP SPORT RDC 2026',
      dateDebut: _d(2026, 8, 3),
      dateFin: _d(2026, 9, 6),
    ),
    InfoTarifItem(
      code: '3727',
      label: 'OP ALIGNEMENT ADIDAS',
      dateDebut: _d(2026, 8, 12),
      dateFin: _d(2026, 12, 31),
    ),
    InfoTarifItem(
      code: '8026',
      label: 'FDS 26 10/08/2026',
      dateDebut: _d(2026, 8, 10),
      dateFin: _d(2026, 9, 9),
    ),
  ];

  static DateTime _d(int y, int m, int d) => DateTime(y, m, d);
}
