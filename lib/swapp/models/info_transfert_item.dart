// =============================================================================
// CapMobile — Module Swapp — Modèle Info Transfert
// -----------------------------------------------------------------------------
// Fonctionnalité : Données transfert inter-magasin (types, résa, OT, lignes).
// Design         : Objets immuables — mapping futur JSON API store.
// UI             : InfoTransfertDetailPage (cartes Types / Résa / OT / Transfert).
// Spécifications : Données démo [InfoTransfertDemoData] en attendant l'API.
// Auteur         : H.AMIZIANI
// =============================================================================

/// Fiche transfert vers un magasin destination.
class InfoTransfertFiche {
  final int codeMagDest;
  final String nomMagDest;
  final List<String> typesAutorises;
  final List<InfoTransfertReservation> reservations;
  final List<InfoTransfertOtLine> ots;
  final List<InfoTransfertLine> lignes;
  final int clickAndCollectAEmballer;

  const InfoTransfertFiche({
    required this.codeMagDest,
    required this.nomMagDest,
    this.typesAutorises = const [],
    this.reservations = const [],
    this.ots = const [],
    this.lignes = const [],
    this.clickAndCollectAEmballer = 0,
  });

  factory InfoTransfertFiche.fromJson(Map<String, dynamic> json) {
    return InfoTransfertFiche(
      codeMagDest: (json['codeMagDest'] as num?)?.toInt() ?? 0,
      nomMagDest: '${json['nomMagDest'] ?? ''}'.trim(),
      typesAutorises: (json['typesAutorises'] as List? ?? const [])
          .map((e) => '$e')
          .toList(),
      reservations: (json['reservations'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InfoTransfertReservation.fromJson)
          .toList(),
      ots: (json['ots'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InfoTransfertOtLine.fromJson)
          .toList(),
      lignes: (json['lignes'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(InfoTransfertLine.fromJson)
          .toList(),
      clickAndCollectAEmballer:
          (json['clickAndCollectAEmballer'] as num?)?.toInt() ?? 0,
    );
  }
}

class InfoTransfertReservation {
  final String codeArticle;
  final int quantite;
  final String statut;

  const InfoTransfertReservation({
    required this.codeArticle,
    required this.quantite,
    required this.statut,
  });

  factory InfoTransfertReservation.fromJson(Map<String, dynamic> json) {
    return InfoTransfertReservation(
      codeArticle: '${json['codeArticle'] ?? ''}'.trim(),
      quantite: (json['quantite'] as num?)?.toInt() ?? 0,
      statut: '${json['statut'] ?? ''}'.trim(),
    );
  }
}

class InfoTransfertOtLine {
  final String otId;
  final String codeArticle;
  final int quantite;

  const InfoTransfertOtLine({
    required this.otId,
    required this.codeArticle,
    required this.quantite,
  });

  factory InfoTransfertOtLine.fromJson(Map<String, dynamic> json) {
    return InfoTransfertOtLine(
      otId: '${json['otId'] ?? ''}'.trim(),
      codeArticle: '${json['codeArticle'] ?? ''}'.trim(),
      quantite: (json['quantite'] as num?)?.toInt() ?? 0,
    );
  }
}

class InfoTransfertLine {
  final String codeArticle;
  final String libelle;
  final int quantite;
  final String statut;

  const InfoTransfertLine({
    required this.codeArticle,
    required this.libelle,
    required this.quantite,
    required this.statut,
  });

  factory InfoTransfertLine.fromJson(Map<String, dynamic> json) {
    return InfoTransfertLine(
      codeArticle: '${json['codeArticle'] ?? ''}'.trim(),
      libelle: '${json['libelle'] ?? ''}'.trim(),
      quantite: (json['quantite'] as num?)?.toInt() ?? 0,
      statut: '${json['statut'] ?? ''}'.trim(),
    );
  }
}
