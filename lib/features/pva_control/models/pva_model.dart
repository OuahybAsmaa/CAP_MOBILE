// ── PvaLigne ─────────────────────────────────────────────────

class PvaLigne {
  final int    qte;
  final String ean;
  final String gtin;
  final String libTaille;
  final String codeMod;

  const PvaLigne({
    required this.qte,
    required this.ean,
    required this.gtin,
    required this.libTaille,
    required this.codeMod,
  });

  factory PvaLigne.fromJson(Map<String, dynamic> json) => PvaLigne(
    qte:       (json['qte'] as num?)?.toInt() ?? 0,
    ean:       json['ean']?.toString()        ?? '',
    gtin:      json['gtin']?.toString()       ?? '',
    libTaille: json['libTaille']?.toString()  ?? '',
    codeMod:   json['codeMod']?.toString()    ?? '',
  );

  PvaLigne withCodeMod(String codeMod) => PvaLigne(
    qte:       qte,
    ean:       ean,
    gtin:      gtin,
    libTaille: libTaille,
    codeMod:   codeMod,
  );

  @override
  String toString() =>
      'PvaLigne(gtin: $gtin, libTaille: $libTaille, qte: $qte)';
}

// ── PvaReceptionModel ─────────────────────────────────────────

class PvaReceptionModel {
  final String       codeSupport;
  final List<PvaLigne> lignes;

  const PvaReceptionModel({
    required this.codeSupport,
    required this.lignes,
  });

  factory PvaReceptionModel.fromJson(Map<String, dynamic> json) {
    final lignesJson = json['lignes'] as List<dynamic>? ?? [];
    return PvaReceptionModel(
      codeSupport: json['codeSupport']?.toString() ?? '',
      lignes: lignesJson
          .map((e) => PvaLigne.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  int get totalAttendu => lignes.fold(0, (sum, l) => sum + l.qte);
}

// ── PvaLigneResult ────────────────────────────────────────────

class PvaLigneResult {
  final PvaLigne ligne;
  final int      qteLue;

  const PvaLigneResult({
    required this.ligne,
    required this.qteLue,
  });

  bool get isOk => qteLue >= ligne.qte;

  PvaLigneResult copyWith({int? qteLue}) => PvaLigneResult(
    ligne:  ligne,
    qteLue: qteLue ?? this.qteLue,
  );
}