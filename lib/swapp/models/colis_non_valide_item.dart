// =============================================================================
// CapMobile — Module Swapp — Modèle colis non validé
// -----------------------------------------------------------------------------
// Fonctionnalité : Colis réceptionné mais pas encore validé — expéditeur, code
//                  colis, quantité et flux d'origine (livraison ou transfert).
// Design         : Objet immuable ; mapping JSON prêt pour l'API store.
// UI             : Alimente ColisNonValidesPage (onglets Livraisons /
//                  Transferts + tableau Expéditeur · Colis · Qté).
// Spécifications : Données démo dans [ColisNonValideDemoData] ; API TODO.
// Auteur         : H.AMIZIANI
// =============================================================================

/// Origine du colis non validé.
enum ColisNonValideFlux {
  /// Colis d'une livraison dépôt / fournisseur.
  livraison('Livraisons'),

  /// Colis reçu d'un autre magasin.
  transfert('Transferts');

  const ColisNonValideFlux(this.label);

  final String label;
}

/// Un colis en attente de validation.
class ColisNonValideItem {
  /// Expéditeur du colis (dépôt ou magasin).
  final String expediteur;

  /// Code colis (ex. « ANM0237000582 »).
  final String numColis;

  /// Quantité annoncée — décimale comme dans l'ERP (« 1,0 »).
  final double quantite;

  final ColisNonValideFlux flux;

  const ColisNonValideItem({
    required this.expediteur,
    required this.numColis,
    required this.quantite,
    required this.flux,
  });

  String get id => numColis;

  /// Parsing JSON API — à brancher quand l'endpoint sera disponible.
  factory ColisNonValideItem.fromJson(Map<String, dynamic> json) {
    final flux = '${json['flux'] ?? ''}'.trim().toLowerCase();
    return ColisNonValideItem(
      expediteur: '${json['expediteur'] ?? ''}'.trim(),
      numColis: '${json['numColis'] ?? json['colis'] ?? ''}'.trim(),
      quantite: _parseQuantite(json['quantite'] ?? json['qte']),
      flux: flux == 'transfert'
          ? ColisNonValideFlux.transfert
          : ColisNonValideFlux.livraison,
    );
  }

  static double _parseQuantite(Object? raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse('${raw ?? ''}'.replaceAll(',', '.')) ?? 0;
  }
}
