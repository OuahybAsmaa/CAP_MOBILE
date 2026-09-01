// =============================================================================
// CapMobile — Module Swapp — Période d'analyse My Goodays
// -----------------------------------------------------------------------------
// Fonctionnalité : Fenêtre temporelle sélectionnée dans les pastilles de période.
// Spécifications : [apiValue] est la valeur envoyée au back-office ; garder ces
//                  clés synchronisées avec le contrat de l'API Goodays.
// Auteur         : H.AMIZIANI
// =============================================================================

/// Période d'agrégation des statistiques Goodays.
enum GoodaysPeriode {
  semaine('Semaine', 'WEEK'),
  mois('Mois', 'MONTH'),
  trimestre('Trimestre', 'QUARTER'),
  semestre('Semestre', 'HALF_YEAR'),
  annee('Année', 'YEAR');

  /// Libellé affiché dans les pastilles de période.
  final String label;

  /// Clé attendue par l'API (paramètre `period`).
  final String apiValue;

  const GoodaysPeriode(this.label, this.apiValue);
}
