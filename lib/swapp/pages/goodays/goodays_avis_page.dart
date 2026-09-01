// =============================================================================
// CapMobile — Module Swapp — Avis clients Goodays
// -----------------------------------------------------------------------------
// Fonctionnalité : Liste des avis clients — filtres répondus / date, cartes NPS,
//                  navigation depuis le bouton chat de MyGoodaysPage.
// Design         : Header navy SwappAttenteColors ; fond lavande ; accent violet ;
//                  barre du bas Répondus / Nouveau / Statistiques / Paramètres.
// UI             : Ouverte par l'icône chat du header My Goodays.
// Spécifications : Données GoodaysAvisDemoData — branchement API dans _loadAvis().
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/core/widgets/app_popup.dart';
import 'package:cap_mobile/swapp/models/goodays/goodays.dart';
import 'package:cap_mobile/core/apiswap/goodays/data/goodays_avis_test_data.dart';
import 'package:cap_mobile/swapp/pages/goodays/goodays_reponse_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_attente_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

// --- Palette locale (alignée My Goodays) ------------------------------------
const _violet = AppColors.primary;
const _violetDark = AppColors.primaryDark;
const _violetSoft = AppColors.primarySoft;
const _green = Color(0xFF22C55E);
const _greenSoft = Color(0xFFDCFCE7);
const _red = Color(0xFFEF4444);
const _redSoft = Color(0xFFFCE7E7);
const _ink = SwappMenuColors.ink;
const _inkDim = SwappMenuColors.inkDim;
const _cardBorder = Color(0xFFE8EAF3);

/// Écran liste des avis clients Goodays.
class GoodaysAvisPage extends StatefulWidget {
  const GoodaysAvisPage({super.key});

  static Route<void> fadeRoute() => swappMenuFadeRoute(const GoodaysAvisPage());

  @override
  State<GoodaysAvisPage> createState() => _GoodaysAvisPageState();
}

class _GoodaysAvisPageState extends State<GoodaysAvisPage> {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm:ss');

  bool _showRepondus = false;
  DateTime _since = DateTime(2026, 8, 17);
  late final List<GoodaysAvis> _all = _loadAvis();

  /// Point de branchement unique de l'API.
  ///
  /// TODO(API) : remplacer par `SwappApiService.fetchGoodaysAvis(since)`.
  List<GoodaysAvis> _loadAvis() => GoodaysAvisDemoData.all();

