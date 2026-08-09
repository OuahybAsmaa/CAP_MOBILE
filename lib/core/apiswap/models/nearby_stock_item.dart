// =============================================================================
// CapMobile — API Swapp — Modèle JSON stock alentours (nearby)
// -----------------------------------------------------------------------------
// Fonctionnalité : DTO réponse GET /api/stock/{gencode}/{codeMag}/nearby.
// Design         : NearbyStoreStock + NearbyStockLine (stockMag par taille).
// UI             : nearbyStockProvider → sélecteur magasin + _StockTable Alentours.
// Auteur         : H.AMIZIANI
// =============================================================================

/// Ligne stock pour une taille dans un magasin alentour.
class NearbyStockLine {
  final int codeMag;
  final String taille;
  final int stockMag;

  const NearbyStockLine({
    required this.codeMag,
    required this.taille,
    required this.stockMag,
  });

  factory NearbyStockLine.fromJson(Map<String, dynamic> json) {
    return NearbyStockLine(
      codeMag: _asInt(json['codeMag']),
      taille: json['taille']?.toString() ?? '',
      stockMag: _asInt(json['stockMag']),
    );
  }
}

/// Stock d'un magasin proche (ordre API = proximité).
class NearbyStoreStock {
  final int codeMag;
  final String nomMag;
  final List<NearbyStockLine> stocks;
  final int rank;

  const NearbyStoreStock({
    required this.codeMag,
    required this.nomMag,
    required this.stocks,
    required this.rank,
  });

  factory NearbyStoreStock.fromJson(Map<String, dynamic> json, {required int rank}) {
    final rawStocks = json['stocks'];
    final lines = rawStocks is List
        ? rawStocks
            .whereType<Map<String, dynamic>>()
            .map(NearbyStockLine.fromJson)
            .toList()
        : <NearbyStockLine>[];

    return NearbyStoreStock(
      codeMag: _asInt(json['codeMag']),
      nomMag: json['nomMag']?.toString() ?? '',
      stocks: lines,
      rank: rank,
    );
  }

  /// UI : true si au moins une taille a du stock magasin > 0 (picker alentours).
  bool get hasStock => stocks.any((line) => line.stockMag > 0);

  /// UI : somme stockMag toutes tailles — badge vert dans le dialogue magasin.
  int get totalStock =>
      stocks.fold<int>(0, (sum, line) => sum + line.stockMag);
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
