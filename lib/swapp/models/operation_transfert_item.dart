// =============================================================================
// CapMobile — Module Swapp — Modèle Opération de transfert (OT en attente)
// -----------------------------------------------------------------------------
// Fonctionnalité : En-tête d'un ordre de transfert non clôturé — magasin
//                  destination, nombre d'articles saisis, date de création.
// Design         : Objet immuable — mapping futur depuis JSON API store.
// UI             : Alimente OperationsTransfertPage (« VOS OTS EN ATTENTE ») et
//                  le popup de reprise ouvert depuis InfoTransfertMenuPage.
// Spécifications : Données démo dans [OperationTransfertDemoData] ; l'ordre de
//                  transfert d'affichage suit [compareOrdreTransfert].
// Auteur         : H.AMIZIANI
// =============================================================================

/// Ordre de transfert en attente — une carte de la liste.
class OperationTransfertItem {
  /// Numéro d'OT — identifiant legacy et clé de sélection.
  final String numOt;

  /// Code magasin destination (ex. 902).
  final int codeMagasin;

  /// Libellé magasin destination (ex. « LE RELAIS »).
  final String libelleMagasin;

  /// Nombre d'articles déjà saisis dans l'OT.
  final int nbArticles;

  /// Date de création de l'OT.
  final DateTime dateCreation;

  const OperationTransfertItem({
    required this.numOt,
    required this.codeMagasin,
    required this.libelleMagasin,
    required this.nbArticles,
    required this.dateCreation,
  });

  /// Identifiant unique pour la sélection UI.
  String get id => numOt;

  /// Titre affiché — « 902 LE RELAIS ».
  String get displayTitle => '$codeMagasin $libelleMagasin';

  /// Ordre de transfert : du plus ancien au plus récent, puis n° d'OT.
  static int compareOrdreTransfert(
    OperationTransfertItem a,
    OperationTransfertItem b,
  ) {
    final byDate = a.dateCreation.compareTo(b.dateCreation);
    return byDate != 0 ? byDate : a.numOt.compareTo(b.numOt);
  }

  /// Parsing JSON API — à brancher quand l'endpoint sera disponible.
  ///
  /// Exemple attendu :
  /// `{ "numOt": "OT-20200416-902", "codeMagasin": 902,
  ///    "libelleMagasin": "LE RELAIS", "nbArticles": 5,
  ///    "dateCreation": "2020-04-16" }`
  factory OperationTransfertItem.fromJson(Map<String, dynamic> json) {
    return OperationTransfertItem(
      numOt: '${json['numOt'] ?? json['otId'] ?? ''}'.trim(),
      codeMagasin:
          (json['codeMagasin'] ?? json['codeMag'] as num?)?.toInt() ?? 0,
      libelleMagasin: '${json['libelleMagasin'] ?? json['magasin'] ?? ''}'
          .trim(),
      nbArticles: (json['nbArticles'] ?? json['nbArt'] as num?)?.toInt() ?? 0,
      dateCreation: _parseDate(json['dateCreation'] ?? json['dateCrea']),
    );
  }

  static DateTime _parseDate(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      final iso = DateTime.tryParse(raw);
      if (iso != null) return iso;
      final parts = raw.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          return DateTime(y, m, d);
        }
      }
    }
    return DateTime.now();
  }
}
