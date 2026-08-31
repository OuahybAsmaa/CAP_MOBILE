class OperationCommerciale {
  final int codePromo;
  final String libPromo;
  final String theme;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String typeApplication;
  final int etatPromo;
  final bool fds;

  const OperationCommerciale({
    required this.codePromo,
    required this.libPromo,
    required this.theme,
    required this.dateDebut,
    required this.dateFin,
    required this.typeApplication,
    required this.etatPromo,
    required this.fds,
  });

  factory OperationCommerciale.fromJson(Map<String, dynamic> json) {
    return OperationCommerciale(
      codePromo:       json['codePromo'] as int,
      libPromo:        json['libPromo'] as String,
      theme:           json['theme'] as String,
      dateDebut:       DateTime.parse(json['dateDebut'] as String),
      dateFin:         DateTime.parse(json['dateFin'] as String),
      typeApplication: json['typeApplication'] as String,
      etatPromo:       json['etatPromo'] as int,
      fds:             json['fds'] as bool,
    );
  }
}

class PromoResult {
  final String libPromo;
  final double pvInitial;
  final double pvPromo;
  final int percentPromo;
  final String typeApplication;
  bool get isEnPromo => percentPromo > 0;

  const PromoResult({
    required this.libPromo,
    required this.pvInitial,
    required this.pvPromo,
    required this.percentPromo,
    required this.typeApplication,
  });

  factory PromoResult.fromJson(Map<String, dynamic> json) {
    return PromoResult(
      libPromo:        json['libPromo'] as String,
      pvInitial:       (json['pvInitial'] as num).toDouble(),
      pvPromo:         (json['pvPromo'] as num).toDouble(),
      percentPromo:    json['percentPromo'] as int,
      typeApplication: json['typeApplication'] as String,
    );
  }
}

class ModeleProduit {
  final String codeMod;
  final double pvInitial;
  final double pvPromo;
  final int stock;
  final bool nouveaute;

  const ModeleProduit({
    required this.codeMod,
    required this.pvInitial,
    required this.pvPromo,
    required this.stock,
    required this.nouveaute,
  });

  factory ModeleProduit.fromJson(Map<String, dynamic> json) {
    return ModeleProduit(
      codeMod:   json['codeMod'] as String,
      pvInitial: (json['pvInitial'] as num).toDouble(),
      pvPromo:   (json['pvPromo'] as num).toDouble(),
      stock:     json['stock'] as int,
      nouveaute: json['nouveaute'] as bool,
    );
  }
}