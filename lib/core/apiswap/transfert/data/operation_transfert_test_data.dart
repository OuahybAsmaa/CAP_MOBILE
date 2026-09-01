// Donnees de test de la couche API Swapp.

import 'package:cap_mobile/swapp/models/operation_transfert_item.dart';

/// Données démo — reproduction capture « Opérations de transfert » legacy.
abstract final class OperationTransfertDemoData {
  /// 7 OT en attente pour 234 articles au total.
  static List<OperationTransfertItem> items() => [
    OperationTransfertItem(
      numOt: 'OT-20200416-902',
      codeMagasin: 902,
      libelleMagasin: 'LE RELAIS',
      nbArticles: 5,
      dateCreation: _d(2020, 4, 16),
    ),
    OperationTransfertItem(
      numOt: 'OT-20200603-495-1',
      codeMagasin: 495,
      libelleMagasin: 'LE MANS LA CHAPELLE SAINT AUBIN',
      nbArticles: 66,
      dateCreation: _d(2020, 6, 3),
    ),
    OperationTransfertItem(
      numOt: 'OT-20200603-495-2',
      codeMagasin: 495,
      libelleMagasin: 'LE MANS LA CHAPELLE SAINT AUBIN',
      nbArticles: 64,
      dateCreation: _d(2020, 6, 3),
    ),
    OperationTransfertItem(
      numOt: 'OT-20200615-495-1',
      codeMagasin: 495,
      libelleMagasin: 'LE MANS LA CHAPELLE SAINT AUBIN',
      nbArticles: 47,
      dateCreation: _d(2020, 6, 15),
    ),
    OperationTransfertItem(
      numOt: 'OT-20200615-495-2',
      codeMagasin: 495,
      libelleMagasin: 'LE MANS LA CHAPELLE SAINT AUBIN',
      nbArticles: 6,
      dateCreation: _d(2020, 6, 15),
    ),
    OperationTransfertItem(
      numOt: 'OT-20200629-303',
      codeMagasin: 303,
      libelleMagasin: 'LENS NOYELLES GODAULT',
      nbArticles: 43,
      dateCreation: _d(2020, 6, 29),
    ),
    OperationTransfertItem(
      numOt: 'OT-20200702-127',
      codeMagasin: 127,
      libelleMagasin: 'AMIENS GLISY',
      nbArticles: 3,
      dateCreation: _d(2020, 7, 2),
    ),
  ];

  static DateTime _d(int y, int m, int d) => DateTime(y, m, d);
}
