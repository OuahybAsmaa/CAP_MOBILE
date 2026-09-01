// =============================================================================
// CapMobile — Module Swapp — Colis non validés
// -----------------------------------------------------------------------------
// Fonctionnalité : Colis réceptionnés en attente de validation — bascule
//                  Livraisons / Transferts, quantités cumulées, validation.
// Design         : Header navy (compteurs + onglets segmentés) · tableau
//                  Expéditeur · Colis · Qté · pied de cumul fixe.
// UI             : Ouverte par la tuile « Colis non validés » de
//                  ReceptionsMenuPage ; appui long sur une ligne = valider.
// Spécifications : Données [ColisNonValideDemoData] ; API TODO.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/reception/data/colis_non_valide_test_data.dart';
import 'package:cap_mobile/core/widgets/app_popup.dart';
import 'package:cap_mobile/swapp/models/colis_non_valide_item.dart';
import 'package:cap_mobile/swapp/widgets/swapp_attente_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Écran « Colis non validés » — consultation et validation des colis reçus.
class ColisNonValidesPage extends StatefulWidget {
  const ColisNonValidesPage({super.key});

  static Route<void> fadeRoute() =>
      swappMenuFadeRoute(const ColisNonValidesPage());

  @override
  State<ColisNonValidesPage> createState() => _ColisNonValidesPageState();
}

class _ColisNonValidesPageState extends State<ColisNonValidesPage> {
  /// Quantités affichées comme dans l'ERP : « 1,0 » / « 30,0 ».
  static final _qte = NumberFormat('#,##0.0', 'fr_FR');

  // TODO(API) : remplacer par SwappApiService.fetchColisNonValides()
  late List<ColisNonValideItem> _items;
  ColisNonValideFlux _flux = ColisNonValideFlux.livraison;

  @override
  void initState() {
    super.initState();
    _items = ColisNonValideDemoData.items();
  }

  List<ColisNonValideItem> get _visible =>
      _items.where((colis) => colis.flux == _flux).toList();

  int _countOf(ColisNonValideFlux flux) =>
      _items.where((colis) => colis.flux == flux).length;

  double get _totalQuantite =>
      _visible.fold<double>(0, (total, colis) => total + colis.quantite);

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _selectFlux(ColisNonValideFlux flux) {
    if (flux == _flux) return;
    HapticFeedback.selectionClick();
    setState(() => _flux = flux);
  }

