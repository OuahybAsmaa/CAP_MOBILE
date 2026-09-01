// =============================================================================
// CapMobile — Module Swapp — My Goodays (satisfaction client)
// -----------------------------------------------------------------------------
// Fonctionnalité : Tableau de bord de la satisfaction magasin — note globale,
//                  écarts P-1 / réseau, score NPS, répartition promoteurs,
//                  indicateurs de réactivité et courbe d'évolution.
// Design         : Header navy SwappAttenteColors (comme Mes remises) ; fond
//                  lavande SwappMenuColors.bg ; cartes blanches arrondies 14 ;
//                  accent violet, étoiles ambre, écarts vert / rouge.
// UI             : Ouverte par la tuile « My Goodays » de SwappMenuPage ;
//                  pastilles de période en haut ; carte note pleine largeur ;
//                  NPS, donut, indicateurs (vagues) et courbe avec remplissage.
//                  Donut et courbe s'animent au chargement ; un tap les agrandit
//                  dans AppPopup.
// Spécifications : Données GoodaysDemoData — un seul point de branchement API
//                  dans _loadStats(). Donut et courbe dessinés en CustomPainter
//                  (aucune dépendance graphique dans le projet).
// Auteur         : H.AMIZIANI
// =============================================================================

import 'dart:math' as math;

import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/core/widgets/app_popup.dart';
import 'package:cap_mobile/swapp/models/goodays/goodays.dart';
import 'package:cap_mobile/core/apiswap/goodays/data/goodays_test_data.dart';
import 'package:cap_mobile/swapp/pages/goodays/goodays_avis_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_attente_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- Palette locale ---------------------------------------------------------
const _violet = AppColors.primary;
const _violetSoft = AppColors.primarySoft;
const _amber = Color(0xFFFBB040);
const _starEmpty = Color(0xFFD8DBE8);
const _green = Color(0xFF22C55E);
const _greenSoft = Color(0xFFDCFCE7);
const _red = Color(0xFFEF4444);
const _blue = Color(0xFF3B82F6);
const _blueSoft = Color(0xFFDCEAFE);
const _sky = Color(0xFF38BDF8);
const _grid = Color(0xFFE8EAF3);
const _ink = SwappMenuColors.ink;
const _inkDim = SwappMenuColors.inkDim;

/// Écran « My Goodays » — synthèse des avis clients du magasin.
class MyGoodaysPage extends StatefulWidget {
  const MyGoodaysPage({super.key});

  static Route<void> fadeRoute() => swappMenuFadeRoute(const MyGoodaysPage());

  @override
  State<MyGoodaysPage> createState() => _MyGoodaysPageState();
}

class _MyGoodaysPageState extends State<MyGoodaysPage> {
  GoodaysPeriode _periode = GoodaysPeriode.mois;
  GoodaysMetric _metric = GoodaysMetric.score;
  int _windowWeeks = 12;
  late GoodaysStats _stats = _loadStats(_periode);

  /// Série affichée dans la courbe (dernières [_windowWeeks] semaines).
  List<GoodaysScorePoint> get _evolutionWindow {
    final all = _stats.evolution;
    if (all.length <= _windowWeeks) return all;
    return all.sublist(all.length - _windowWeeks);
  }

  /// Point de branchement unique de l'API.
  ///
  /// TODO(API) : remplacer par `SwappApiService.fetchGoodaysStats(periode)` —
  /// prévoir un état de chargement, le reste de la page est déjà piloté par
  /// l'objet [GoodaysStats] retourné.
  GoodaysStats _loadStats(GoodaysPeriode periode) =>
      GoodaysDemoData.forPeriode(periode);

  void _selectPeriode(GoodaysPeriode periode) {
    if (periode == _periode) return;
    HapticFeedback.selectionClick();
    setState(() {
      _periode = periode;
      _stats = _loadStats(periode);
    });
  }

  void _selectMetric(GoodaysMetric metric) {
    if (metric == _metric) return;
    HapticFeedback.selectionClick();
    setState(() => _metric = metric);
  }

  void _openDonutPopup() {
    HapticFeedback.lightImpact();
    AppPopup.show<void>(
      context: context,
      showIcon: false,
      maxWidth: 380,
      title: 'Répartition des avis',
      body: _DonutExpandBody(stats: _stats),
      actions: const [AppPopupAction(label: 'Fermer')],
    );
  }

