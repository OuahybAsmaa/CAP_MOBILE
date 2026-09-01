// =============================================================================
// CapMobile — Module Swapp — Modèle Retour Dépôt (retour saison en attente)
// -----------------------------------------------------------------------------
// Fonctionnalité : En-tête d'un retour dépôt non clôturé — dépôt destinataire,
//                  nombre d'articles saisis, date de création.
// Design         : Objet immuable — mapping futur depuis JSON API store.
// UI             : Alimente RetourDepotPage (« VOS RETOURS SAISON EN ATTENTE »)
//                  et le popup de reprise ouvert depuis InfoTransfertMenuPage.
// Spécifications : Données démo dans [RetourDepotDemoData] ; ordre d'affichage
//                  chronologique via [compareOrdreRetour].
// Auteur         : H.AMIZIANI
// =============================================================================

/// Retour dépôt en attente — une carte de la liste.
class RetourDepotItem {
  /// Numéro de retour — identifiant legacy et clé de sélection.
  final String numRetour;

  /// Code du dépôt destinataire.
  final int codeDepot;

  /// Libellé du dépôt (ex. « VGM TREMERY »).
  final String libelleDepot;

  /// Nombre d'articles déjà saisis dans le retour.
  final int nbArticles;

  /// Date de création du retour.
  final DateTime dateCreation;

  const RetourDepotItem({
    required this.numRetour,
    required this.codeDepot,
    required this.libelleDepot,
    required this.nbArticles,
    required this.dateCreation,
  });

  /// Identifiant unique pour la sélection UI.
  String get id => numRetour;

  /// Titre affiché — « Dépôt VGM TREMERY ».
  String get displayTitle => 'Dépôt $libelleDepot';

  /// Ordre d'affichage : du plus ancien au plus récent, puis n° de retour.
  static int compareOrdreRetour(RetourDepotItem a, RetourDepotItem b) {
    final byDate = a.dateCreation.compareTo(b.dateCreation);
    return byDate != 0 ? byDate : a.numRetour.compareTo(b.numRetour);
  }

  /// Parsing JSON API — à brancher quand l'endpoint sera disponible.
  ///
  /// Exemple attendu :
  /// `{ "numRetour": "RD-20200928-01", "codeDepot": 999,
  ///    "libelleDepot": "VGM TREMERY", "nbArticles": 43,
  ///    "dateCreation": "2020-09-28" }`
  factory RetourDepotItem.fromJson(Map<String, dynamic> json) {
    return RetourDepotItem(
      numRetour: '${json['numRetour'] ?? json['numRet'] ?? ''}'.trim(),
      codeDepot: (json['codeDepot'] ?? json['codeDep'] as num?)?.toInt() ?? 0,
      libelleDepot: '${json['libelleDepot'] ?? json['depot'] ?? ''}'.trim(),
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
