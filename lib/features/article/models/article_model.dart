class ArticleModel {
  final String libArticle;
  final String libRayon;
  final String libSaison;
  final String libFamille;
  final String libSousFamille;
  final String libTheme;
  final String codeMod;
  final double prixVente;
  final String gencode;
  final String libTaille;
  final String marque;
  final String codeFsr;
  final String gtin;
  final String libColoris;
  final String codeRayon;
  final String codeFamille;
  final String codeSsFamille;
  final String codeMarque;
  final String codeMarche;
  final int artIdentifiant;

  ArticleModel({
    required this.libArticle,
    required this.libRayon,
    required this.libSaison,
    required this.libFamille,
    required this.libSousFamille,
    required this.libTheme,
    required this.codeMod,
    required this.prixVente,
    required this.gencode,
    required this.libTaille,
    required this.marque,
    required this.codeFsr,
    required this.gtin,
    required this.libColoris,
    required this.codeRayon,
    required this.codeFamille,
    required this.codeSsFamille,
    required this.codeMarque,
    required this.codeMarche,
    required this.artIdentifiant,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      libArticle:    json['libArticle']    as String? ?? '',
      libRayon:      json['libRayon']      as String? ?? '',
      libSaison:     json['libSaison']     as String? ?? '',
      libFamille:    json['libFamille']    as String? ?? '',
      libSousFamille:json['libSousFamille']as String? ?? '',
      libTheme:      json['libTheme']      as String? ?? '',
      codeMod:       json['codeMod']       as String? ?? '',
      prixVente:     (json['prixVente'] as num?)?.toDouble() ?? 0.0,
      gencode:       json['gencode']       as String? ?? '',
      libTaille:     json['libTaille']     as String? ?? '',
      marque:        json['marque']        as String? ?? '',
      codeFsr:       json['codeFsr']       as String? ?? '',
      gtin:          json['gtin']          as String? ?? '',
      libColoris:    json['libColoris']    as String? ?? '',
      codeRayon:     json['codeRayon']     as String? ?? '',
      codeFamille:   json['codeFamille']   as String? ?? '',
      codeSsFamille: json['codeSsFamille'] as String? ?? '',
      codeMarque:    json['codeMarque']    as String? ?? '',
      codeMarche:    json['codeMarche']    as String? ?? '',
      artIdentifiant:(json['artIdentifiant'] as num?)?.toInt() ?? 0,
    );
  }

  String get prixFormate =>
      '${prixVente.toStringAsFixed(2).replaceAll('.', ',')} €';
}