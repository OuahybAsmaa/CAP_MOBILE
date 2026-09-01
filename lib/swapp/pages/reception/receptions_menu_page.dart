// =============================================================================
// CapMobile — Module Swapp — Mes réceptions (hub livraisons)
// -----------------------------------------------------------------------------
// Fonctionnalité : Hub des réceptions magasin — collection, réassort, transferts
//                  entrants, colis non validés, réception sans ADR, réserve.
// Design         : Header navy (compteurs colis + scan) · liste de tuiles
//                  pleine largeur avec pastille icône pastel, badge et chevron.
// UI             : Ouverte par la tuile « Réceptions » de SwappMenuPage ;
//                  « Collection » → CollectionReceptionPage ; « Réassort » →
//                  ReceptionReassortPage ; « Colis non validés » →
//                  ColisNonValidesPage ; les autres tuiles restent à brancher.
// Spécifications : Compteurs démo (_colisAttendus / _colisNonValides) ; API TODO.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/reception/data/colis_non_valide_test_data.dart';
import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/swapp/pages/reception/collection_reception_page.dart';
import 'package:cap_mobile/swapp/pages/reception/colis_non_valides_page.dart';
import 'package:cap_mobile/swapp/pages/reception/reception_reassort_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_attente_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Écran « Mes réceptions » — point d'entrée des livraisons magasin.
class ReceptionsMenuPage extends StatelessWidget {
  const ReceptionsMenuPage({super.key});

  static Route<void> fadeRoute() =>
      swappMenuFadeRoute(const ReceptionsMenuPage());

  // TODO(API) : remplacer par SwappApiService.fetchReceptionsResume()
  static const _colisAttendus = 12;

  /// Même source que ColisNonValidesPage pour éviter deux compteurs divergents.
  static int get _colisNonValides => ColisNonValideDemoData.items().length;

