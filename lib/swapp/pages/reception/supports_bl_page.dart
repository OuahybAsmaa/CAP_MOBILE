// =============================================================================
// CapMobile — Module Swapp — Supports d'un BL collection
// -----------------------------------------------------------------------------
// Fonctionnalité : Supports attendus sur un bon de livraison — colis annoncés /
//                  restants, bascule « Réception au colis », scan d'un support.
// Design         : Header navy (compteurs + scan) · bascule teal · tableau
//                  Support · Total · Restant, ligne courante teal pleine ·
//                  pied « Quantité totale » fixe.
// UI             : Ouverte au double tap sur une ligne de CollectionReceptionPage.
// Spécifications : Données [SupportCollectionDemoData] ; API TODO.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/reception/data/support_collection_test_data.dart';
import 'package:cap_mobile/swapp/models/bl_collection_item.dart';
import 'package:cap_mobile/swapp/models/support_collection_item.dart';
import 'package:cap_mobile/swapp/widgets/swapp_attente_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Écran des supports d'un bon de livraison collection.
class SupportsBlPage extends StatefulWidget {
  final BlCollectionItem bl;

  const SupportsBlPage({super.key, required this.bl});

  static Route<void> fadeRoute({required BlCollectionItem bl}) =>
      swappMenuFadeRoute(SupportsBlPage(bl: bl));

  @override
  State<SupportsBlPage> createState() => _SupportsBlPageState();
}

class _SupportsBlPageState extends State<SupportsBlPage> {
  static const _teal = Color(0xFF0D9488);
  static const _tealBg = Color(0xFFD9F1EF);
  static const _greenBg = Color(0xFFDCFCE7);
  static const _greenInk = Color(0xFF15803D);

  late List<SupportCollectionItem> _items;

  /// Réception colis par colis au lieu du support entier.
  bool _receptionAuColis = false;

  /// Support courant — dernier scanné (démo : premier support incomplet).
  String? _currentId;

  @override
  void initState() {
    super.initState();
    // TODO(API) : remplacer par SwappApiService.fetchSupportsBl(numBl)
    _items = SupportCollectionDemoData.forBl(widget.bl);
    final aTraiter = _items.where((support) => !support.termine).toList();
    _currentId = aTraiter.isEmpty ? null : aTraiter.first.id;
  }

  int get _totalColis =>
      _items.fold<int>(0, (total, support) => total + support.total);

  int get _totalRestants =>
      _items.fold<int>(0, (total, support) => total + support.restant);

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _toggleReceptionAuColis(bool value) {
    HapticFeedback.selectionClick();
    setState(() => _receptionAuColis = value);
    _snack(
      value
          ? 'Réception au colis activée — scannez chaque colis'
          : 'Réception au support — scannez le support complet',
    );
  }

  void _scan() {
    HapticFeedback.selectionClick();
    // TODO(API) : scan DataWedge puis décrément du restant du support.
    _snack(
      _receptionAuColis ? 'Scan colis — bientôt' : 'Scan support — bientôt',
    );
  }