  List<GoodaysAvis> get _filtered {
    return [
      for (final avis in _all)
        if (avis.repondu == _showRepondus && !avis.date.isBefore(_since)) avis,
    ]..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _pickSinceDate(double Function(double) dp) async {
    HapticFeedback.selectionClick();
    final picked = await showDatePicker(
      context: context,
      initialDate: _since,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('fr', 'FR'),
      helpText: 'Afficher les avis depuis',
      cancelText: 'Annuler',
      confirmText: 'OK',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: _violet,
            brightness: Brightness.light,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _since = picked);
  }

  void _openAvisMenu(GoodaysAvis avis) {
    HapticFeedback.lightImpact();
    AppPopup.show<void>(
      context: context,
      title: avis.nomComplet,
      body: Text(
        avis.commentaire,
        style: const TextStyle(fontSize: 14, height: 1.45, color: _ink),
      ),
      actions: [
        AppPopupAction(label: 'Répondre', onTap: () => _openReply(avis)),
        const AppPopupAction(label: 'Fermer'),
      ],
    );
  }

  void _openReply(GoodaysAvis avis) {
    HapticFeedback.lightImpact();
    Navigator.push(context, GoodaysReponsePage.fadeRoute(avis));
  }

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 390).clamp(0.85, 1.25);
    double dp(double v) => v * scale;
    final insets = MediaQuery.paddingOf(context);
    final avis = _filtered;
    final promoters = avis.where((item) => item.isPromoteur).length;

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
              onStats: () => Navigator.pop(context),
            ),
            _InsightsBanner(
              dp: dp,
              total: avis.length,
              promoters: promoters,
              answered: _showRepondus,
            ),
            _FilterBar(
              dp: dp,
              showRepondus: _showRepondus,
              sinceLabel: 'Depuis ${_dateFormat.format(_since)}',
              onToggleRepondus: (v) {
                HapticFeedback.selectionClick();
                setState(() => _showRepondus = v);
              },
              onPickDate: () => _pickSinceDate(dp),
            ),
            Expanded(
              child: avis.isEmpty
                  ? _EmptyState(dp: dp, repondus: _showRepondus)
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        dp(12),
                        dp(10),
                        dp(12),
                        dp(32) + insets.bottom,
                      ),
                      itemCount: avis.length,
                      separatorBuilder: (_, _) => SizedBox(height: dp(10)),
                      itemBuilder: (_, i) => _AvisCard(
                        dp: dp,
                        avis: avis[i],
                        dateTimeFormat: _dateTimeFormat,
                        onMenu: () => _openAvisMenu(avis[i]),
                        onReply: () => _openReply(avis[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header navy
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final double Function(double) dp;
  final double top;
  final VoidCallback onBack;
  final VoidCallback onStats;

  const _Header({
    required this.dp,
    required this.top,
    required this.onBack,
    required this.onStats,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SwappAttenteColors.headerNavy,
      child: Padding(
        padding: EdgeInsets.fromLTRB(dp(14), top + dp(8), dp(14), dp(20)),
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
                    'Avis clients',
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
              icon: Icons.bar_chart_rounded,
              onTap: onStats,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Résumé de la sélection
// ---------------------------------------------------------------------------
class _InsightsBanner extends StatelessWidget {
  final double Function(double) dp;
  final int total;
  final int promoters;
  final bool answered;

  const _InsightsBanner({
    required this.dp,
    required this.total,
    required this.promoters,
    required this.answered,
  });

  @override
  Widget build(BuildContext context) {
    final rate = total == 0 ? 0 : ((promoters / total) * 100).round();

    return Container(
      margin: EdgeInsets.fromLTRB(dp(12), dp(12), dp(12), dp(2)),
      padding: EdgeInsets.all(dp(16)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_violetDark, _violet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(dp(20)),
        boxShadow: [
          BoxShadow(
            color: _violet.withValues(alpha: 0.25),
            blurRadius: dp(20),
            offset: Offset(0, dp(8)),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  answered ? 'AVIS TRAITÉS' : 'À TRAITER',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: dp(9),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.15,
                  ),
                ),
                SizedBox(height: dp(5)),
                Text(
                  '$total retour${total > 1 ? 's' : ''} client',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: dp(19),
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                SizedBox(height: dp(5)),
                Text(
                  total == 0
                      ? 'Aucun avis sur cette période'
                      : '$promoters promoteur${promoters > 1 ? 's' : ''} dans la sélection',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.76),
                    fontSize: dp(10.5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: dp(58),
            height: dp(58),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$rate%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: dp(15),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'positifs',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: dp(7.5),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Barre filtres — toggle répondus + date
// ---------------------------------------------------------------------------
class _FilterBar extends StatelessWidget {
  final double Function(double) dp;
  final bool showRepondus;
  final String sinceLabel;
  final ValueChanged<bool> onToggleRepondus;
  final VoidCallback onPickDate;

  const _FilterBar({
    required this.dp,
    required this.showRepondus,
    required this.sinceLabel,
    required this.onToggleRepondus,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(dp(12), dp(10), dp(12), dp(4)),
      padding: EdgeInsets.all(dp(5)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(dp(16)),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.06),
            blurRadius: dp(12),
            offset: Offset(0, dp(4)),
            spreadRadius: dp(-4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _FilterChoice(
              dp: dp,
              icon: showRepondus
                  ? Icons.done_all_rounded
                  : Icons.pending_actions_rounded,
              label: showRepondus ? 'Répondus' : 'En attente',
              color: _violet,
              background: _violetSoft,
              onTap: () => onToggleRepondus(!showRepondus),
            ),
          ),
          SizedBox(width: dp(5)),
          Expanded(
            child: _FilterChoice(
              dp: dp,
              icon: Icons.calendar_month_rounded,
              label: sinceLabel,
              color: _inkDim,
              background: const Color(0xFFF5F6FA),
              onTap: onPickDate,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChoice extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _FilterChoice({
    required this.dp,
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(dp(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(12)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dp(10), vertical: dp(10)),
          child: Row(
            children: [
              Icon(icon, size: dp(16), color: color),
              SizedBox(width: dp(7)),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: dp(10.5),
                    fontWeight: FontWeight.w700,
                    color: color,
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
// Carte avis
// ---------------------------------------------------------------------------
class _AvisCard extends StatelessWidget {
  final double Function(double) dp;
  final GoodaysAvis avis;
  final DateFormat dateTimeFormat;
  final VoidCallback onMenu;
  final VoidCallback onReply;

  const _AvisCard({
    required this.dp,
    required this.avis,
    required this.dateTimeFormat,
    required this.onMenu,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    final accent = avis.isPromoteur ? _green : _red;
    final accentSoft = avis.isPromoteur ? _greenSoft : _redSoft;
    final avatarBg = avis.isPromoteur
        ? const Color(0xFF166534)
        : const Color(0xFF991B1B);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(dp(14)),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.05),
            blurRadius: dp(12),
            offset: Offset(0, dp(4)),
            spreadRadius: dp(-4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: dp(5), color: accent),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(dp(10), dp(12), dp(10), dp(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: dp(18),
                          backgroundColor: avatarBg,
                          child: Text(
                            avis.initiales,
                            style: TextStyle(
                              fontSize: dp(12),
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: dp(10)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                avis.nomComplet,
                                style: TextStyle(
                                  fontSize: dp(13),
                                  fontWeight: FontWeight.w800,
                                  color: _ink,
                                ),
                              ),
                              SizedBox(height: dp(4)),
                              Row(
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    size: dp(12),
                                    color: _inkDim,
                                  ),
                                  SizedBox(width: dp(4)),
                                  Text(
                                    avis.canal,
                                    style: TextStyle(
                                      fontSize: dp(10),
                                      fontWeight: FontWeight.w600,
                                      color: _inkDim,
                                    ),
                                  ),
                                  SizedBox(width: dp(8)),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: dp(8),
                                      vertical: dp(3),
                                    ),
                                    decoration: BoxDecoration(
                                      color: accentSoft,
                                      borderRadius: BorderRadius.circular(
                                        dp(20),
                                      ),
                                    ),
                                    child: Text(
                                      'NPS : ${avis.nps}/10',
                                      style: TextStyle(
                                        fontSize: dp(9.5),
                                        fontWeight: FontWeight.w800,
                                        color: accent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(
                            minWidth: dp(28),
                            minHeight: dp(28),
                          ),
                          onPressed: onMenu,
                          icon: Icon(
                            Icons.more_vert_rounded,
                            size: dp(20),
                            color: _inkDim,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: dp(6)),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: dp(12),
                          color: _inkDim,
                        ),
                        SizedBox(width: dp(4)),
                        Expanded(
                          child: Text(
                            dateTimeFormat.format(avis.date),
                            style: TextStyle(
                              fontSize: dp(9.5),
                              fontWeight: FontWeight.w600,
                              color: _inkDim,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: dp(10)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: dp(32),
                          height: dp(32),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(
                              avis.categorie == GoodaysAvisCategorie.positif
                                  ? dp(16)
                                  : dp(6),
                            ),
                          ),
                          child: Icon(
                            avis.categorie.icon,
                            size: dp(18),
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: dp(8)),
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: dp(10),
                              vertical: dp(10),
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F8),
                              borderRadius: BorderRadius.circular(dp(12)),
                            ),
                            child: Text(
                              avis.commentaire,
                              style: TextStyle(
                                fontSize: dp(11),
                                fontWeight: FontWeight.w500,
                                color: _ink,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: dp(6)),
                        Material(
                          color: const Color(0xFFFFF7D6),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onReply,
                            child: Padding(
                              padding: EdgeInsets.all(dp(8)),
                              child: Icon(
                                Icons.reply_rounded,
                                size: dp(20),
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// États vides / placeholder onglets
// ---------------------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final double Function(double) dp;
  final bool repondus;

  const _EmptyState({required this.dp, required this.repondus});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(dp(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_rounded,
              size: dp(48),
              color: _inkDim.withValues(alpha: 0.5),
            ),
            SizedBox(height: dp(12)),
            Text(
              repondus ? 'Aucun avis répondu' : 'Aucun avis en attente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: dp(14),
                fontWeight: FontWeight.w700,
                color: _inkDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
