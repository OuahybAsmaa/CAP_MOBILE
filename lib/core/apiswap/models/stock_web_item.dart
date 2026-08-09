// =============================================================================
// CapMobile — API Swapp — Modèle JSON stock web SFS
// -----------------------------------------------------------------------------
// Fonctionnalité : DTO une ligne GET /api/stock/{codeModele}/sfs.
// Design         : gencode, taille, stock (quantité dispo entrepôt).
// UI             : taille + stock → colonnes Taille/Dispo _StockTable onglet Web.
// Spécifications : fromJson + _asInt pour champs numériques.
// Auteur         : H.AMIZIANI
// =============================================================================

/// Item stock web — disponibilité SFS pour une taille.
class StockWebItem {
  final String gencode;
  final String taille;
  final int stock;

  const StockWebItem({
    required this.gencode,
    required this.taille,
    required this.stock,
  });

  factory StockWebItem.fromJson(Map<String, dynamic> json) {
    return StockWebItem(
      gencode: json['gencode']?.toString() ?? '',
      taille: json['taille']?.toString() ?? '',
      stock: _asInt(json['stock']),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