  Future<void> _validerColis(ColisNonValideItem colis) async {
    HapticFeedback.mediumImpact();
    final confirmed = await AppPopup.confirm(
      context,
      icon: Icons.inventory_2_rounded,
      title: 'Valider le colis ?',
      message:
          '${colis.numColis}\n'
          '${colis.expediteur} · ${_qte.format(colis.quantite)} article(s)',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _items.removeWhere((item) => item.id == colis.id));
    _snack('Colis ${colis.numColis} validé (mode démo)');
  }

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.35);
    double dp(double v) => v * scale;
    final insets = MediaQuery.paddingOf(context);
    final visible = _visible;

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
              nbColis: visible.length,
              totalQuantite: _qte.format(_totalQuantite),
              nbLivraisons: _countOf(ColisNonValideFlux.livraison),
              nbTransferts: _countOf(ColisNonValideFlux.transfert),
              flux: _flux,
              onBack: () => Navigator.pop(context),
              onSelectFlux: _selectFlux,
            ),
            SwappAttenteSectionBar(
              dp: dp,
              title: 'COLIS EN ATTENTE DE VALIDATION',
            ),
            Expanded(
              child: visible.isEmpty
                  ? SwappAttenteEmptyState(
                      dp: dp,
                      icon: Icons.inventory_2_outlined,
                      title: 'Aucun colis à valider',
                      hint: _flux == ColisNonValideFlux.livraison
                          ? 'Les colis de livraison validés disparaissent d\u2019ici.'
                          : 'Aucun colis de transfert en attente.',
                    )
                  : ListView(
                      padding: EdgeInsets.fromLTRB(dp(14), 0, dp(14), dp(16)),
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: SwappMenuColors.panel,
                            borderRadius: BorderRadius.circular(dp(16)),
                            boxShadow: [
                              BoxShadow(
                                color: SwappMenuColors.ink.withValues(
                                  alpha: 0.07,
                                ),
                                blurRadius: dp(14),
                                offset: Offset(0, dp(5)),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              SwappTableHeader(
                                dp: dp,
                                columns: const [
                                  SwappTableColumn(label: 'EXPÉDITEUR · COLIS'),
                                  SwappTableColumn(
                                    label: 'QTÉ',
                                    width: SwappTableLayout.total,
                                    align: TextAlign.right,
                                  ),
                                ],
                              ),
                              for (var i = 0; i < visible.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: SwappMenuColors.ink.withValues(
                                      alpha: 0.06,
                                    ),
                                  ),
                                _ColisRow(
                                  dp: dp,
                                  colis: visible[i],
                                  quantiteLabel: _qte.format(
                                    visible[i].quantite,
                                  ),
                                  onTap: () => _snack(
                                    '${visible[i].numColis} · '
                                    '${visible[i].expediteur}',
                                  ),
                                  onLongPress: () => _validerColis(visible[i]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            _CumulBar(
              dp: dp,
              bottomInset: insets.bottom,
              nbColis: visible.length,
              totalQuantite: _qte.format(_totalQuantite),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header navy — compteurs et onglets de flux
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final double Function(double) dp;
  final double top;
  final int nbColis;
  final String totalQuantite;
  final int nbLivraisons;
  final int nbTransferts;
  final ColisNonValideFlux flux;
  final VoidCallback onBack;
  final ValueChanged<ColisNonValideFlux> onSelectFlux;

  const _Header({
    required this.dp,
    required this.top,
    required this.nbColis,
    required this.totalQuantite,
    required this.nbLivraisons,
    required this.nbTransferts,
    required this.flux,
    required this.onBack,
    required this.onSelectFlux,
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
                        'RÉCEPTION',
                        style: TextStyle(
                          fontSize: dp(9.5),
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.55),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: dp(2)),
                      Text(
                        'Colis non validés',
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
              ],
            ),
            SizedBox(height: dp(14)),
            Row(
              children: [
                Expanded(
                  child: SwappAttenteStatCard(
                    dp: dp,
                    value: '$nbColis',
                    label: 'COLIS À VALIDER',
                  ),
                ),
                SizedBox(width: dp(12)),
                Expanded(
                  child: SwappAttenteStatCard(
                    dp: dp,
                    value: totalQuantite,
                    label: 'QUANTITÉ CUMULÉE',
                  ),
                ),
              ],
            ),
            SizedBox(height: dp(14)),
            SwappSegmentedTabs(
              dp: dp,
              segments: [
                SwappSegment(
                  label: 'Livraisons',
                  icon: Icons.local_shipping_rounded,
                  count: nbLivraisons,
                ),
                SwappSegment(
                  label: 'Transferts',
                  icon: Icons.compare_arrows_rounded,
                  count: nbTransferts,
                ),
              ],
              selectedIndex: flux.index,
              onSelect: (index) =>
                  onSelectFlux(ColisNonValideFlux.values[index]),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ligne du tableau
// ---------------------------------------------------------------------------
class _ColisRow extends StatelessWidget {
  final double Function(double) dp;
  final ColisNonValideItem colis;
  final String quantiteLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ColisRow({
    required this.dp,
    required this.colis,
    required this.quantiteLabel,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final transfert = colis.flux == ColisNonValideFlux.transfert;

    return Material(
      color: SwappMenuColors.panel,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(11)),
          child: Row(
            children: [
              Container(
                width: dp(34),
                height: dp(34),
                decoration: BoxDecoration(
                  color: transfert
                      ? SwappMenuColors.p4Bg
                      : SwappMenuColors.p3Bg,
                  borderRadius: BorderRadius.circular(dp(10)),
                ),
                child: Icon(
                  transfert
                      ? Icons.compare_arrows_rounded
                      : Icons.warehouse_rounded,
                  size: dp(18),
                  color: transfert ? SwappMenuColors.p4 : SwappMenuColors.p3,
                ),
              ),
              SizedBox(width: dp(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      colis.expediteur,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dp(12.5),
                        fontWeight: FontWeight.w800,
                        color: SwappMenuColors.ink,
                      ),
                    ),
                    SizedBox(height: dp(2)),
                    Text(
                      colis.numColis,
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
              SizedBox(
                width: dp(SwappTableLayout.total),
                child: Text(
                  quantiteLabel,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: dp(13),
                    fontWeight: FontWeight.w900,
                    color: SwappMenuColors.ink,
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

/// Pied fixe — cumul des colis et des quantités de l'onglet actif.
class _CumulBar extends StatelessWidget {
  final double Function(double) dp;
  final double bottomInset;
  final int nbColis;
  final String totalQuantite;

  const _CumulBar({
    required this.dp,
    required this.bottomInset,
    required this.nbColis,
    required this.totalQuantite,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SwappMenuColors.ink,
        boxShadow: [
          BoxShadow(
            color: SwappMenuColors.ink.withValues(alpha: 0.28),
            blurRadius: dp(16),
            offset: Offset(0, dp(-4)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          dp(SwappTableLayout.gutter),
          dp(14),
          dp(SwappTableLayout.gutter),
          dp(14) + bottomInset,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$nbColis colis',
                style: TextStyle(
                  fontSize: dp(13),
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            Text(
              'Quantité totale ',
              style: TextStyle(
                fontSize: dp(12),
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            Text(
              totalQuantite,
              style: TextStyle(
                fontSize: dp(15),
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
