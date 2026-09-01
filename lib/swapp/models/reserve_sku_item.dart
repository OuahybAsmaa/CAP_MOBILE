// =============================================================================
// CapMobile — Module Swapp — Données mock « Réserve Produit »
// -----------------------------------------------------------------------------
// Fonctionnalité : Jeu de test en attendant l’intégration API réserve magasin.
// Design         : Sections NON RANGE / PAS DE LOGE + chips SKU.
// UI             : Alimente ReserveProduitPage (compteurs + Wrap chips).
// Spécifications : Remplacer par service API quand endpoint disponible.
// Auteur         : H.AMIZIANI
// =============================================================================

/// Ligne SKU affichée en chip dans une section réserve.
class ReserveSkuItem {
  final String sku;
  final String label;
  final String sectionId;

  const ReserveSkuItem({
    required this.sku,
    required this.label,
    required this.sectionId,
  });
}
