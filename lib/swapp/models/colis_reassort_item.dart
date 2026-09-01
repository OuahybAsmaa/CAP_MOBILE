// =============================================================================
// CapMobile — Module Swapp — Modèle colis de réassort bipé
// -----------------------------------------------------------------------------
// Fonctionnalité : Colis scanné pendant une réception réassort — BL rattaché,
//                  quantité annoncée et état du contrôle (accepté / refusé).
// Design         : Objet immuable ; mapping JSON prêt pour l'API store.
// UI             : Alimente ReceptionReassortPage (tableau BL / Qte / État).
// Spécifications : File de colis démo dans [ColisReassortDemoData] pour simuler
//                  les bips ; API TODO.
// Auteur         : H.AMIZIANI
// =============================================================================

/// Résultat du contrôle d'un colis bipé.
enum ColisReassortEtat {
  /// Colis attendu et rattaché à un BL.
  accepte('Accepté'),

  /// Colis rejeté (BL inconnu, déjà reçu, magasin différent…).
  refuse('Refusé');

  const ColisReassortEtat(this.label);

  final String label;
}

/// Un colis bipé lors de la réception du réassort.
class ColisReassortItem {
  /// Code colis scanné.
  final String numColis;

  /// Bon de livraison rattaché.
  final String numBl;

  /// Quantité annoncée dans le colis.
  final int quantite;

  final ColisReassortEtat etat;

  /// Motif du refus — `null` quand le colis est accepté.
  final String? motif;

  const ColisReassortItem({
    required this.numColis,
    required this.numBl,
    required this.quantite,
    required this.etat,
    this.motif,
  });

  String get id => numColis;

  bool get accepte => etat == ColisReassortEtat.accepte;

  /// Parsing JSON API — à brancher quand l'endpoint sera disponible.
  factory ColisReassortItem.fromJson(Map<String, dynamic> json) {
    final etat = '${json['etat'] ?? ''}'.trim().toLowerCase();
    return ColisReassortItem(
      numColis: '${json['numColis'] ?? json['colis'] ?? ''}'.trim(),
      numBl: '${json['numBl'] ?? json['bl'] ?? ''}'.trim(),
      quantite: (json['quantite'] ?? json['qte'] as num?)?.toInt() ?? 0,
      etat: etat == 'refuse' || etat == 'refusé'
          ? ColisReassortEtat.refuse
          : ColisReassortEtat.accepte,
      motif: (json['motif'] as String?)?.trim(),
    );
  }
}
