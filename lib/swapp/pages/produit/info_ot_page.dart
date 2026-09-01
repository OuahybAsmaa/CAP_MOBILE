// =============================================================================
// CapMobile — Module Swapp — Page Info OT
// -----------------------------------------------------------------------------
// Fonctionnalité : Liste ordres de transfert — Article · Qté · Magasin.
// Design         : Thème SWAPP indigo — header blanc, tableau, scan QR.
// UI             : Toolbar scan · table OT · flèche → fiche produit.
// Spécifications : infoOtProvider (démo) → SwappApiService.fetchInfoOts() TODO.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/transfert/providers/info_ot_provider.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/core/widgets/app_popup.dart';
import 'package:cap_mobile/features/auth/providers/auth_provider.dart';
import 'package:cap_mobile/swapp/models/info_ot_item.dart';
import 'package:cap_mobile/swapp/pages/produit/detail_produit_page.dart';
import 'package:cap_mobile/swapp/widgets/qr_camera_scanner_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_tool_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cap_mobile/core/apiswap/produit/providers/swapp_product_provider.dart';

/// Écran « Info OT » — ordres de transfert magasin.
class InfoOtPage extends ConsumerStatefulWidget {
  const InfoOtPage({super.key});

  static Route<void> fadeRoute() => swappMenuFadeRoute(const InfoOtPage());

  @override
  ConsumerState<InfoOtPage> createState() => _InfoOtPageState();
}

class _InfoOtPageState extends ConsumerState<InfoOtPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final collab = ref.read(authProvider).collaborateur;
    await ref
        .read(infoOtProvider.notifier)
        .fetchItems(codeMag: collab?.codeMag);
  }

  Future<void> _openProduct(String codeArticle) async {
    HapticFeedback.lightImpact();
    await ref
        .read(swappProductProvider.notifier)
        .fetchModele(codeModele: codeArticle);
    if (!mounted) return;
    await Navigator.push(
      context,
      DetailProduitPage.fadeRoute(loadDefaultProduct: false),
    );
  }

  Future<void> _openQrScanner() async {
    final code = await openQrCameraScanner(context, context.l10n);
    if (!mounted || code == null || code.trim().isEmpty) return;

    final trimmed = code.trim();
    ref.read(infoOtProvider.notifier).setSearchQuery(trimmed);
    await _openProduct(trimmed);
  }

  void _showInfoDialog() {
    AppPopup.info(
      context,
      title: 'Info OT',
      message:
          'Ordres de transfert entre magasins.\n\n'
          '• Scanner un article pour filtrer ou ouvrir la fiche\n'
          '• Flèche : détail produit\n\n'
          'TODO(API) : branchement GET /api/ots/{codeMag}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(infoOtProvider);
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.35);
    double dp(double v) => v * scale;
    final top = MediaQuery.paddingOf(context).top;
    final items = state.visibleItems;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: SwappMenuColors.panel,
      ),
      child: Scaffold(
        backgroundColor: SwappMenuColors.bg,
        body: Column(
          children: [
            _OtHeader(
              dp: dp,
              top: top,
              count: items.length,
              isDemo: true,
              onBack: () => Navigator.pop(context),
              onInfo: _showInfoDialog,
            ),
            Expanded(
              child: RefreshIndicator(
                color: SwappMenuColors.indigo,
                onRefresh: _load,
                child: state.isLoading && state.items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: dp(120)),
                          const Center(child: CircularProgressIndicator()),
                        ],
                      )
                    : state.error != null && state.items.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.all(dp(24)),
                        children: [
                          _ErrorState(
                            dp: dp,
                            message: state.error!,
                            onRetry: _load,
                          ),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          dp(16),
                          dp(12),
                          dp(16),
                          dp(24),
                        ),
                        children: [
                          _ScanToolCard(dp: dp, onScanQr: _openQrScanner),
                          if (state.searchQuery != null &&
                              state.searchQuery!.isNotEmpty) ...[
                            SizedBox(height: dp(8)),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: InputChip(
                                label: Text(
                                  'Filtre : ${state.searchQuery}',
                                  style: TextStyle(fontSize: dp(11)),
                                ),
                                deleteIcon: const Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  ref
                                      .read(infoOtProvider.notifier)
                                      .setSearchQuery(null);
                                },
                                backgroundColor: SwappMenuColors.p1Bg,
                                side: BorderSide.none,
                              ),
                            ),
                          ],
                          SizedBox(height: dp(12)),
                          _ApiBanner(dp: dp),
                          SizedBox(height: dp(12)),
                          _TableHeader(dp: dp),
                          SizedBox(height: dp(6)),
                          if (items.isEmpty)
                            _EmptyState(dp: dp)
                          else
                            ...List.generate(items.length, (index) {
                              final item = items[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: dp(8)),
                                child: _OtRowCard(
                                  dp: dp,
                                  item: item,
                                  onView: () => _openProduct(item.codeArticle),
                                ),
                              );
                            }),
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

class _OtHeader extends StatelessWidget {
  final double Function(double) dp;
  final double top;
  final int count;
  final bool isDemo;
  final VoidCallback onBack;
  final VoidCallback onInfo;

