class ExpLigne {
  final int    qte;
  final String ean;
  final String gtin;
  final String libTaille;

  const ExpLigne({
    required this.qte,
    required this.ean,
    required this.gtin,
    required this.libTaille,
  });

  factory ExpLigne.fromJson(Map<String, dynamic> json) => ExpLigne(
    qte:       (json['qte'] as num?)?.toInt() ?? 0,
    ean:       json['ean']?.toString()       ?? '',
    gtin:      json['gtin']?.toString()      ?? '',
    libTaille: json['libTaille']?.toString() ?? '',
  );

  @override
  String toString() =>
      'ExpLigne(gtin: $gtin, libTaille: $libTaille, qte: $qte)';
}

// ── Réception complète retournée par l'API ────────────────────

class ExpReceptionModel {
  final String  source;        // "EXP"
  final String  codeRecep;
  final int     codeMag;
  final String  nomMag;
  final int     codeMagDest;
  final String  nomMagDest;
  final String? nomDep;
  final String? dateExp;
  final String? dateLivr;
  final String? etat;
  final List<ExpLigne> lignes;

  const ExpReceptionModel({
    required this.source,
    required this.codeRecep,
    required this.codeMag,
    required this.nomMag,
    required this.codeMagDest,
    required this.nomMagDest,
    this.nomDep,
    this.dateExp,
    this.dateLivr,
    this.etat,
    required this.lignes,
  });

  factory ExpReceptionModel.fromJson(Map<String, dynamic> json) {
    final lignesJson = json['lignes'] as List<dynamic>? ?? [];
    return ExpReceptionModel(
      source:      json['source']?.toString()      ?? '',
      codeRecep:   json['codeRecep']?.toString()   ?? '',
      codeMag:     (json['codeMag']  as num?)?.toInt() ?? 0,
      nomMag:      json['nomMag']?.toString()      ?? '',
      codeMagDest: (json['codeMagDest'] as num?)?.toInt() ?? 0,
      nomMagDest:  json['nomMagDest']?.toString()  ?? '',
      nomDep:      json['nomDep']?.toString(),
      dateExp:     json['dateExp']?.toString(),
      dateLivr:    json['dateLivr']?.toString(),
      etat:        json['etat']?.toString(),
      lignes:      lignesJson
          .map((e) => ExpLigne.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  int get totalAttendu => lignes.fold(0, (sum, l) => sum + l.qte);

  String get dateExpFormatted {
    if (dateExp == null) return '—';
    try {
      final dt = DateTime.parse(dateExp!);
      return '${dt.day.toString().padLeft(2, '0')}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.year}';
    } catch (_) {
      return dateExp!;
    }
  }
}


class ExpLigneResult {
  final ExpLigne ligne;       // données API
  final int      qteLue;      // scannée par le lecteur RFID

  const ExpLigneResult({
    required this.ligne,
    required this.qteLue,
  });

  bool get isOk => qteLue >= ligne.qte;

  ExpLigneResult copyWith({int? qteLue}) => ExpLigneResult(
    ligne:  ligne,
    qteLue: qteLue ?? this.qteLue,
  );
}