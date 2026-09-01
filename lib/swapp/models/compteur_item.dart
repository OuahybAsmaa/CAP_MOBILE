// =============================================================================
// CapMobile — Module Swapp — Modèle Compteur
// -----------------------------------------------------------------------------
// Fonctionnalité : Destination d'une saisie (dépôt / compteur legacy), commune
//                  aux ordres de transfert et aux retours dépôt.
// Design         : Objet immuable — mapping futur depuis JSON API store.
// UI             : Alimente CompteurSelectionPage (« COMPTEURS DISPONIBLES »).
// Spécifications : Données démo dans [CompteurDemoData] ; [matches] filtre la
//                  recherche sur le libellé et le numéro.
// Auteur         : H.AMIZIANI
// =============================================================================

/// Compteur — une ligne de la liste des destinations disponibles.
class CompteurItem {
  /// Numéro de compteur affiché (ex. 999).
  final int numero;

  /// Libellé du dépôt (ex. « VGM TREMERY »).
  final String libelleDepot;

  const CompteurItem({required this.numero, required this.libelleDepot});

  /// Identifiant unique pour la sélection UI.
  String get id => '$numero';

  /// Titre affiché — « Dépôt VGM TREMERY ».
  String get displayTitle => 'Dépôt $libelleDepot';

  /// Sous-titre affiché — « N° 999 ».
  String get displaySubtitle => 'N° $numero';

  /// Vrai si le compteur correspond à la recherche [query].
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return libelleDepot.toLowerCase().contains(q) || '$numero'.contains(q);
  }

  /// Parsing JSON API — à brancher quand l'endpoint sera disponible.
  ///
  /// Exemple attendu :
  /// `{ "numero": 999, "libelleDepot": "VGM TREMERY" }`
  factory CompteurItem.fromJson(Map<String, dynamic> json) {
    return CompteurItem(
      numero: (json['numero'] ?? json['codeDepot'] as num?)?.toInt() ?? 0,
      libelleDepot: '${json['libelleDepot'] ?? json['depot'] ?? ''}'.trim(),
    );
  }
}
