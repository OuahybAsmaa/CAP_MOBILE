// =============================================================================
// CapMobile — Module Swapp — Menu Transferts (maquette)
// -----------------------------------------------------------------------------
// Fonctionnalité : Hub Transferts — 6 actions (inter-magasin, OT, transporteur…).
// Design         : Header blanc · Test imprimante · 3 outils ronds · grille 2×3.
// UI             : Ouvert depuis SwappMenuPage « Transferts » ; Inter-magasin →
//                  Destination ; Remise / Enlèvement → RemiseTransporteurPage.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/transfert/data/retour_depot_test_data.dart';
import 'package:cap_mobile/core/apiswap/transfert/data/operation_transfert_test_data.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/swapp/pages/produit/detail_produit_page.dart';
import 'package:cap_mobile/swapp/pages/transfert/compteur_selection_page.dart';
import 'package:cap_mobile/swapp/pages/transfert/info_transfert_destination_page.dart';
import 'package:cap_mobile/swapp/pages/transfert/operations_transfert_page.dart';
import 'package:cap_mobile/swapp/pages/transfert/remise_transporteur_page.dart';
import 'package:cap_mobile/swapp/pages/transfert/retour_depot_page.dart';
import 'package:cap_mobile/swapp/widgets/qr_camera_scanner_page.dart';
import 'package:cap_mobile/swapp/widgets/reprise_en_cours_dialog.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cap_mobile/core/apiswap/produit/providers/swapp_product_provider.dart';

/// Hub « Transferts » — grille moderne alignée maquette.
class InfoTransfertMenuPage extends ConsumerWidget {
  const InfoTransfertMenuPage({super.key});

  static Route<void> fadeRoute() =>
      swappMenuFadeRoute(const InfoTransfertMenuPage());

  /// Tuile « Ordre de Transfert » — propose de reprendre les OT en attente.
  Future<void> _openOrdreTransfert(BuildContext context) async {
    HapticFeedback.lightImpact();
    // TODO(API) : remplacer par SwappApiService.fetchOperationsTransfert()
    final enAttente = OperationTransfertDemoData.items();

    if (enAttente.isEmpty) {
      await Navigator.push(
        context,
        CompteurSelectionPage.fadeRoute(
          instruction: CompteurSelectionTextes.transfert,
        ),
      );
      return;
    }

    final poursuivre = await showRepriseEnCoursDialog(
      context,
      message:
          'Vous avez des OTs en cours de réalisation.\n'
          'Souhaitez-vous les poursuivre ?',
      nbEnAttente: enAttente.length,
      uniteEnAttente: 'OT',
      nbArticles: enAttente.fold<int>(0, (total, ot) => total + ot.nbArticles),
    );
    if (!context.mounted || !poursuivre) return;

    await Navigator.push(context, OperationsTransfertPage.fadeRoute());
  }

  /// Tuile « Retour Dépôt » — propose de reprendre les retours en attente.
  Future<void> _openRetourDepot(BuildContext context) async {
    HapticFeedback.lightImpact();
    // TODO(API) : remplacer par SwappApiService.fetchRetoursDepot()
    final enAttente = RetourDepotDemoData.items();

    if (enAttente.isEmpty) {
      await Navigator.push(
        context,
        CompteurSelectionPage.fadeRoute(
          instruction: CompteurSelectionTextes.retour,
        ),
      );
      return;
    }

    final poursuivre = await showRepriseEnCoursDialog(
      context,
      message:
          'Vous avez des retours dépôt en cours de réalisation.\n'
          'Souhaitez-vous les poursuivre ?',
      nbEnAttente: enAttente.length,
      uniteEnAttente: 'retour',
      nbArticles: enAttente.fold<int>(0, (total, r) => total + r.nbArticles),
      icon: Icons.inventory_2_outlined,
    );
    if (!context.mounted || !poursuivre) return;

    await Navigator.push(context, RetourDepotPage.fadeRoute());
  }

  void _soon(BuildContext context, String label) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label — bientôt'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.35);
    double dp(double v) => v * scale;
    final top = MediaQuery.paddingOf(context).top;

    Future<void> openScan() async {
      final code = await openQrCameraScanner(context, context.l10n);
      if (!context.mounted || code == null || code.trim().isEmpty) return;
      await ref
          .read(swappProductProvider.notifier)
          .fetchModele(codeModele: code.trim());
      if (!context.mounted) return;
      await Navigator.push(
        context,
        DetailProduitPage.fadeRoute(loadDefaultProduct: false),
      );
    }