  void _selectSupport(SupportCollectionItem support) {
    HapticFeedback.selectionClick();
    setState(() => _currentId = support.id);
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
              numBl: widget.bl.numBl,
              nbSupports: _items.length,
              nbRestants: _totalRestants,
              onBack: () => Navigator.pop(context),
              onScan: _scan,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(dp(14), dp(14), dp(14), dp(2)),
              child: _ReceptionAuColisCard(
                dp: dp,
                value: _receptionAuColis,
                teal: _teal,
                tealBg: _tealBg,
                onChanged: _toggleReceptionAuColis,
              ),
            ),
            SwappAttenteSectionBar(dp: dp, title: 'SUPPORTS DU BON'),
            Expanded(
              child: _items.isEmpty
                  ? SwappAttenteEmptyState(
                      dp: dp,
                      icon: Icons.local_shipping_outlined,
                      title: 'Aucun support attendu',
                      hint: 'Scannez un support pour l\u2019ajouter au bon.',
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
                                  SwappTableColumn(label: 'SUPPORT'),
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
                                _SupportRow(
                                  dp: dp,
                                  support: _items[i],
                                  current: _items[i].id == _currentId,
                                  teal: _teal,
                                  greenBg: _greenBg,
                                  greenInk: _greenInk,
                                  onTap: () => _selectSupport(_items[i]),
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
              total: _totalColis,
              restant: _totalRestants,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header navy — BL, compteurs et scan
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final double Function(double) dp;
  final double top;
  final String numBl;
  final int nbSupports;
  final int nbRestants;
  final VoidCallback onBack;
  final VoidCallback onScan;

  const _Header({
    required this.dp,
    required this.top,
    required this.numBl,
    required this.nbSupports,
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
                        'BON DE LIVRAISON',
                        style: TextStyle(
                          fontSize: dp(9.5),
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.55),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: dp(2)),
                      Text(
                        numBl,
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
                    value: '$nbSupports',
                    label: 'SUPPORTS ATTENDUS',
                  ),
                ),
                SizedBox(width: dp(12)),
                Expanded(
                  child: SwappAttenteStatCard(
                    dp: dp,
                    value: '$nbRestants',
                    label: 'COLIS À RÉCEPTIONNER',
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
// Bascule du mode de réception
// ---------------------------------------------------------------------------
class _ReceptionAuColisCard extends StatelessWidget {
  final double Function(double) dp;
  final bool value;
  final Color teal;
  final Color tealBg;
  final ValueChanged<bool> onChanged;

  const _ReceptionAuColisCard({
    required this.dp,
    required this.value,
    required this.teal,
    required this.tealBg,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(dp(16));

    return Material(
      color: SwappMenuColors.panel,
      borderRadius: radius,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            color: SwappMenuColors.panel,
            borderRadius: radius,
            border: Border.all(
              color: value ? teal : SwappMenuColors.ink.withValues(alpha: 0.06),
              width: value ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: SwappMenuColors.ink.withValues(alpha: 0.06),
                blurRadius: dp(12),
                offset: Offset(0, dp(4)),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(dp(12), dp(10), dp(8), dp(10)),
            child: Row(
              children: [
                Container(
                  width: dp(42),
                  height: dp(42),
                  decoration: BoxDecoration(
                    color: tealBg,
                    borderRadius: BorderRadius.circular(dp(12)),
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: teal,
                    size: dp(22),
                  ),
                ),
                SizedBox(width: dp(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Réception au colis',
                        style: TextStyle(
                          fontSize: dp(14),
                          fontWeight: FontWeight.w900,
                          color: value ? teal : SwappMenuColors.ink,
                        ),
                      ),
                      SizedBox(height: dp(2)),
                      Text(
                        value
                            ? 'Chaque colis est scanné séparément'
                            : 'Le support est réceptionné en une fois',
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
                Switch.adaptive(
                  value: value,
                  onChanged: onChanged,
                  activeTrackColor: teal,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ligne du tableau
// ---------------------------------------------------------------------------
class _SupportRow extends StatelessWidget {
  final double Function(double) dp;
  final SupportCollectionItem support;
  final bool current;
  final Color teal;
  final Color greenBg;
  final Color greenInk;
  final VoidCallback onTap;

  const _SupportRow({
    required this.dp,
    required this.support,
    required this.current,
    required this.teal,
    required this.greenBg,
    required this.greenInk,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = current ? Colors.white : SwappMenuColors.ink;

    return Material(
      color: current ? teal : SwappMenuColors.panel,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(12)),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping_rounded,
                      size: dp(17),
                      color: current ? Colors.white : teal,
                    ),
                    SizedBox(width: dp(8)),
                    Expanded(
                      child: Text(
                        support.numSupport,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: dp(13),
                          fontWeight: FontWeight.w900,
                          color: ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: dp(SwappTableLayout.total),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SwappCountPill(
                    dp: dp,
                    value: support.total,
                    bg: current
                        ? Colors.white.withValues(alpha: 0.22)
                        : const Color(0xFFF1F5F9),
                    fg: current ? Colors.white : SwappMenuColors.inkDim,
                  ),
                ),
              ),
              SizedBox(
                width: dp(SwappTableLayout.restant),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SwappCountPill(
                    dp: dp,
                    value: support.restant,
                    bg: current
                        ? Colors.white
                        : support.termine
                        ? greenBg
                        : SwappMenuColors.p5Bg,
                    fg: current
                        ? teal
                        : support.termine
                        ? greenInk
                        : SwappMenuColors.p5,
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
