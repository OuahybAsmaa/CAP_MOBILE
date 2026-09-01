// =============================================================================
// CapMobile — Module Swapp — Modèle Article saisi (transfert / retour)
// -----------------------------------------------------------------------------
// Fonctionnalité : Ligne article d'un ordre de transfert ou d'un retour dépôt —
//                  déclinaison, stock magasin, quantité saisie et statut.
// Design         : Objet immuable — mapping futur depuis JSON API store.
// UI             : Alimente ArticlesSaisiePage (tableau ARTICLE / STATUT / STK. /
//                  TRF.) ouverte au double tap sur une ligne de liste en attente.
// Spécifications : Données démo dans [ArticleSaisieDemoData].
// Auteur         : H.AMIZIANI
// =============================================================================

/// Statut de contrôle d'une ligne article.
enum ArticleSaisieStatut {
  /// Quantité saisie conforme.
  valide('Validé'),

  /// Écart à contrôler (stock, quantité).
  alerte('Alerte'),

  /// Ligne pas encore traitée.
  enAttente('En attente');

  const ArticleSaisieStatut(this.label);

  /// Libellé affiché dans la légende de progression.
  final String label;
}

/// Ligne article d'une saisie transfert / retour.
class ArticleSaisieItem {
  /// Code modèle / article (ex. « 30180098 »).
  final String codeArticle;

  /// Taille affichée (ex. « T-39 »).
  final String taille;

  /// Couleur affichée (ex. « Rouge »).
  final String couleur;

  /// Stock magasin de la déclinaison (colonne STK.).
  final int stock;

  /// Quantité saisie pour le transfert / retour (colonne TRF.).
  final int quantite;

  /// Statut de contrôle de la ligne.
  final ArticleSaisieStatut statut;

  const ArticleSaisieItem({
    required this.codeArticle,
    required this.taille,
    required this.couleur,
    required this.stock,
    required this.quantite,
    required this.statut,
  });

  /// Identifiant unique de la déclinaison.
  String get id => '$codeArticle-$taille-$couleur';

  /// Sous-titre affiché — « T-39 Rouge ».
  String get displayVariante => '$taille $couleur';

  /// Parsing JSON API — à brancher quand l'endpoint sera disponible.
  ///
  /// Exemple attendu :
  /// `{ "codeArticle": "30180098", "taille": "T-39", "couleur": "Rouge",
  ///    "stock": 0, "quantite": 2, "statut": "valide" }`
  factory ArticleSaisieItem.fromJson(Map<String, dynamic> json) {
    return ArticleSaisieItem(
      codeArticle: '${json['codeArticle'] ?? json['gencode'] ?? ''}'.trim(),
      taille: '${json['taille'] ?? ''}'.trim(),
      couleur: '${json['couleur'] ?? ''}'.trim(),
      stock: (json['stock'] ?? json['stk'] as num?)?.toInt() ?? 0,
      quantite: (json['quantite'] ?? json['qte'] as num?)?.toInt() ?? 0,
      statut: _parseStatut(json['statut']),
    );
  }

  static ArticleSaisieStatut _parseStatut(Object? raw) {
    final value = '${raw ?? ''}'.trim().toLowerCase();
    return switch (value) {
      'valide' || 'validé' || 'ok' => ArticleSaisieStatut.valide,
      'alerte' || 'ko' => ArticleSaisieStatut.alerte,
      _ => ArticleSaisieStatut.enAttente,
    };
  }
}
