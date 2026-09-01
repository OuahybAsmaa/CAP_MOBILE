// =============================================================================
// CapMobile — Module Swapp — Modèle support d'un BL collection
// -----------------------------------------------------------------------------
// Fonctionnalité : Support (rolls / palette) d'un bon de livraison — colis
//                  annoncés et colis restant à réceptionner.
// Design         : Objet immuable + copyWith (décompte au fil des scans).
// UI             : Alimente SupportsBlPage (tableau Support / Total / Restant).
// Spécifications : Données démo dérivées du BL ; API TODO.
// Auteur         : H.AMIZIANI
// =============================================================================


/// Un support attendu sur un bon de livraison collection.
class SupportCollectionItem {
  /// Numéro du support (ex. « M023700000042 »).
  final String numSupport;

  /// Colis annoncés sur le support.
  final int total;

  /// Colis restant à réceptionner.
  final int restant;

  const SupportCollectionItem({
    required this.numSupport,
    required this.total,
    required this.restant,
  });

  String get id => numSupport;

  /// Tous les colis du support ont été réceptionnés.
  bool get termine => restant <= 0;

  /// Colis déjà réceptionnés.
  int get receptionnes => (total - restant).clamp(0, total);

  SupportCollectionItem copyWith({int? restant}) => SupportCollectionItem(
    numSupport: numSupport,
    total: total,
    restant: restant ?? this.restant,
  );

  /// Parsing JSON API — à brancher quand l'endpoint sera disponible.
  factory SupportCollectionItem.fromJson(Map<String, dynamic> json) {
    return SupportCollectionItem(
      numSupport: '${json['numSupport'] ?? json['support'] ?? ''}'.trim(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      restant: (json['restant'] as num?)?.toInt() ?? 0,
    );
  }
}