    final tiles = <_TransferTileData>[
      _TransferTileData(
        title: 'Transfert Inter-magasin',
        subtitle: 'Entre points de vente',
        icon: Icons.link_rounded,
        iconBg: SwappMenuColors.p1Bg,
        iconColor: SwappMenuColors.p1,
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(context, InfoTransfertDestinationPage.fadeRoute());
        },
      ),
      _TransferTileData(
        title: 'Remise au Transporteur',
        subtitle: 'Colis à expédier',
        icon: Icons.local_shipping_outlined,
        iconBg: SwappMenuColors.p3Bg,
        iconColor: SwappMenuColors.p3,
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            RemiseTransporteurPage.fadeRoute(title: 'Remise au Transporteur'),
          );
        },
      ),
      _TransferTileData(
        title: 'Ordre de Transfert',
        subtitle: 'Créer & suivre',
        icon: Icons.assignment_turned_in_outlined,
        iconBg: SwappMenuColors.p2Bg,
        iconColor: SwappMenuColors.p2,
        onTap: () => _openOrdreTransfert(context),
      ),
      _TransferTileData(
        title: "Demande d'enlèv. Transporteur",
        subtitle: 'Planifier un enlèvement',
        icon: Icons.help_outline_rounded,
        iconBg: const Color(0xFFE0F7F4),
        iconColor: const Color(0xFF0D9488),
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            RemiseTransporteurPage.fadeRoute(title: "Demande d'enlèvement"),
          );
        },
      ),
      _TransferTileData(
        title: 'Retour Dépôt',
        subtitle: 'Réintégration stock',
        icon: Icons.home_outlined,
        iconBg: SwappMenuColors.p5Bg,
        iconColor: SwappMenuColors.p5,
        onTap: () => _openRetourDepot(context),
      ),
      _TransferTileData(
        title: 'Consultation support',
        subtitle: 'Historique codes-barres',
        icon: Icons.view_week_outlined,
        iconBg: SwappMenuColors.p6Bg,
        iconColor: SwappMenuColors.p6,
        onTap: () => _soon(context, 'Consultation support'),
      ),
    ];

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: SwappMenuColors.bg,
      ),
      child: Scaffold(
        backgroundColor: SwappMenuColors.bg,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(dp(16), top + dp(10), dp(16), dp(8)),
              child: Row(
                children: [
                  Material(
                    color: SwappMenuColors.panel,
                    borderRadius: BorderRadius.circular(dp(12)),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(dp(12)),
                      child: SizedBox(
                        width: dp(40),
                        height: dp(40),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: SwappMenuColors.ink,
                          size: dp(20),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: dp(12)),
                  Expanded(
                    child: Text(
                      'Transferts',
                      style: TextStyle(
                        fontSize: dp(22),
                        fontWeight: FontWeight.w900,
                        color: SwappMenuColors.ink,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Material(
                    color: SwappMenuColors.indigo,
                    borderRadius: BorderRadius.circular(dp(22)),
                    elevation: 4,
                    shadowColor: SwappMenuColors.indigo.withValues(alpha: 0.45),
                    child: InkWell(
                      onTap: () => _soon(context, 'Test imprimante'),
                      borderRadius: BorderRadius.circular(dp(22)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: dp(12),
                          vertical: dp(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.print_rounded,
                              color: Colors.white,
                              size: dp(16),
                            ),
                            SizedBox(width: dp(6)),
                            Text(
                              'Test imprimante',
                              style: TextStyle(
                                fontSize: dp(11),
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(dp(16), dp(6), dp(16), dp(4)),
              child: Row(
                children: [
                  _RoundTool(
                    dp: dp,
                    color: AppColors.error,
                    icon: Icons.apps_rounded,
                    onTap: () => _soon(context, 'Recherche article'),
                  ),
                  SizedBox(width: dp(10)),
                  _RoundTool(
                    dp: dp,
                    color: const Color(0xFFC4A574),
                    icon: Icons.crop_square_rounded,
                    onTap: () => _soon(context, 'Ranger'),
                  ),
                  SizedBox(width: dp(10)),
                  _RoundTool(
                    dp: dp,
                    color: SwappMenuColors.ink,
                    icon: Icons.qr_code_scanner_rounded,
                    onTap: openScan,
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.fromLTRB(dp(16), dp(14), dp(16), dp(24)),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: dp(12),
                  mainAxisSpacing: dp(12),
                  childAspectRatio: 1.05,
                ),
                itemCount: tiles.length,
                itemBuilder: (context, index) {
                  return _TransferCard(dp: dp, data: tiles[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransferTileData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;

  const _TransferTileData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });
}

class _RoundTool extends StatelessWidget {
  final double Function(double) dp;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _RoundTool({
    required this.dp,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: dp(42),
          height: dp(42),
          child: Icon(icon, color: Colors.white, size: dp(20)),
        ),
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final double Function(double) dp;
  final _TransferTileData data;

  const _TransferCard({required this.dp, required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SwappMenuColors.panel,
      borderRadius: BorderRadius.circular(dp(18)),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(dp(18)),
        child: Ink(
          decoration: BoxDecoration(
            color: SwappMenuColors.panel,
            borderRadius: BorderRadius.circular(dp(18)),
            boxShadow: [
              BoxShadow(
                color: SwappMenuColors.ink.withValues(alpha: 0.08),
                blurRadius: dp(16),
                offset: Offset(0, dp(6)),
              ),
              BoxShadow(
                color: SwappMenuColors.ink.withValues(alpha: 0.04),
                blurRadius: dp(4),
                offset: Offset(0, dp(1)),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(dp(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: dp(40),
                      height: dp(40),
                      decoration: BoxDecoration(
                        color: data.iconBg,
                        borderRadius: BorderRadius.circular(dp(12)),
                      ),
                      child: Icon(
                        data.icon,
                        color: data.iconColor,
                        size: dp(22),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: dp(28),
                      height: dp(28),
                      decoration: BoxDecoration(
                        color: data.iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: data.iconColor,
                        size: dp(14),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: dp(13),
                    fontWeight: FontWeight.w900,
                    color: SwappMenuColors.ink,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: dp(4)),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: dp(11),
                    fontWeight: FontWeight.w600,
                    color: SwappMenuColors.inkDim,
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
