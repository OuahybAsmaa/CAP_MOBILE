// =============================================================================
// CapMobile — Module Swapp — Données de démonstration My Goodays
// -----------------------------------------------------------------------------
// Fonctionnalité : Jeu de données local utilisé tant que l'API Goodays n'est
//                  pas branchée. Une entrée par période sélectionnable.
// Spécifications : REMPLACER par SwappApiService.fetchGoodaysStats(periode) —
//                  la page ne dépend que de GoodaysStats, aucun autre changement
//                  ne sera nécessaire côté UI.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/swapp/models/goodays/goodays_periode.dart';
import 'package:cap_mobile/swapp/models/goodays/goodays_score_point.dart';
import 'package:cap_mobile/swapp/models/goodays/goodays_stats.dart';

/// Fabrique de statistiques de démonstration.
abstract final class GoodaysDemoData {
  /// Statistiques simulées pour la [periode] demandée.
  static GoodaysStats forPeriode(GoodaysPeriode periode) => switch (periode) {
    GoodaysPeriode.semaine => _semaine,
    GoodaysPeriode.mois => _mois,
    GoodaysPeriode.trimestre => _trimestre,
    GoodaysPeriode.semestre => _semestre,
    GoodaysPeriode.annee => _annee,
  };

  /// Construit une série à partir de libellés et de notes alignés.
  ///
  /// Le volume d'avis et la moyenne glissante sont dérivés de la note pour
  /// éviter de saisir trois listes en parallèle dans les données de démo.
  static List<GoodaysScorePoint> _serie(
    List<String> labels,
    List<double> scores,
    int clientsBase,
  ) {
    return [
      for (var i = 0; i < labels.length; i++)
        GoodaysScorePoint(
          label: labels[i],
          score: scores[i],
          clients: clientsBase + ((scores[i] - 4.5) * 240).round(),
          moyenne: double.parse(
            (scores.take(i + 1).reduce((a, b) => a + b) / (i + 1))
                .toStringAsFixed(2),
          ),
        ),
    ];
  }

  static final _mois = GoodaysStats(
    score: 4.51,
    deltaPeriodePrecedente: 0.67,
    deltaReseau: 0,
    nps: 78,
    promoteursPct: 83,
    passifsPct: 14,
    detracteursPct: 3,
    tempsReponseHeures: 4,
    qualiteReponse: 4.75,
    tauxReponse: 99.27,
    evolution: _serie(
      const [
        'S23', 'S24', 'S25', 'S26', 'S27', 'S28', 'S29', //
        'S30', 'S31', 'S32', 'S33', 'S34', 'S35',
      ],
      const [
        4.52, 4.56, 4.55, 4.53, 4.49, 4.51, 4.49, //
        4.52, 4.55, 4.54, 4.53, 4.53, 4.51,
      ],
      120,
    ),
  );

  static final _semaine = GoodaysStats(
    score: 4.62,
    deltaPeriodePrecedente: 0.11,
    deltaReseau: 0.04,
    nps: 81,
    promoteursPct: 86,
    passifsPct: 12,
    detracteursPct: 2,
    tempsReponseHeures: 3,
    qualiteReponse: 4.80,
    tauxReponse: 98.10,
    evolution: _serie(
      const ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'],
      const [4.58, 4.61, 4.64, 4.60, 4.66, 4.63, 4.62],
      28,
    ),
  );

  static final _trimestre = GoodaysStats(
    score: 4.47,
    deltaPeriodePrecedente: 0.32,
    deltaReseau: -0.05,
    nps: 74,
    promoteursPct: 80,
    passifsPct: 16,
    detracteursPct: 4,
    tempsReponseHeures: 5,
    qualiteReponse: 4.68,
    tauxReponse: 97.40,
    evolution: _serie(
      const ['Juin', 'Juil', 'Août'],
      const [4.42, 4.48, 4.51],
      430,
    ),
  );

  static final _semestre = GoodaysStats(
    score: 4.44,
    deltaPeriodePrecedente: 0.21,
    deltaReseau: -0.02,
    nps: 72,
    promoteursPct: 78,
    passifsPct: 17,
    detracteursPct: 5,
    tempsReponseHeures: 6,
    qualiteReponse: 4.61,
    tauxReponse: 96.80,
    evolution: _serie(
      const ['Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août'],
      const [4.35, 4.39, 4.44, 4.42, 4.48, 4.51],
      420,
    ),
  );

  static final _annee = GoodaysStats(
    score: 4.39,
    deltaPeriodePrecedente: 0.48,
    deltaReseau: 0.03,
    nps: 69,
    promoteursPct: 76,
    passifsPct: 18,
    detracteursPct: 6,
    tempsReponseHeures: 7,
    qualiteReponse: 4.55,
    tauxReponse: 95.20,
    evolution: _serie(
      const [
        'Sep', 'Oct', 'Nov', 'Déc', 'Jan', 'Fév', //
        'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août',
      ],
      const [
        4.28, 4.31, 4.30, 4.34, 4.33, 4.36, //
        4.35, 4.39, 4.44, 4.42, 4.48, 4.51,
      ],
      410,
    ),
  );
}