  void _openLinePopup() {
    HapticFeedback.lightImpact();
    AppPopup.show<void>(
      context: context,
      showIcon: false,
      maxWidth: 400,
      title: _metric.chartTitle,
      body: _LineExpandBody(
        points: _evolutionWindow,
        metric: _metric,
        maxY: _stats.maxYFor(_metric),
      ),
      actions: const [AppPopupAction(label: 'Fermer')],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.25);
    double dp(double v) => v * scale;
    final insets = MediaQuery.paddingOf(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: swappOverlayStyle(statusBarColor: SwappAttenteColors.headerNavy),
      child: Scaffold(
        backgroundColor: SwappMenuColors.bg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              dp: dp,
              top: insets.top,
              onBack: () => Navigator.pop(context),
              onMessages: () =>
                  Navigator.push(context, GoodaysAvisPage.fadeRoute()),
            ),
            Expanded(
              child: ListView(
                // Marge basse = barre de navigation Android incluse.
                padding: EdgeInsets.fromLTRB(
                  dp(12),
                  dp(12),
                  dp(12),
                  dp(20) + insets.bottom,
                ),
                children: [
                    _PeriodPills(
                      dp: dp,
                      selected: _periode,
                      onSelect: _selectPeriode,
                    ),
                    SizedBox(height: dp(12)),
                    _ScoreCard(
                      dp: dp,
                      stats: _stats,
                      metric: _metric,
                      onSelectMetric: _selectMetric,
                    ),
                    SizedBox(height: dp(10)),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 9,
                            child: _NpsCard(dp: dp, stats: _stats),
                          ),
                          SizedBox(width: dp(10)),
                          Expanded(
                            flex: 11,
                            child: _RepartitionCard(
                              dp: dp,
                              stats: _stats,
                              onExpand: _openDonutPopup,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: dp(10)),
                    _IndicateursRow(dp: dp, stats: _stats),
                    SizedBox(height: dp(10)),
                    _EvolutionCard(
                      dp: dp,
                      points: _evolutionWindow,
                      metric: _metric,
                      maxY: _stats.maxYFor(_metric),
                      weeks: _windowWeeks,
                      onWeeksChanged: (weeks) {
                        HapticFeedback.selectionClick();
                        setState(() => _windowWeeks = weeks);
                      },
                      onExpand: _openLinePopup,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header navy — même bleu que Mes remises / Mes réceptions
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final double Function(double) dp;
  final double top;
  final VoidCallback onBack;
  final VoidCallback onMessages;

  const _Header({
    required this.dp,
    required this.top,
    required this.onBack,
    required this.onMessages,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SwappAttenteColors.headerNavy,
      child: Padding(
        padding: EdgeInsets.fromLTRB(dp(14), top + dp(8), dp(14), dp(16)),
        child: Row(
          children: [
            SwappAttenteNavSquare(
              dp: dp,
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            ),
            SizedBox(width: dp(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FIDÉLITÉ',
                    style: TextStyle(
                      fontSize: dp(9.5),
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.55),
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: dp(2)),
                  Text(
                    'My Goodays',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: dp(17),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            SwappAttenteNavSquare(
              dp: dp,
              icon: Icons.forum_rounded,
              onTap: onMessages,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pastilles de période — barre horizontale Semaine → Année
// ---------------------------------------------------------------------------
class _PeriodPills extends StatelessWidget {
  final double Function(double) dp;
  final GoodaysPeriode selected;
  final ValueChanged<GoodaysPeriode> onSelect;

  const _PeriodPills({
    required this.dp,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      dp: dp,
      padding: EdgeInsets.all(dp(4)),
      child: Row(
        children: [
          for (final periode in GoodaysPeriode.values)
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(periode),
                  borderRadius: BorderRadius.circular(dp(20)),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: periode == selected ? _violet : Colors.transparent,
                      borderRadius: BorderRadius.circular(dp(20)),
                    ),
                    padding: EdgeInsets.symmetric(vertical: dp(9)),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        periode.label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: dp(11.5),
                          fontWeight: FontWeight.w700,
                          color: periode == selected ? Colors.white : _ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte note globale — 4.51/5, écarts P-1 / réseau, étoiles et onglets
// ---------------------------------------------------------------------------
class _ScoreCard extends StatelessWidget {
  final double Function(double) dp;
  final GoodaysStats stats;
  final GoodaysMetric metric;
  final ValueChanged<GoodaysMetric> onSelectMetric;

  const _ScoreCard({
    required this.dp,
    required this.stats,
    required this.metric,
    required this.onSelectMetric,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      dp: dp,
      padding: EdgeInsets.fromLTRB(dp(12), dp(12), dp(12), dp(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            stats.scoreLabel,
                            style: TextStyle(
                              fontSize: dp(40),
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E3A8A),
                              height: 1,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: dp(4),
                              left: dp(3),
                            ),
                            child: Text(
                              '/${stats.scoreMax.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: dp(14),
                                fontWeight: FontWeight.w700,
                                color: _inkDim,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: dp(8)),
                    _StarRow(value: stats.score, size: dp(22), gap: dp(1)),
                  ],
                ),
              ),
              SizedBox(width: dp(10)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _DeltaBlock(
                    dp: dp,
                    label: 'vs P-1',
                    value: GoodaysStats.signedLabel(
                      stats.deltaPeriodePrecedente,
                    ),
                    leading: _DeltaLeading.arrow,
                    positive: stats.deltaPeriodePrecedente > 0,
                  ),
                  SizedBox(height: dp(6)),
                  _DeltaBlock(
                    dp: dp,
                    label: 'vs rézo',
                    value: GoodaysStats.signedLabel(stats.deltaReseau),
                    leading: _DeltaLeading.dot,
                    positive: stats.deltaReseau > 0,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: dp(12)),
          _MetricTabs(dp: dp, selected: metric, onSelect: onSelectMetric),
        ],
      ),
    );
  }
}

enum _DeltaLeading { arrow, dot }

/// Ligne d'écart : triangle vert (P-1) ou point violet (réseau).
class _DeltaBlock extends StatelessWidget {
  final double Function(double) dp;
  final String label;
  final String value;
  final _DeltaLeading leading;
  final bool positive;

  const _DeltaBlock({
    required this.dp,
    required this.label,
    required this.value,
    required this.leading,
    required this.positive,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = positive ? _green : _red;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dp(8), vertical: dp(6)),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F5FB),
        borderRadius: BorderRadius.circular(dp(10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading == _DeltaLeading.arrow)
            Icon(
              positive
                  ? Icons.arrow_drop_up_rounded
                  : Icons.arrow_drop_down_rounded,
              size: dp(18),
              color: valueColor,
            )
          else
            Container(
              width: dp(8),
              height: dp(8),
              margin: EdgeInsets.symmetric(horizontal: dp(5)),
              decoration: const BoxDecoration(
                color: _violet,
                shape: BoxShape.circle,
              ),
            ),
          Text(
            label,
            style: TextStyle(
              fontSize: dp(10),
              fontWeight: FontWeight.w600,
              color: _inkDim,
            ),
          ),
          SizedBox(width: dp(8)),
          Text(
            value,
            style: TextStyle(
              fontSize: dp(12),
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onglets Score / Clients / Moy. — pilotent la série de la courbe
// ---------------------------------------------------------------------------
class _MetricTabs extends StatelessWidget {
  final double Function(double) dp;
  final GoodaysMetric selected;
  final ValueChanged<GoodaysMetric> onSelect;

  const _MetricTabs({
    required this.dp,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dp(4)),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1FB),
        borderRadius: BorderRadius.circular(dp(12)),
      ),
      child: Row(
        children: [
          for (final metric in GoodaysMetric.values)
            Expanded(
              child: _MetricTab(
                dp: dp,
                metric: metric,
                active: metric == selected,
                onTap: () => onSelect(metric),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricTab extends StatelessWidget {
  final double Function(double) dp;
  final GoodaysMetric metric;
  final bool active;
  final VoidCallback onTap;

  const _MetricTab({
    required this.dp,
    required this.metric,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(10)),
        child: Ink(
          decoration: BoxDecoration(
            color: active ? _violet : Colors.transparent,
            borderRadius: BorderRadius.circular(dp(10)),
          ),
          padding: EdgeInsets.symmetric(vertical: dp(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                metric.icon,
                size: dp(14),
                color: active ? Colors.white : _inkDim,
              ),
              SizedBox(width: dp(5)),
              Flexible(
                child: Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: dp(11),
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : _inkDim,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte Score NPS — dégradé violet, badge étoile et jauge
// ---------------------------------------------------------------------------
class _NpsCard extends StatelessWidget {
  final double Function(double) dp;
  final GoodaysStats stats;

  const _NpsCard({required this.dp, required this.stats});

  @override
  Widget build(BuildContext context) {
    // Le NPS va de -100 à 100 : on ramène la jauge sur 0 → 1.
    final ratio = ((stats.nps + 100) / 200).clamp(0.0, 1.0);
    final greenFlex = math.max((ratio * 100).round(), 8);
    final blueFlex = math.max(100 - greenFlex, 8);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(dp(16)),
        boxShadow: [
          BoxShadow(
            color: _violet.withValues(alpha: 0.35),
            blurRadius: dp(14),
            offset: Offset(0, dp(6)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(dp(16)),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4C6FFF), Color(0xFF7B4DFF)],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _StarFieldPainter())),
            Padding(
              padding: EdgeInsets.fromLTRB(dp(14), dp(12), dp(14), dp(14)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SCORE NPS',
                    style: TextStyle(
                      fontSize: dp(11),
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.92),
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: dp(6)),
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            '${stats.nps}',
                            style: TextStyle(
                              fontSize: dp(40),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: dp(28),
                        height: dp(28),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: _amber,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.star_rounded,
                          size: dp(17),
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: dp(12)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(dp(4)),
                    child: SizedBox(
                      height: dp(6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: greenFlex,
                            child: const ColoredBox(color: Color(0xFF4ADE80)),
                          ),
                          Expanded(
                            flex: blueFlex,
                            child: const ColoredBox(color: Color(0xFF7DD3FC)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Points lumineux discrets sur le fond de la carte NPS.
class _StarFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.22);
    const dots = <(double, double, double)>[
      (0.12, 0.18, 1.2),
      (0.28, 0.08, 0.8),
      (0.55, 0.22, 1.0),
      (0.78, 0.12, 1.4),
      (0.90, 0.38, 0.9),
      (0.18, 0.62, 1.1),
      (0.42, 0.78, 0.7),
      (0.68, 0.70, 1.3),
      (0.86, 0.86, 0.8),
      (0.08, 0.88, 1.0),
    ];
    for (final d in dots) {
      canvas.drawCircle(
        Offset(size.width * d.$1, size.height * d.$2),
        d.$3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Carte répartition — donut promoteurs / passifs / détracteurs
// ---------------------------------------------------------------------------
class _RepartitionCard extends StatelessWidget {
  final double Function(double) dp;
  final GoodaysStats stats;
  final VoidCallback onExpand;

  const _RepartitionCard({
    required this.dp,
    required this.stats,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <(String, double, Color)>[
      ('Promoteur', stats.promoteursPct, _violet),
      ('Passifs', stats.passifsPct, const Color(0xFF4ADE80)),
      ('Détracteurs', stats.detracteursPct, _sky),
    ];

    return _Card(
      dp: dp,
      padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(12)),
      child: Stack(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onExpand,
                child: _AnimatedDonut(
                  size: dp(86),
                  stroke: dp(17),
                  values: [for (final p in parts) p.$2],
                  colors: [for (final p in parts) p.$3],
                  centerSize: dp(34),
                  centerIconSize: dp(19),
                ),
              ),
              SizedBox(width: dp(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final part in parts) ...[
                      _LegendRow(
                        dp: dp,
                        color: part.$3,
                        label: part.$1,
                        percent: part.$2,
                      ),
                      if (part != parts.last) SizedBox(height: dp(9)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _ExpandBtn(dp: dp, onTap: onExpand),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final double Function(double) dp;
  final Color color;
  final String label;
  final double percent;

  const _LegendRow({
    required this.dp,
    required this.color,
    required this.label,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: dp(8),
          height: dp(8),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: dp(6)),
        Expanded(
          child: Text(
            '$label ${percent.toStringAsFixed(0)}%',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: dp(11),
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// Anneau segmenté — un arc par catégorie, séparés par un léger espace.
class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double stroke;
  final double progress;

  const _DonutPainter({
    required this.values,
    required this.colors,
    required this.stroke,
    this.progress = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, v) => sum + v);
    if (total <= 0 || progress <= 0) return;

    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    const gap = 0.06;
    var start = -math.pi / 2;
    var remaining = (2 * math.pi * progress).clamp(0.0, 2 * math.pi);

    for (var i = 0; i < values.length; i++) {
      if (remaining <= 0) break;
      final sweep = values[i] / total * 2 * math.pi;
      final drawn = math.min(sweep, remaining);
      paint.color = colors[i];
      canvas.drawArc(
        rect,
        start + gap / 2,
        math.max(drawn - gap, 0.02),
        false,
        paint,
      );
      start += sweep;
      remaining -= sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.stroke != stroke ||
      old.progress != progress ||
      !listEquals(old.values, values) ||
      !listEquals(old.colors, colors);
}

// ---------------------------------------------------------------------------
// Trois indicateurs de réactivité
// ---------------------------------------------------------------------------
class _IndicateursRow extends StatelessWidget {
  final double Function(double) dp;
  final GoodaysStats stats;

  const _IndicateursRow({required this.dp, required this.stats});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _IndicateurCard(
              dp: dp,
              icon: Icons.schedule_rounded,
              iconColor: _violet,
              iconBg: _violetSoft,
              label: 'Temps de réponse',
              value: '${stats.tempsReponseHeures}H',
              valueColor: _violet,
              sparkline: stats.evolution,
              sparkPhase: 0.2,
            ),
          ),
          SizedBox(width: dp(10)),
          Expanded(
            child: _IndicateurCard(
              dp: dp,
              icon: Icons.star_rounded,
              iconColor: _blue,
              iconBg: _blueSoft,
              label: 'Qualité de réponse',
              value: stats.qualiteReponse.toStringAsFixed(2),
              valueColor: _blue,
              stars: stats.qualiteReponse,
              sparkline: stats.evolution,
              sparkPhase: 1.1,
            ),
          ),
          SizedBox(width: dp(10)),
          Expanded(
            child: _IndicateurCard(
              dp: dp,
              icon: Icons.check_circle_rounded,
              iconColor: _green,
              iconBg: _greenSoft,
              label: 'Taux de réponse',
              value: '${stats.tauxReponse.toStringAsFixed(2)}%',
              valueColor: _green,
              sparkline: stats.evolution,
              sparkPhase: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _IndicateurCard extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final Color valueColor;
  final List<GoodaysScorePoint> sparkline;
  final double sparkPhase;

  /// Note à illustrer sous la valeur (carte « Qualité de réponse »).
  final double? stars;

  const _IndicateurCard({
    required this.dp,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.sparkline,
    required this.sparkPhase,
    this.stars,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      dp: dp,
      padding: EdgeInsets.fromLTRB(dp(10), dp(10), dp(10), dp(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: dp(26),
                height: dp(26),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: dp(15), color: iconColor),
              ),
              SizedBox(width: dp(4)),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: dp(9.5),
                    fontWeight: FontWeight.w600,
                    color: _inkDim,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(height: dp(6)),
          Text(
            value,
            style: TextStyle(
              fontSize: dp(18),
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          if (stars != null) ...[
            SizedBox(height: dp(3)),
            _StarRow(value: stars!, size: dp(10), gap: dp(0.5)),
          ],
          SizedBox(height: dp(6)),
          SizedBox(
            height: dp(26),
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(
                values: [for (final p in sparkline) p.score],
                color: iconColor,
                phase: sparkPhase,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vague décorative sous les KPI — suit la série si elle existe, sinon un sinus.
class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double phase;

  const _SparklinePainter({
    required this.values,
    required this.color,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const n = 18;
    final minV = values.isEmpty ? 0.0 : values.reduce(math.min);
    final maxV = values.isEmpty ? 1.0 : values.reduce(math.max);
    final span = (maxV - minV).abs() < 0.05 ? 0.2 : maxV - minV;

    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final t = i / (n - 1);
      var y = math.sin(t * math.pi * 2.4 + phase) * 0.28 + 0.55;
      if (values.length >= 2) {
        final idx = t * (values.length - 1);
        final lo = idx.floor();
        final hi = math.min(lo + 1, values.length - 1);
        final f = idx - lo;
        final v = values[lo] * (1 - f) + values[hi] * f;
        y = ((v - minV) / span).clamp(0.15, 0.85);
      }
      pts.add(Offset(size.width * t, size.height * (1 - y)));
    }

    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final cur = pts[i];
      final mid = Offset((prev.dx + cur.dx) / 2, (prev.dy + cur.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    path.lineTo(pts.last.dx, pts.last.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.color != color ||
      old.phase != phase ||
      !listEquals(old.values, values);
}

// ---------------------------------------------------------------------------
// Carte évolution — courbe de la métrique sélectionnée
// ---------------------------------------------------------------------------
class _EvolutionCard extends StatelessWidget {
  final double Function(double) dp;
  final List<GoodaysScorePoint> points;
  final GoodaysMetric metric;
  final double maxY;
  final int weeks;
  final ValueChanged<int> onWeeksChanged;
  final VoidCallback onExpand;

  const _EvolutionCard({
    required this.dp,
    required this.points,
    required this.metric,
    required this.maxY,
    required this.weeks,
    required this.onWeeksChanged,
    required this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    final entier = metric == GoodaysMetric.clients;

    return _Card(
      dp: dp,
      padding: EdgeInsets.fromLTRB(dp(12), dp(12), dp(12), dp(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  metric.chartTitle,
                  style: TextStyle(
                    fontSize: dp(12),
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E3A8A),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              _WeeksChip(dp: dp, weeks: weeks, onChanged: onWeeksChanged),
            ],
          ),
          SizedBox(height: dp(10)),
          GestureDetector(
            onTap: onExpand,
            child: SizedBox(
              height: dp(112),
              child: _AnimatedLineChart(
                values: [for (final p in points) p.valueFor(metric)],
                labels: [for (final p in points) p.label],
                maxY: maxY,
                dp: dp,
                decimals: entier ? 0 : 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filtre « 12 semaines » — calendrier + chevron, comme sur la maquette.
class _WeeksChip extends StatelessWidget {
  final double Function(double) dp;
  final int weeks;
  final ValueChanged<int> onChanged;

  const _WeeksChip({
    required this.dp,
    required this.weeks,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Fenêtre d\'évolution',
      padding: EdgeInsets.zero,
      offset: Offset(0, dp(36)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dp(12)),
      ),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final w in const [4, 8, 12])
          PopupMenuItem(
            value: w,
            child: Text(
              '$w semaines',
              style: TextStyle(
                fontWeight: w == weeks ? FontWeight.w800 : FontWeight.w600,
                color: w == weeks ? _violet : _ink,
              ),
            ),
          ),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: dp(8), vertical: dp(6)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(dp(10)),
          border: Border.all(color: const Color(0xFFE4E6F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_rounded, size: dp(12), color: _inkDim),
            SizedBox(width: dp(6)),
            Text(
              '$weeks semaines',
              style: TextStyle(
                fontSize: dp(11),
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
            SizedBox(width: dp(2)),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: dp(16),
              color: _inkDim,
            ),
          ],
        ),
      ),
    );
  }
}

/// Courbe + grille + libellés d'axes, sans dépendance externe.
class _LineChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final double maxY;
  final int divisions;
  final double Function(double) dp;
  final int decimals;
  final double progress;

  const _LineChartPainter({
    required this.values,
    required this.labels,
    required this.maxY,
    required this.divisions,
    required this.dp,
    required this.decimals,
    this.progress = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || maxY <= 0) return;

    final plot = Rect.fromLTRB(
      dp(20),
      dp(12),
      size.width - dp(4),
      size.height - dp(18),
    );
    final gridPaint = Paint()
      ..color = _grid
      ..strokeWidth = dp(1);

    for (var i = 0; i <= divisions; i++) {
      final y = plot.top + plot.height * i / divisions;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      _drawText(
        canvas,
        (maxY - maxY * i / divisions).toStringAsFixed(0),
        TextStyle(fontSize: dp(8), color: _inkDim, fontWeight: FontWeight.w600),
        Offset(plot.left - dp(4), y),
        dxFactor: -1,
      );
    }

    final left = plot.left + dp(8);
    final right = plot.right - dp(8);
    final step = values.length == 1
        ? 0.0
        : (right - left) / (values.length - 1);

    Offset pointAt(int i) {
      final x = values.length == 1 ? (left + right) / 2 : left + step * i;
      final ratio = (values[i] / maxY).clamp(0.0, 1.0);
      return Offset(x, plot.bottom - plot.height * ratio);
    }

    final full = Path();
    for (var i = 0; i < values.length; i++) {
      final p = pointAt(i);
      i == 0 ? full.moveTo(p.dx, p.dy) : full.lineTo(p.dx, p.dy);
    }

    final drawn = Path();
    for (final metric in full.computeMetrics()) {
      drawn.addPath(
        metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0)),
        Offset.zero,
      );
    }
    Offset? lastDrawn;
    for (final metric in drawn.computeMetrics()) {
      lastDrawn = metric.getTangentForOffset(metric.length)?.position;
    }
    if (lastDrawn != null) {
      final fill = Path()
        ..addPath(drawn, Offset.zero)
        ..lineTo(lastDrawn.dx, plot.bottom)
        ..lineTo(pointAt(0).dx, plot.bottom)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _violet.withValues(alpha: 0.28),
              _violet.withValues(alpha: 0.02),
            ],
          ).createShader(plot)
          ..style = PaintingStyle.fill,
      );
    }

    canvas.drawPath(
      drawn,
      Paint()
        ..color = _violet
        ..style = PaintingStyle.stroke
        ..strokeWidth = dp(1.8)
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final dotFill = Paint()..color = Colors.white;
    final dotStroke = Paint()
      ..color = _violet
      ..style = PaintingStyle.stroke
      ..strokeWidth = dp(1.4);

    final lastVisible = values.length <= 1
        ? 0
        : (progress * (values.length - 1)).floor();

    for (var i = 0; i < values.length; i++) {
      _drawText(
        canvas,
        labels[i],
        TextStyle(
          fontSize: dp(7.5),
          color: _inkDim,
          fontWeight: FontWeight.w600,
        ),
        Offset(pointAt(i).dx, plot.bottom + dp(5)),
        dyFactor: 0,
      );
      if (i > lastVisible) continue;
      final p = pointAt(i);
      canvas.drawCircle(p, dp(2.6), dotFill);
      canvas.drawCircle(p, dp(2.6), dotStroke);
      _drawText(
        canvas,
        values[i].toStringAsFixed(decimals),
        TextStyle(fontSize: dp(6.5), color: _blue, fontWeight: FontWeight.w700),
        Offset(p.dx, p.dy - dp(5)),
        dyFactor: -1,
      );
    }
  }

  /// Écrit [text] autour de [anchor] ; les facteurs positionnent la boîte de
  /// texte (-1 = alignée avant l'ancre, -0.5 = centrée, 0 = après l'ancre).
  void _drawText(
    Canvas canvas,
    String text,
    TextStyle style,
    Offset anchor, {
    double dxFactor = -0.5,
    double dyFactor = -0.5,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      anchor + Offset(painter.width * dxFactor, painter.height * dyFactor),
    );
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter old) =>
      old.maxY != maxY ||
      old.decimals != decimals ||
      old.progress != progress ||
      !listEquals(old.values, values) ||
      !listEquals(old.labels, labels);
}

// ---------------------------------------------------------------------------
// Animation des graphes + agrandissement AppPopup
// ---------------------------------------------------------------------------
class _ExpandBtn extends StatelessWidget {
  final double Function(double) dp;
  final VoidCallback onTap;

  const _ExpandBtn({required this.dp, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _violetSoft,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(dp(4)),
          child: Icon(Icons.open_in_full_rounded, size: dp(14), color: _violet),
        ),
      ),
    );
  }
}

class _AnimatedDonut extends StatefulWidget {
  final double size;
  final double stroke;
  final List<double> values;
  final List<Color> colors;
  final double centerSize;
  final double centerIconSize;

  const _AnimatedDonut({
    required this.size,
    required this.stroke,
    required this.values,
    required this.colors,
    required this.centerSize,
    required this.centerIconSize,
  });

  @override
  State<_AnimatedDonut> createState() => _AnimatedDonutState();
}

class _AnimatedDonutState extends State<_AnimatedDonut>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _progress = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeOutCubic,
  );

  @override
  void didUpdateWidget(covariant _AnimatedDonut oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.values, widget.values)) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(widget.size),
                painter: _DonutPainter(
                  values: widget.values,
                  colors: widget.colors,
                  stroke: widget.stroke,
                  progress: _progress.value,
                ),
              ),
              Container(
                width: widget.centerSize,
                height: widget.centerSize,
                decoration: const BoxDecoration(
                  color: _violet,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.groups_rounded,
                  size: widget.centerIconSize,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnimatedLineChart extends StatefulWidget {
  final List<double> values;
  final List<String> labels;
  final double maxY;
  final double Function(double) dp;
  final int decimals;

  const _AnimatedLineChart({
    required this.values,
    required this.labels,
    required this.maxY,
    required this.dp,
    required this.decimals,
  });

  @override
  State<_AnimatedLineChart> createState() => _AnimatedLineChartState();
}

class _AnimatedLineChartState extends State<_AnimatedLineChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final Animation<double> _progress = CurvedAnimation(
    parent: _ctrl,
    curve: Curves.easeInOutCubic,
  );

  @override
  void didUpdateWidget(covariant _AnimatedLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.values, widget.values) ||
        oldWidget.maxY != widget.maxY) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, _) {
        return CustomPaint(
          painter: _LineChartPainter(
            values: widget.values,
            labels: widget.labels,
            maxY: widget.maxY,
            divisions: 5,
            dp: widget.dp,
            decimals: widget.decimals,
            progress: _progress.value,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _DonutExpandBody extends StatelessWidget {
  final GoodaysStats stats;

  const _DonutExpandBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final parts = <(String, double, Color)>[
      ('Promoteur', stats.promoteursPct, _violet),
      ('Passifs', stats.passifsPct, const Color(0xFF4ADE80)),
      ('Détracteurs', stats.detracteursPct, _sky),
    ];
    double dp(double v) => v;

    return Column(
      children: [
        _AnimatedDonut(
          size: 180,
          stroke: 28,
          values: [for (final p in parts) p.$2],
          colors: [for (final p in parts) p.$3],
          centerSize: 64,
          centerIconSize: 32,
        ),
        const SizedBox(height: 18),
        for (final part in parts) ...[
          _LegendRow(dp: dp, color: part.$3, label: part.$1, percent: part.$2),
          if (part != parts.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _LineExpandBody extends StatelessWidget {
  final List<GoodaysScorePoint> points;
  final GoodaysMetric metric;
  final double maxY;

  const _LineExpandBody({
    required this.points,
    required this.metric,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    double dp(double v) => v;
    return SizedBox(
      height: 240,
      child: _AnimatedLineChart(
        values: [for (final p in points) p.valueFor(metric)],
        labels: [for (final p in points) p.label],
        maxY: maxY,
        dp: dp,
        decimals: metric == GoodaysMetric.clients ? 0 : 2,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Briques partagées
// ---------------------------------------------------------------------------
/// Carte blanche arrondie commune à tous les blocs de la page.
class _Card extends StatelessWidget {
  final double Function(double) dp;
  final EdgeInsets padding;
  final Widget child;

  const _Card({required this.dp, required this.padding, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(dp(16)),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.07),
            blurRadius: dp(16),
            offset: Offset(0, dp(6)),
            spreadRadius: dp(-4),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Cinq étoiles ambre — pleine, demie ou vide selon [value].
class _StarRow extends StatelessWidget {
  final double value;
  final double size;
  final double gap;

  const _StarRow({required this.value, required this.size, required this.gap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gap),
            child: Icon(
              value >= i + 1
                  ? Icons.star_rounded
                  : value > i + 0.25
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
              size: size,
              color: value > i + 0.25 ? _amber : _starEmpty,
            ),
          ),
      ],
    );
  }
}
