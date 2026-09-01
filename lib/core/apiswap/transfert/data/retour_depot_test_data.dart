// Donnees de test de la couche API Swapp.

import 'package:cap_mobile/swapp/models/retour_depot_item.dart';

/// Données démo — reproduction capture « Retour Dépôt » legacy.
abstract final class RetourDepotDemoData {
  /// 10 retours en attente pour 366 articles au total.
  static List<RetourDepotItem> items() => [
    _tremery('RD-20200928-01', 43, _d(2020, 9, 28)),
    _tremery('RD-20200928-02', 83, _d(2020, 9, 28)),
    _tremery('RD-20200928-03', 55, _d(2020, 9, 28)),
    _tremery('RD-20200929-01', 83, _d(2020, 9, 29)),
    _tremery('RD-20200929-02', 1, _d(2020, 9, 29)),
    _tremery('RD-20200929-03', 84, _d(2020, 9, 29)),
    _tremery('RD-20200930-01', 4, _d(2020, 9, 30)),
    _tremery('RD-20201001-01', 6, _d(2020, 10, 1)),
    _tremery('RD-20201002-01', 5, _d(2020, 10, 2)),
    _tremery('RD-20201005-01', 2, _d(2020, 10, 5)),
  ];

  static RetourDepotItem _tremery(String num, int nbArticles, DateTime date) {
    return RetourDepotItem(
      numRetour: num,
      codeDepot: 999,
      libelleDepot: 'VGM TREMERY',
      nbArticles: nbArticles,
      dateCreation: date,
    );
  }

  static DateTime _d(int y, int m, int d) => DateTime(y, m, d);
}
