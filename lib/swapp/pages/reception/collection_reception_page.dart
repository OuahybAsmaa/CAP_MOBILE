// =============================================================================
// CapMobile — Module Swapp — Réception Collection (scan support)
// -----------------------------------------------------------------------------
// Fonctionnalité : Bons de livraison collection à réceptionner — supports
//                  attendus / restants par BL, scan d'un support, cumul global.
// Design         : Header navy (compteurs + scan) · tableau BL · Date · Total ·
//                  Restant · pied « Quantité totale » fixe aligné aux colonnes.
// UI             : Ouverte par la tuile « Collection » de ReceptionsMenuPage ;
//                  double tap sur une ligne → SupportsBlPage.
// Spécifications : Données [BlCollectionDemoData] ; API TODO.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/reception/data/bl_collection_test_data.dart';
import 'package:cap_mobile/swapp/models/bl_collection_item.dart';
import 'package:cap_mobile/swapp/pages/reception/supports_bl_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_attente_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Écran « Collection » — scan des supports par bon de livraison.
class CollectionReceptionPage extends StatefulWidget {
  const CollectionReceptionPage({super.key});

  static Route<void> fadeRoute() =>
      swappMenuFadeRoute(const CollectionReceptionPage());

  @override
  State<CollectionReceptionPage> createState() =>
      _CollectionReceptionPageState();
}

class _CollectionReceptionPageState extends State<CollectionReceptionPage> {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static const _greenBg = Color(0xFFDCFCE7);
  static const _greenInk = Color(0xFF15803D);

  late List<BlCollectionItem> _items;

  @override
  void initState() {
    super.initState();
    // TODO(API) : remplacer par SwappApiService.fetchBlsCollection()
    _items = BlCollectionDemoData.items()
      ..sort(BlCollectionItem.compareChronologique);
  }

  int get _totalSupports =>
      _items.fold<int>(0, (total, bl) => total + bl.total);

  int get _totalRestants =>
      _items.fold<int>(0, (total, bl) => total + bl.restant);

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _scanSupport() {
    HapticFeedback.selectionClick();
    // TODO(API) : scan DataWedge puis affectation du support au BL.
    _snack('Scan support — bientôt');
  }

  void _openBl(BlCollectionItem bl) {
    HapticFeedback.lightImpact();
    _snack('BL ${bl.numBl} · ${bl.restant} support(s) à scanner');
  }

  /// Double tap sur une ligne — supports attendus sur le BL.
  Future<void> _openSupports(BlCollectionItem bl) async {
    HapticFeedback.selectionClick();
    await Navigator.push(context, SupportsBlPage.fadeRoute(bl: bl));
  }

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.35);
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
              nbBls: _items.length,
              nbRestants: _totalRestants,
              onBack: () => Navigator.pop(context),
              onScan: _scanSupport,
            ),
            SwappAttenteSectionBar(dp: dp, title: 'BONS DE LIVRAISON'),
            Expanded(
              child: _items.isEmpty
                  ? SwappAttenteEmptyState(
                      dp: dp,
                      icon: Icons.inbox_rounded,
                      title: 'Aucun BL à réceptionner',
                      hint: 'Scannez un support pour démarrer une réception.',
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
                                  SwappTableColumn(label: 'BL'),
                                  SwappTableColumn(
                                    label: 'DATE',
                                    width: SwappTableLayout.date,
                                    align: TextAlign.center,
                                  ),
                                  SwappTableColumn(
                                    label: 'TOTAL',
                                    width: SwappTableLayout.total,
                                    align: TextAlign.right,
                                  ),
                                  SwappTableColumn(
                                    label: 'RESTANT',
                                    width: SwappTableLayout.restant,
                                    align: TextAlign.right,
                                  ),
                                ],
                              ),
                              for (var i = 0; i < _items.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: SwappMenuColors.ink.withValues(
                                      alpha: 0.06,
                                    ),
                                  ),
                                _BlRow(
                                  dp: dp,
                                  bl: _items[i],
                                  dateLabel: _dateFormat.format(_items[i].date),
                                  greenBg: _greenBg,
                                  greenInk: _greenInk,
                                  onTap: () => _openBl(_items[i]),
                                  onDoubleTap: () => _openSupports(_items[i]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            SwappTotalBar(
              dp: dp,
              bottomInset: insets.bottom,
              total: _totalSupports,
              restant: _totalRestants,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header navy — titre, compteurs et scan
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final double Function(double) dp;
  final double top;
  final int nbBls;
  final int nbRestants;
  final VoidCallback onBack;
  final VoidCallback onScan;

  const _Header({
    required this.dp,
    required this.top,
    required this.nbBls,
    required this.nbRestants,
    required this.onBack,
    required this.onScan,
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
                        'RÉCEPTION · COLLECTION',
                        style: TextStyle(
                          fontSize: dp(9.5),
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.55),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: dp(2)),
                      Text(
                        'Scan support',
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
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(dp(12)),
                  elevation: 3,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    onTap: onScan,
                    borderRadius: BorderRadius.circular(dp(12)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: dp(12),
                        vertical: dp(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            color: SwappAttenteColors.headerNavy,
                            size: dp(18),
                          ),
                          SizedBox(width: dp(6)),
                          Text(
                            'Scanner',
                            style: TextStyle(
                              fontSize: dp(12),
                              fontWeight: FontWeight.w900,
                              color: SwappAttenteColors.headerNavy,
                            ),
                          ),
                        ],
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
                    value: '$nbBls',
                    label: 'BONS DE LIVRAISON',
                  ),
                ),
                SizedBox(width: dp(12)),
                Expanded(
                  child: SwappAttenteStatCard(
                    dp: dp,
                    value: '$nbRestants',
                    label: 'SUPPORTS À SCANNER',
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
// Ligne du tableau
// ---------------------------------------------------------------------------
class _BlRow extends StatelessWidget {
  final double Function(double) dp;
  final BlCollectionItem bl;
  final String dateLabel;
  final Color greenBg;
  final Color greenInk;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const _BlRow({
    required this.dp,
    required this.bl,
    required this.dateLabel,
    required this.greenBg,
    required this.greenInk,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SwappMenuColors.panel,
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(12)),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: dp(16),
                      color: SwappMenuColors.p1,
                    ),
                    SizedBox(width: dp(8)),
                    Expanded(
                      child: Text(
                        bl.numBl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
              SizedBox(
                width: dp(SwappTableLayout.date),
                child: Text(
                  dateLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: dp(12),
                    fontWeight: FontWeight.w600,
                    color: SwappMenuColors.inkDim,
                  ),
                ),
              ),
              SizedBox(
                width: dp(SwappTableLayout.total),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SwappCountPill(
                    dp: dp,
                    value: bl.total,
                    bg: const Color(0xFFF1F5F9),
                    fg: SwappMenuColors.inkDim,
                  ),
                ),
              ),
              SizedBox(
                width: dp(SwappTableLayout.restant),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SwappCountPill(
                    dp: dp,
                    value: bl.restant,
                    bg: bl.termine ? greenBg : SwappMenuColors.p5Bg,
                    fg: bl.termine ? greenInk : SwappMenuColors.p5,
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