  void _snack(BuildContext context, String message) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  List<_ReceptionTile> _tiles(BuildContext context) {
    void soon(String label) => _snack(context, '$label — bientôt');

    return [
      _ReceptionTile(
        title: 'Collection',
        subtitle: 'Livraison de la nouvelle collection',
        icon: Icons.collections_bookmark_rounded,
        color: SwappMenuColors.p1,
        bg: SwappMenuColors.p1Bg,
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(context, CollectionReceptionPage.fadeRoute());
        },
      ),
      _ReceptionTile(
        title: 'Réception du Réassort',
        subtitle: 'Colis de réapprovisionnement',
        icon: Icons.move_to_inbox_rounded,
        color: SwappMenuColors.p3,
        bg: SwappMenuColors.p3Bg,
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(context, ReceptionReassortPage.fadeRoute());
        },
      ),
      _ReceptionTile(
        title: 'Transferts',
        subtitle: 'Colis reçus d\u2019un autre magasin',
        icon: Icons.compare_arrows_rounded,
        color: SwappMenuColors.p4,
        bg: SwappMenuColors.p4Bg,
        onTap: () => soon('Réception des transferts'),
      ),
      _ReceptionTile(
        title: 'Colis non validés',
        subtitle: 'Réceptions à terminer',
        icon: Icons.inventory_2_rounded,
        color: SwappMenuColors.p5,
        bg: SwappMenuColors.p5Bg,
        badge: '$_colisNonValides',
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(context, ColisNonValidesPage.fadeRoute());
        },
      ),
      _ReceptionTile(
        title: 'Réception Sans ADR',
        subtitle: 'Colis sans avis de réception',
        icon: Icons.assignment_late_outlined,
        color: SwappMenuColors.p6,
        bg: SwappMenuColors.p6Bg,
        onTap: () => soon('Réception Sans ADR'),
      ),
      _ReceptionTile(
        title: 'Déclarer une réserve',
        subtitle: 'Litige, manquant ou colis abîmé',
        icon: Icons.flag_rounded,
        color: AppColors.error,
        bg: const Color(0xFFFDE7EA),
        onTap: () => soon('Déclarer une réserve'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.35);
    double dp(double v) => v * scale;
    final insets = MediaQuery.paddingOf(context);
    final tiles = _tiles(context);

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
              onScan: () => _snack(context, 'Scan colis — bientôt'),
              onHistorique: () => _snack(context, 'Historique — bientôt'),
            ),
            SwappAttenteSectionBar(dp: dp, title: 'TOUTES LES RÉCEPTIONS'),
            Expanded(
              child: ListView.separated(
                // Marge basse = barre de navigation Android incluse.
                padding: EdgeInsets.fromLTRB(
                  dp(14),
                  0,
                  dp(14),
                  dp(24) + insets.bottom,
                ),
                itemCount: tiles.length,
                separatorBuilder: (_, _) => SizedBox(height: dp(12)),
                itemBuilder: (context, index) =>
                    _ReceptionCard(dp: dp, tile: tiles[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header navy — titre, compteurs colis et actions
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final double Function(double) dp;
  final double top;
  final VoidCallback onBack;
  final VoidCallback onScan;
  final VoidCallback onHistorique;

  const _Header({
    required this.dp,
    required this.top,
    required this.onBack,
    required this.onScan,
    required this.onHistorique,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SwappAttenteColors.headerNavy,
      child: Padding(
        padding: EdgeInsets.fromLTRB(dp(14), top + dp(8), dp(14), dp(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
                        'LIVRAISONS',
                        style: TextStyle(
                          fontSize: dp(9.5),
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.55),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: dp(2)),
                      Text(
                        'Mes réceptions',
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
                SizedBox(width: dp(8)),
                SwappAttenteNavSquare(
                  dp: dp,
                  icon: Icons.history_rounded,
                  onTap: onHistorique,
                ),
                SizedBox(width: dp(10)),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(dp(12)),
                  elevation: 3,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    onTap: onScan,
                    borderRadius: BorderRadius.circular(dp(12)),
                    child: SizedBox(
                      width: dp(40),
                      height: dp(40),
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: SwappAttenteColors.headerNavy,
                        size: dp(22),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: dp(14)),
            Row(
              children: [
                Expanded(
                  child: SwappAttenteStatCard(
                    dp: dp,
                    value: '${ReceptionsMenuPage._colisAttendus}',
                    label: 'COLIS ATTENDUS',
                  ),
                ),
                SizedBox(width: dp(12)),
                Expanded(
                  child: SwappAttenteStatCard(
                    dp: dp,
                    value: '${ReceptionsMenuPage._colisNonValides}',
                    label: 'COLIS NON VALIDÉS',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tuile d'action
// ---------------------------------------------------------------------------
class _ReceptionTile {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bg;

  /// Compteur affiché en pastille (ex. colis restants).
  final String? badge;

  final VoidCallback onTap;

  const _ReceptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
    this.badge,
  });
}

class _ReceptionCard extends StatelessWidget {
  final double Function(double) dp;
  final _ReceptionTile tile;

  const _ReceptionCard({required this.dp, required this.tile});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(dp(18));

    return Material(
      color: SwappMenuColors.panel,
      borderRadius: radius,
      child: InkWell(
        onTap: tile.onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: SwappMenuColors.panel,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: SwappMenuColors.ink.withValues(alpha: 0.07),
                blurRadius: dp(14),
                offset: Offset(0, dp(5)),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(dp(12)),
            child: Row(
              children: [
                // Pastille icône : dégradé pastel pour donner du relief.
                Container(
                  width: dp(50),
                  height: dp(50),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [tile.bg, tile.color.withValues(alpha: 0.22)],
                    ),
                    borderRadius: BorderRadius.circular(dp(15)),
                  ),
                  child: Icon(tile.icon, color: tile.color, size: dp(26)),
                ),
                SizedBox(width: dp(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tile.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: dp(14.5),
                          fontWeight: FontWeight.w900,
                          color: SwappMenuColors.ink,
                          letterSpacing: -0.2,
                        ),
                      ),
                      SizedBox(height: dp(3)),
                      Text(
                        tile.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: dp(11.5),
                          fontWeight: FontWeight.w600,
                          color: SwappMenuColors.inkDim,
                        ),
                      ),
                    ],
                  ),
                ),
                if (tile.badge != null) ...[
                  SizedBox(width: dp(8)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: dp(9),
                      vertical: dp(4),
                    ),
                    decoration: BoxDecoration(
                      color: tile.color,
                      borderRadius: BorderRadius.circular(dp(20)),
                    ),
                    child: Text(
                      tile.badge!,
                      style: TextStyle(
                        fontSize: dp(11.5),
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                SizedBox(width: dp(8)),
                Container(
                  width: dp(28),
                  height: dp(28),
                  decoration: BoxDecoration(
                    color: tile.bg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: tile.color,
                    size: dp(15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
