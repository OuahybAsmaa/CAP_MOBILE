// =============================================================================
// CapMobile — Module Swapp — Modèle BL de collection (scan support)
// -----------------------------------------------------------------------------
// Fonctionnalité : Bon de livraison collection — supports attendus et restants
//                  à scanner pour la réception.
// Design         : Objet immuable ; mapping JSON prêt pour l'API store.
// UI             : Alimente CollectionReceptionPage (tableau BL / Date / Total /
//                  Restant + pied « Quantité totale »).
// Spécifications : Données démo dans [BlCollectionDemoData] ; API TODO.
// Auteur         : H.AMIZIANI
// =============================================================================

/// Un bon de livraison collection à réceptionner.
class BlCollectionItem {
  /// Numéro du bon de livraison (ex. « 0237000103 »).
  final String numBl;

  /// Date du bon de livraison.
  final DateTime date;

  /// Nombre de supports annoncés sur le BL.
  final int total;

  /// Supports encore à scanner.
  final int restant;

  const BlCollectionItem({
    required this.numBl,
    required this.date,
    required this.total,
    required this.restant,
  });

  String get id => numBl;

  /// Tous les supports ont été scannés.
  bool get termine => restant <= 0;

  /// Supports déjà scannés.
  int get scannes => (total - restant).clamp(0, total);

  /// Tri d'affichage — du BL le plus ancien au plus récent.
  static int compareChronologique(BlCollectionItem a, BlCollectionItem b) {
    final byDate = a.date.compareTo(b.date);
    return byDate != 0 ? byDate : a.numBl.compareTo(b.numBl);
  }

  /// Parsing JSON API — à brancher quand l'endpoint sera disponible.
  factory BlCollectionItem.fromJson(Map<String, dynamic> json) {
    return BlCollectionItem(
      numBl: '${json['numBl'] ?? json['bl'] ?? ''}'.trim(),
      date: _parseDate(json['date']),
      total: (json['total'] as num?)?.toInt() ?? 0,
      restant: (json['restant'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime _parseDate(Object? raw) {
    if (raw is DateTime) return raw;
    return DateTime.tryParse('${raw ?? ''}') ?? DateTime.now();
  }
}
