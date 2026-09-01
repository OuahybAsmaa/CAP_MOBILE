// =============================================================================
// CapMobile — Module Swapp — Statistiques satisfaction client (My Goodays)
// -----------------------------------------------------------------------------
// Fonctionnalité : Agrégat affiché par MyGoodaysPage — note globale, écarts,
//                  NPS, répartition promoteurs/passifs/détracteurs, indicateurs
//                  de réactivité et série d'évolution.
// Spécifications : Un objet par période (voir GoodaysPeriode) ; pourcentages
//                  exprimés sur 100 ; [fromJson] prêt pour l'API Goodays.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/swapp/models/goodays/goodays_metric.dart';
import 'package:cap_mobile/swapp/models/goodays/goodays_score_point.dart';

/// Photographie de la satisfaction client sur une période donnée.
class GoodaysStats {
  /// Note globale du magasin, sur [scoreMax].
  final double score;

  /// Barème de la note (5 chez Goodays).
  final double scoreMax;

  /// Écart avec la période précédente (P-1).
  final double deltaPeriodePrecedente;

  /// Écart avec la moyenne du réseau.
  final double deltaReseau;

  /// Net Promoter Score, de -100 à 100.
  final int nps;

  /// Part des promoteurs, en %.
  final double promoteursPct;

  /// Part des passifs, en %.
  final double passifsPct;

  /// Part des détracteurs, en %.
  final double detracteursPct;

  /// Délai moyen de réponse aux avis, en heures.
  final int tempsReponseHeures;

  /// Note de qualité des réponses apportées, sur 5.
  final double qualiteReponse;

  /// Part des avis ayant reçu une réponse, en %.
  final double tauxReponse;

  /// Série chronologique affichée dans la carte « Évolution ».
  final List<GoodaysScorePoint> evolution;

  const GoodaysStats({
    required this.score,
    required this.deltaPeriodePrecedente,
    required this.deltaReseau,
    required this.nps,
    required this.promoteursPct,
    required this.passifsPct,
    required this.detracteursPct,
    required this.tempsReponseHeures,
    required this.qualiteReponse,
    required this.tauxReponse,
    required this.evolution,
    this.scoreMax = 5,
  });

  /// Note formatée « 4.51 » (2 décimales, point comme sur la maquette).
  String get scoreLabel => score.toStringAsFixed(2);

  /// Écart formaté à la française avec son signe : « +0,67 », « -0,12 ».
  static String signedLabel(double value) {
    final abs = value.abs().toStringAsFixed(2).replaceAll('.', ',');
    return value < 0 ? '-$abs' : '+$abs';
  }

  /// Valeur maximale de l'axe Y du graphique pour la métrique demandée.
  ///
  /// Les notes gardent l'échelle fixe 0→5 ; le volume d'avis s'adapte aux
  /// données pour rester lisible quel que soit le magasin.
  double maxYFor(GoodaysMetric metric) {
    if (metric != GoodaysMetric.clients) return scoreMax;
    final peak = evolution.fold<double>(
      0,
      (max, p) => p.clients > max ? p.clients.toDouble() : max,
    );
    if (peak <= 0) return 10;
    // Arrondi à la dizaine supérieure pour des graduations rondes.
    return (peak / 10).ceilToDouble() * 10;
  }

  /// TODO(API) : brancher sur `SwappApiService.fetchGoodaysStats(periode)`.
  factory GoodaysStats.fromJson(Map<String, dynamic> json) {
    final points = (json['evolution'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(GoodaysScorePoint.fromJson)
        .toList();

    return GoodaysStats(
      score: (json['score'] as num?)?.toDouble() ?? 0,
      scoreMax: (json['scoreMax'] as num?)?.toDouble() ?? 5,
      deltaPeriodePrecedente:
          (json['deltaPeriodePrecedente'] as num?)?.toDouble() ?? 0,
      deltaReseau: (json['deltaReseau'] as num?)?.toDouble() ?? 0,
      nps: (json['nps'] as num?)?.toInt() ?? 0,
      promoteursPct: (json['promoteursPct'] as num?)?.toDouble() ?? 0,
      passifsPct: (json['passifsPct'] as num?)?.toDouble() ?? 0,
      detracteursPct: (json['detracteursPct'] as num?)?.toDouble() ?? 0,
      tempsReponseHeures: (json['tempsReponseHeures'] as num?)?.toInt() ?? 0,
      qualiteReponse: (json['qualiteReponse'] as num?)?.toDouble() ?? 0,
      tauxReponse: (json['tauxReponse'] as num?)?.toDouble() ?? 0,
      evolution: points,
    );
  }
}