  const _OtHeader({
    required this.dp,
    required this.top,
    required this.count,
    required this.isDemo,
    required this.onBack,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SwappMenuColors.panel,
        boxShadow: [
          BoxShadow(
            color: SwappMenuColors.ink.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(dp(4), top + dp(4), dp(8), dp(14)),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: SwappMenuColors.ink,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Info OT',
                    style: TextStyle(
                      fontSize: dp(20),
                      fontWeight: FontWeight.w900,
                      color: SwappMenuColors.ink,
                    ),
                  ),
                  Text(
                    'Ordres de transfert · $count ligne${count > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: dp(11),
                      color: SwappMenuColors.inkDim,
                    ),
                  ),
                ],
              ),
            ),
            if (isDemo)
              Container(
                margin: EdgeInsets.only(right: dp(4)),
                padding: EdgeInsets.symmetric(
                  horizontal: dp(8),
                  vertical: dp(3),
                ),
                decoration: BoxDecoration(
                  color: SwappMenuColors.p5Bg,
                  borderRadius: BorderRadius.circular(dp(8)),
                ),
                child: Text(
                  'DÉMO',
                  style: TextStyle(
                    fontSize: dp(9),
                    fontWeight: FontWeight.w900,
                    color: SwappMenuColors.p5,
                  ),
                ),
              ),
            IconButton(
              onPressed: onInfo,
              icon: const Icon(Icons.info_outline_rounded),
              color: SwappMenuColors.indigo,
              tooltip: 'Aide',
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanToolCard extends StatelessWidget {
  final double Function(double) dp;
  final VoidCallback onScanQr;

  const _ScanToolCard({required this.dp, required this.onScanQr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dp(14), vertical: dp(12)),
      decoration: BoxDecoration(
        color: SwappMenuColors.panel,
        borderRadius: BorderRadius.circular(dp(16)),
        boxShadow: [
          BoxShadow(
            color: SwappMenuColors.ink.withValues(alpha: 0.08),
            blurRadius: dp(12),
            offset: Offset(0, dp(4)),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Actions',
              style: TextStyle(
                fontSize: dp(12),
                fontWeight: FontWeight.w800,
                color: SwappMenuColors.ink,
              ),
            ),
          ),
          SwappCompactToolbar(
            buttonSize: dp(36),
            gap: dp(8),
            onQrScan: onScanQr,
          ),
        ],
      ),
    );
  }
}

/// Bandeau rappel intégration API — visible en mode démo.
class _ApiBanner extends StatelessWidget {
  final double Function(double) dp;

  const _ApiBanner({required this.dp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(8)),
      decoration: BoxDecoration(
        color: SwappMenuColors.p4Bg,
        borderRadius: BorderRadius.circular(dp(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_outlined, size: dp(16), color: SwappMenuColors.p4),
          SizedBox(width: dp(8)),
          Expanded(
            child: Text(
              'Données test — API : SwappApiService.fetchInfoOts()',
              style: TextStyle(
                fontSize: dp(10),
                fontWeight: FontWeight.w600,
                color: SwappMenuColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final double Function(double) dp;

  const _TableHeader({required this.dp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(10)),
      decoration: BoxDecoration(
        color: SwappMenuColors.ink,
        borderRadius: BorderRadius.circular(dp(12)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              'Article',
              style: TextStyle(
                fontSize: dp(11),
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Qté',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: dp(11),
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'Magasin',
              style: TextStyle(
                fontSize: dp(11),
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(
            width: dp(40),
            child: Text(
              '—',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: dp(11),
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtRowCard extends StatelessWidget {
  final double Function(double) dp;
  final InfoOtItem item;
  final VoidCallback onView;

  const _OtRowCard({
    required this.dp,
    required this.item,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SwappMenuColors.panel,
      borderRadius: BorderRadius.circular(dp(14)),
      elevation: 2,
      shadowColor: SwappMenuColors.ink.withValues(alpha: 0.12),
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(dp(14)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dp(10), vertical: dp(12)),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.codeArticle,
                      style: TextStyle(
                        fontSize: dp(12),
                        fontWeight: FontWeight.w900,
                        color: SwappMenuColors.ink,
                      ),
                    ),
                    if (item.libelle != null && item.libelle!.isNotEmpty) ...[
                      SizedBox(height: dp(2)),
                      Text(
                        item.libelle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: dp(9),
                          color: SwappMenuColors.inkDim,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: dp(6),
                    vertical: dp(4),
                  ),
                  decoration: BoxDecoration(
                    color: SwappMenuColors.p2Bg,
                    borderRadius: BorderRadius.circular(dp(8)),
                  ),
                  child: Text(
                    '${item.quantite}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: dp(13),
                      fontWeight: FontWeight.w900,
                      color: SwappMenuColors.p2,
                    ),
                  ),
                ),
              ),
              SizedBox(width: dp(6)),
              Expanded(
                flex: 3,
                child: Text(
                  item.libelleMagasin,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: dp(10),
                    fontWeight: FontWeight.w700,
                    color: SwappMenuColors.inkDim,
                  ),
                ),
              ),
              SizedBox(
                width: dp(36),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: SwappMenuColors.indigo,
                  size: dp(20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final double Function(double) dp;

  const _EmptyState({required this.dp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dp(32)),
      child: Column(
        children: [
          Icon(
            Icons.sync_alt_rounded,
            size: dp(40),
            color: SwappMenuColors.inkDim,
          ),
          SizedBox(height: dp(8)),
          Text(
            'Aucun ordre de transfert',
            style: TextStyle(color: SwappMenuColors.inkDim, fontSize: dp(13)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final double Function(double) dp;
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.dp,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.error_outline, size: dp(40), color: SwappMenuColors.p6),
        SizedBox(height: dp(12)),
        Text(message, textAlign: TextAlign.center),
        SizedBox(height: dp(16)),
        FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    );
  }
}
