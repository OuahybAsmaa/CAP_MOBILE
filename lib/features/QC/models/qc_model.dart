class QcTaille {
  final String taille;
  final int qte;

  const QcTaille({required this.qte, required this.taille});

  factory QcTaille.fromJson(Map<String, dynamic> json) => QcTaille(
    taille:    json['taille'].toString(),
    qte: (json['qte'] as num?)?.toInt() ?? 0,
  );
}

class QcColis {
  final String codeColis;
  final int nbCol;
  final int nbArt;
  final String supCommande;
  final String codeSaison;
  final int pcb;
  final double long;
  final double larg;
  final double haut;
  final String img;
  final List<QcTaille> tailles;

  const QcColis({
    required this.codeColis,
    required this.nbCol,
    required this.nbArt,
    required this.supCommande,
    required this.codeSaison,
    required this.pcb,
    required this.long,
    required this.larg,
    required this.haut,
    required this.img,
    required this.tailles,
  });

  factory QcColis.fromJson(Map<String, dynamic> json) => QcColis(
    codeColis:   json['CodeColis']     as String? ?? '',
    nbCol:       (json['NbCol']        as num?)?.toInt() ?? 0,
    nbArt:       (json['NbArt']        as num?)?.toInt() ?? 0,
    supCommande: json['SupeCommande']  as String? ?? '',
    codeSaison:  json['CodeSaison']    as String? ?? '',
    pcb:         (json['PCB']          as num?)?.toInt() ?? 0,
    long:        (json['Long']         as num?)?.toDouble() ?? 0,
    larg:        (json['Larg']         as num?)?.toDouble() ?? 0,
    haut:        (json['Haut']         as num?)?.toDouble() ?? 0,
    img: json['Img'] as String? ?? '',
    tailles: (json['taille'] as List<dynamic>? ?? [])
        .map((e) => QcTaille.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class QcProductionModel {
  final String code;
  final String marque;
  final String saison;
  final String rayon;
  final String famille;
  final String sousFamille;
  final List<QcColis> colis;

  const QcProductionModel({
    required this.code,
    required this.marque,
    required this.saison,
    required this.rayon,
    required this.famille,
    required this.sousFamille,
    required this.colis,
  });

  factory QcProductionModel.fromJson(Map<String, dynamic> json) =>
      QcProductionModel(
        code:        json['code']        as String? ?? '',
        marque:      json['marque']      as String? ?? '',
        saison:      json['saison']      as String? ?? '',
        rayon:       json['rayon']       as String? ?? '',
        famille:     json['famille']     as String? ?? '',
        sousFamille: json['sousFamille'] as String? ?? '',
        colis: (json['Colis'] as List<dynamic>? ?? [])
            .map((e) => QcColis.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}