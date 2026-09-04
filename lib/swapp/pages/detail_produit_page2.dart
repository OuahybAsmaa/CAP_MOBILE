// =============================================================================
// CapMobile — Module Swapp — Page Produit v2 (DetailProduitPage2)
// -----------------------------------------------------------------------------
// Fonctionnalité : Variante UI fiche produit — grille overview, lignes taille colorées,
//                  toggle Mag/Web, scan, sélection magasin, i18n FR/EN/NL.
// Design         : Header avec panier/cmd ; cartes overview ; tableau métriques ;
//                  couleurs _sizeRowColors ; nav bas 5 onglets.
// UI             : Variante écran produit — Header enrichi (panier/cmd) ;
//                  _OverviewGrid2 cartes récap ; _SizeRow2 lignes colorées ;
//                  même BottomNav 5 onglets que v1.
// Spécifications : Même providers que v1 ; widgets extraits (ArticleCodeDialog…) ;
//                  layout _Layout2 scale 0.9–1.35.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/stock_web_provider.dart';
import 'package:cap_mobile/core/apiswap/swapp_api_constants.dart';
import 'package:cap_mobile/core/apiswap/swapp_product_provider.dart';
import 'package:cap_mobile/core/l10n/app_localizations.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/core/l10n/language_menu_button.dart';
import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/swapp/models/product_stock_view.dart';
import 'package:cap_mobile/swapp/pages/client_search_page.dart';
import 'package:cap_mobile/swapp/utils/swapp_scan_flow.dart';
import 'package:cap_mobile/swapp/widgets/article_code_dialog.dart';
import 'package:cap_mobile/features/auth/models/collaborateur_model.dart';
import 'package:cap_mobile/features/auth/providers/auth_provider.dart';
import 'package:cap_mobile/swapp/widgets/reassort_chip.dart';
import 'package:cap_mobile/swapp/widgets/product_photo_circle.dart';
import 'package:cap_mobile/swapp/widgets/store_picker_dialog.dart';
import 'package:cap_mobile/swapp/widgets/store_select_button.dart';
import 'package:cap_mobile/swapp/widgets/qr_camera_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/apiswap/produit/data/product_test_data.dart';


const _depotPurple = Color(0xFF7C3AED);

/// UI : 0 bleu, stock >0 vert foncé, <0 rouge (tableau v2).
Color _stockAmountColor2(int value) {
  if (value < 0) return AppColors.error;
  if (value == 0) return AppColors.primary;
  return const Color(0xFF047857);
}

const _sizeRowColors = [
  Color(0xFF1A237E),
  Color(0xFF3949AB),
  Color(0xFF1E40AF),
  Color(0xFF059669),
  Color(0xFF7C3AED),
  Color(0xFFEA580C),
  Color(0xFF01667E),
];

/// Mise à l'échelle responsive v2 (base 360 px).
class _Layout2 {
  _Layout2(BuildContext context)
      : scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.35);

  final double scale;
  double dp(double v) => v * scale;
  double sp(double v) => v * scale;
}

enum _StockSource { mag, web }

/// Page produit Swapp v2 — ConsumerStatefulWidget, DataWedge + Riverpod.
class DetailProduitPage2 extends ConsumerStatefulWidget {
  const DetailProduitPage2({super.key});

  @override
  ConsumerState<DetailProduitPage2> createState() => _DetailProduitPage2State();
}

class _DetailProduitPage2State extends ConsumerState<DetailProduitPage2> {
  final _dataWedge = SwappDataWedgeListener();
  bool _available = true;
  int _navIndex = 0;
  _StockSource _stockSource = _StockSource.mag;
  int _selectedCodeMag = SwappApiConstants.defaultCodeMag;

  List<MagasinModel> get _stores =>
      resolveMagasins(ref.read(authProvider).collaborateur?.mags);

  String get _selectedStoreLabel =>
      storeLabelFor(_selectedCodeMag, _stores);

  Future<void> _pickStore() async {
    final picked = await showStorePickerDialog(
      context: context,
      stores: _stores,
      selectedCodeMag: _selectedCodeMag,
    );
    if (!mounted || picked == null || picked == _selectedCodeMag) return;

    setState(() => _selectedCodeMag = picked);
    final code = ref.read(swappProductProvider).product?.reference ??
        SwappApiConstants.defaultCodeModele;
    await ref.read(swappProductProvider.notifier).fetchModele(
          codeModele: code,
          codeMag: picked,
        );
  }

  void _onNavChanged(int i) {
    setState(() {
      _navIndex = i;
      if (i == 0) _stockSource = _StockSource.mag;
      if (i == 1) _stockSource = _StockSource.web;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final collab = ref.read(authProvider).collaborateur;
      if (collab != null) {
        setState(() => _selectedCodeMag = collab.codeMag);
      }
      _initDataWedge();
      _loadDefaultProduct();
    });
  }

  Future<void> _loadDefaultProduct() async {
    await ref.read(swappProductProvider.notifier).fetchModele(
          codeModele: SwappApiConstants.defaultCodeModele,
          codeMag: _selectedCodeMag,
        );
    _fetchStockWeb(SwappApiConstants.defaultCodeModele);
  }

  void _fetchStockWeb(String code) {
    ref.read(stockWebProvider.notifier).fetchStockWeb(code);
  }

  Future<void> _processScan(String code) async {
    await processSwappProductScanUi(
      context: context,
      ref: ref,
      code: code,
      codeMag: _selectedCodeMag,
    );
  }

  Future<void> _initDataWedge() async {
    await _dataWedge.start(
      ref: ref,
      onScan: _processScan,
    );
    if (mounted) setState(() {});
  }

  Future<void> _openQrScanner() async {
    if (!mounted) return;

    _dataWedge.pause();
    try {
      final code = await openQrCameraScanner(context, context.l10n);
      if (!mounted || code == null || code.isEmpty) return;
      await _processScan(code);
    } finally {
      _dataWedge.resume();
    }
  }

  @override
  void dispose() {
    _dataWedge.dispose();
    super.dispose();
  }

  ProductStockView _product(SwappProductState state) =>
      state.product ?? demoProductStockView();

  Future<void> _openArticleDialog() async {
    if (!mounted) return;
    final current = ref.read(swappProductProvider).product?.reference ??
        SwappApiConstants.defaultCodeModele;
    final code = await showArticleCodeDialog(
      context,
      initialCode: current,
    );
    if (!mounted || code == null || code.isEmpty) return;
    await ref.read(swappProductProvider.notifier).fetchModele(
          codeModele: code,
          codeMag: _selectedCodeMag,
        );
    _fetchStockWeb(code);
  }

  Map<String, Map<String, int>> _stockData(
    ProductStockView product,
    StockWebState webState,
  ) {
    return _stockSource == _StockSource.web
        ? webState.stockBySize
        : product.stockBySize;
  }

  Map<String, int> _totals(Map<String, Map<String, int>> stock) {
    final totals = <String, int>{
      'dispo': 0,
      'transit': 0,
      'picking': 0,
      'depot': 0,
    };
    for (final line in stock.values) {
      for (final e in line.entries) {
        totals[e.key] = (totals[e.key] ?? 0) + e.value;
      }
    }
    return totals;
  }

  List<String> _sizes(Map<String, Map<String, int>> stock, ProductStockView p) {
    if (stock.isNotEmpty) {
      return stock.keys.toList()
        ..sort((a, b) {
          final ai = int.tryParse(a);
          final bi = int.tryParse(b);
          if (ai != null && bi != null) return ai.compareTo(bi);
          return a.compareTo(b);
        });
    }
    final match =
        RegExp(r'(\d+)\s*au\s*(\d+)', caseSensitive: false).firstMatch(p.sizeRange);
    if (match != null) {
      final from = int.parse(match.group(1)!);
      final to = int.parse(match.group(2)!);
      return [for (var i = from; i <= to; i++) '$i'];
    }
    return p.size.isNotEmpty ? [p.size] : const [];
  }

  String _navPlaceholderLabel(AppLocalizations l10n) {
    switch (_navIndex) {
      case 2:
        return l10n.navNearby;
      case 3:
        return l10n.navReviews;
      case 4:
        return l10n.navReserve;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final l = _Layout2(context);
    final swapp = ref.watch(swappProductProvider);
    final web = ref.watch(stockWebProvider);
    final product = _product(swapp);
    final stock = _stockData(product, web);
    final totals = _totals(stock);
    final sizes = _sizes(stock, product);
    final loading = swapp.isLoading && swapp.product == null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F8),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                    _Header2(
                      l: l,
                      product: product,
                      onBack: () => Navigator.pop(context),
                    ),
                  Expanded(
                    child: ListView(
                      padding:
                          EdgeInsets.fromLTRB(l.dp(16), 0, l.dp(16), l.dp(100)),
                        children: [
                          if ((_stockSource == _StockSource.mag
                                  ? swapp.error
                                  : web.error) !=
                              null)
                            _ErrorBanner(
                              l: l,
                              message: (_stockSource == _StockSource.mag
                                      ? swapp.error
                                      : web.error)!,
                            ),
                          _ProductCard2(
                            l: l,
                            product: product,
                            available: _available,
                            onAvailableChanged: (v) =>
                                setState(() => _available = v),
                            onSearch: _openArticleDialog,
                            onQrScan: _openQrScanner,
                            storeLabel: _selectedStoreLabel,
                            onStoreSelect: _pickStore,
                          ),
                          SizedBox(height: l.dp(14)),
                          _OverviewGrid2(
                            l: l,
                            totals: totals,
                            webMode: _stockSource == _StockSource.web,
                          ),
                          SizedBox(height: l.dp(12)),
                          if (_navIndex <= 1)
                            ...sizes.asMap().entries.map(
                              (entry) => Padding(
                                padding: EdgeInsets.only(bottom: l.dp(10)),
                                child: _SizeRow2(
                                  l: l,
                                  rowIndex: entry.key,
                                  size: entry.value,
                                  line: stock[entry.value] ?? const {},
                                  highlight: entry.value == product.size,
                                  webMode: _stockSource == _StockSource.web,
                                ),
                              ),
                            )
                          else
                            _NavPlaceholder2(
                              l: l,
                              label: _navPlaceholderLabel(l10n),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        bottomNavigationBar: _BottomNav2(
          l: l,
          index: _navIndex,
          onChanged: _onNavChanged,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// En-tête v2 — retour, titre, langue, clients, panier
// UI     : Barre fixe haut — person_outline → ClientSearchPage ;
//          _HeaderPanierBtn + LanguageMenuButton.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _Header2 extends StatelessWidget {
  final _Layout2 l;
  final ProductStockView product;
  final VoidCallback onBack;

  const _Header2({
    required this.l,
    required this.product,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      padding: EdgeInsets.fromLTRB(l.dp(12), topInset + l.dp(8), l.dp(12), l.dp(14)),
      child: Row(
        children: [
          _HeaderActionBtn(
            l: l,
            icon: Icons.arrow_back,
            onTap: onBack,
          ),
          SizedBox(width: l.dp(12)),
          Expanded(
            child: Text(
              l10n.productPageTitle,
              style: TextStyle(
                fontSize: l.sp(17),
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
          ),
          LanguageMenuButton(
            iconSize: l.dp(22),
            iconColor: Colors.white.withOpacity(0.9),
          ),
          SizedBox(width: l.dp(4)),
          // UI : Module Swapp — recherche / ajout client (ClientSearchPage).
          _HeaderActionBtn(
            l: l,
            icon: Icons.person_outline,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => const ClientSearchPage(),
                  transitionsBuilder: (_, anim, __, child) =>
                      FadeTransition(opacity: anim, child: child),
                  transitionDuration: const Duration(milliseconds: 300),
                ),
              );
            },
          ),
          SizedBox(width: l.dp(8)),
          _HeaderPanierBtn(l: l, qty: product.cartQty),
        ],
      ),
    );
  }
}

class _HeaderActionBtn extends StatelessWidget {
  final _Layout2 l;
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderActionBtn({
    required this.l,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: l.dp(40),
          height: l.dp(40),
          child: Icon(icon, color: Colors.white, size: l.dp(22)),
        ),
      ),
    );
  }
}

class _HeaderPanierBtn extends StatelessWidget {
  final _Layout2 l;
  final int qty;

  const _HeaderPanierBtn({required this.l, required this.qty});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => HapticFeedback.selectionClick(),
        child: SizedBox(
          width: l.dp(44),
          height: l.dp(44),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
                size: l.dp(26),
              ),
              if (qty > 0)
                Positioned(
                  top: l.dp(2),
                  right: l.dp(2),
                  child: Container(
                    constraints: BoxConstraints(minWidth: l.dp(18)),
                    height: l.dp(18),
                    padding: EdgeInsets.symmetric(horizontal: l.dp(4)),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(l.dp(99)),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      qty > 99 ? '99+' : '$qty',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: l.sp(10),
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
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

class _HeaderIcon extends StatelessWidget {
  final _Layout2 l;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _HeaderIcon({
    required this.l,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: l.dp(4)),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(l.dp(12)),
        elevation: 1,
        shadowColor: color.withOpacity(0.35),
        child: InkWell(
          borderRadius: BorderRadius.circular(l.dp(12)),
          onTap: onTap != null
              ? () {
                  HapticFeedback.selectionClick();
                  onTap!();
                }
              : null,
          child: SizedBox(
            width: l.dp(34),
            height: l.dp(34),
            child: Icon(icon, size: l.dp(17), color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final _Layout2 l;
  final String message;

  const _ErrorBanner({required this.l, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: l.dp(10)),
      padding: EdgeInsets.all(l.dp(10)),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(l.dp(12)),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Text(message, style: TextStyle(color: AppColors.error, fontSize: l.sp(12))),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte produit v2 — réassort, photo, pastilles, toolbar, magasin
// UI     : Équivalent _ProductHeroCard v1 — layout légèrement différent (Pill2).
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _ProductCard2 extends StatelessWidget {
  final _Layout2 l;
  final ProductStockView product;
  final bool available;
  final ValueChanged<bool> onAvailableChanged;
  final VoidCallback onSearch;
  final VoidCallback onQrScan;
  final String storeLabel;
  final VoidCallback onStoreSelect;

  const _ProductCard2({
    required this.l,
    required this.product,
    required this.available,
    required this.onAvailableChanged,
    required this.onSearch,
    required this.onQrScan,
    required this.storeLabel,
    required this.onStoreSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: EdgeInsets.all(l.dp(14)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(l.dp(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: l.dp(16),
            offset: Offset(0, l.dp(6)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ReassortChip(
                  ok: product.reassortOk,
                  dp: l.dp,
                  sp: l.sp,
                ),
              ),
              SizedBox(width: l.dp(4)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _HeaderIcon(
                    l: l,
                    icon: Icons.apps_rounded,
                    color: AppColors.error,
                    onTap: onSearch,
                  ),
                  _HeaderIcon(
                    l: l,
                    icon: Icons.nfc_rounded,
                    color: AppColors.warning,
                  ),
                  _HeaderIcon(
                    l: l,
                    icon: Icons.qr_code_scanner_rounded,
                    color: AppColors.primaryDark,
                    onTap: onQrScan,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: l.dp(10)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${product.reference} · ${l10n.displayColorway(product.colorway)} · ${l10n.displaySizeLabel(product.size)}',
                      style: TextStyle(
                        fontSize: l.sp(15),
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        height: 1.25,
                      ),
                    ),
                    SizedBox(height: l.dp(4)),
                    Text(
                      '${l10n.displaySizeOrRange(product.sizeRange)} · ${l10n.displayCategory(product.category)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: l.sp(12),
                        fontWeight: FontWeight.w600,
                        color: AppColors.orange,
                        height: 1.2,
                      ),
                    ),
                    if (product.segment.isNotEmpty) ...[
                      SizedBox(height: l.dp(2)),
                      Text(
                        l10n.displaySegment(product.segment),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: l.sp(11),
                          color: AppColors.textSecondary,
                          height: 1.2,
                        ),
                      ),
                    ],
                    SizedBox(height: l.dp(10)),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _Pill2(
                              l: l,
                              label: product.model,
                              filled: false,
                              compact: true,
                              expandWidth: true,
                            ),
                          ),
                          SizedBox(width: l.dp(6)),
                          _Pill2(
                            l: l,
                            label: '${product.price.toStringAsFixed(0)} €',
                            filled: true,
                          ),
                          SizedBox(width: l.dp(6)),
                          StoreSelectButton(
                            tooltip: storeLabel,
                            onTap: onStoreSelect,
                            size: l.dp(30),
                            iconSize: l.dp(16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: l.dp(8)),
              ProductPhotoCircle(
                size: l.dp(92),
                photoUrl: product.photoUrl,
                showImage: available,
                onToggleVisibility: () => onAvailableChanged(!available),
                eyeSize: l.dp(28),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Pill2 extends StatelessWidget {
  final _Layout2 l;
  final String label;
  final bool filled;
  final bool compact;
  final bool expandWidth;

  const _Pill2({
    required this.l,
    required this.label,
    required this.filled,
    this.compact = false,
    this.expandWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expandWidth ? double.infinity : null,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: l.dp(compact ? 8 : 10),
        vertical: l.dp(compact ? 5 : 6),
      ),
      decoration: BoxDecoration(
        color: filled ? AppColors.primaryDark : const Color(0xFFF1F3F9),
        borderRadius: BorderRadius.circular(l.dp(20)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: l.sp(compact ? 10 : 11),
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : AppColors.primaryDark,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Grille overview v2 — cartes récap (réf, catégorie, segment, tailles…)
// UI     : Grille 2 colonnes sous hero — _OverviewCard2 par métadonnée produit.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _OverviewGrid2 extends StatelessWidget {
  final _Layout2 l;
  final Map<String, int> totals;
  final bool webMode;

  const _OverviewGrid2({
    required this.l,
    required this.totals,
    required this.webMode,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final items = webMode
        ? [
            _OverviewItem(
              label: l10n.dispoWeb,
              value: totals['dispo'] ?? 0,
              icon: Icons.language,
              color: AppColors.info,
            ),
          ]
        : [
            _OverviewItem(
              label: l10n.stockColumnLabel('dispo'),
              value: totals['dispo'] ?? 0,
              icon: Icons.inventory_2_outlined,
              color: AppColors.info,
            ),
            _OverviewItem(
              label: l10n.stockColumnLabel('transit'),
              value: totals['transit'] ?? 0,
              icon: Icons.local_shipping_outlined,
              color: AppColors.success,
            ),
            _OverviewItem(
              label: l10n.pickingShort,
              value: totals['picking'] ?? 0,
              icon: Icons.front_hand_outlined,
              color: AppColors.orange,
            ),
            _OverviewItem(
              label: l10n.stockColumnLabel('depot'),
              value: totals['depot'] ?? 0,
              icon: Icons.warehouse_outlined,
              color: _depotPurple,
            ),
          ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) SizedBox(width: l.dp(6)),
            Expanded(child: _OverviewCard2(l: l, item: items[i])),
          ],
        ],
      ),
    );
  }
}

class _OverviewItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _OverviewItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _OverviewCard2 extends StatelessWidget {
  final _Layout2 l;
  final _OverviewItem item;

  const _OverviewCard2({required this.l, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: l.dp(6), vertical: l.dp(8)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(l.dp(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: l.dp(8),
            offset: Offset(0, l.dp(3)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: l.dp(20),
                height: l.dp(20),
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.icon, size: l.dp(11), color: item.color),
              ),
              SizedBox(width: l.dp(4)),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: l.sp(8),
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: l.dp(4)),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${item.value}',
              maxLines: 1,
              style: TextStyle(
                fontSize: l.sp(18),
                fontWeight: FontWeight.w800,
                color: _stockAmountColor2(item.value),
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavPlaceholder2 extends StatelessWidget {
  final _Layout2 l;
  final String label;

  const _NavPlaceholder2({required this.l, required this.label});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(l.dp(24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(l.dp(16)),
      ),
      child: Column(
        children: [
          Icon(Icons.construction_outlined,
              size: l.dp(32), color: AppColors.textMuted),
          SizedBox(height: l.dp(8)),
          Text(
            label,
            style: TextStyle(
              fontSize: l.sp(14),
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: l.dp(4)),
          Text(
            l10n.comingSoon,
            style: TextStyle(fontSize: l.sp(12), color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tableau stock v2 — lignes taille colorées + métriques dynamiques
// UI     : Liste scrollable — une _SizeRow2 par taille, _MetricCell2 par colonne.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _SizeRow2 extends StatelessWidget {
  final _Layout2 l;
  final int rowIndex;
  final String size;
  final Map<String, int> line;
  final bool highlight;
  final bool webMode;

  const _SizeRow2({
    required this.l,
    required this.rowIndex,
    required this.size,
    required this.line,
    required this.highlight,
    required this.webMode,
  });

  int get _rowTotal {
    if (webMode) return line['dispo'] ?? 0;
    return (line['dispo'] ?? 0) +
        (line['transit'] ?? 0) +
        (line['picking'] ?? 0) +
        (line['depot'] ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final metrics = webMode
        ? [
            _MetricDef(
              l10n.stockColumnLabel('dispo'),
              line['dispo'] ?? 0,
              Icons.language,
              AppColors.info,
            ),
          ]
        : [
            _MetricDef(
              l10n.stockColumnLabel('dispo'),
              line['dispo'] ?? 0,
              Icons.inventory_2_outlined,
              AppColors.info,
            ),
            _MetricDef(
              l10n.stockColumnLabel('transit'),
              line['transit'] ?? 0,
              Icons.local_shipping_outlined,
              AppColors.success,
            ),
            _MetricDef(
              l10n.stockColumnLabel('picking'),
              line['picking'] ?? 0,
              Icons.front_hand_outlined,
              AppColors.orange,
            ),
            _MetricDef(
              l10n.stockColumnLabel('depot'),
              line['depot'] ?? 0,
              Icons.warehouse_outlined,
              _depotPurple,
            ),
          ];

    final rowColor = _sizeRowColors[rowIndex % _sizeRowColors.length];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(l.dp(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: l.dp(8),
            offset: Offset(0, l.dp(3)),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: l.dp(50),
              color: highlight ? AppColors.primary : rowColor,
              padding: EdgeInsets.symmetric(vertical: l.dp(10)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    size,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: l.sp(19),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: l.dp(2)),
                  Text(
                    l10n.totalCount(_rowTotal),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _rowTotal < 0
                          ? const Color(0xFFFFCDD2)
                          : Colors.white.withOpacity(0.9),
                      fontSize: l.sp(10),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  vertical: l.dp(8),
                  horizontal: l.dp(4),
                ),
                child: Row(
                  children: [
                    for (final m in metrics)
                      Expanded(child: _MetricCell2(l: l, metric: m)),
                    Icon(Icons.chevron_right,
                        size: l.dp(18), color: AppColors.textMuted),
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

class _MetricDef {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _MetricDef(this.label, this.value, this.icon, this.color);
}

class _MetricCell2 extends StatelessWidget {
  final _Layout2 l;
  final _MetricDef metric;

  const _MetricCell2({required this.l, required this.metric});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(metric.icon, size: l.dp(15), color: metric.color),
        SizedBox(height: l.dp(3)),
        Text(
          metric.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: l.sp(10), color: AppColors.textSecondary),
        ),
        Text(
          '${metric.value}',
          style: TextStyle(
            fontSize: l.sp(15),
            fontWeight: FontWeight.w800,
            color: _stockAmountColor2(metric.value),
          ),
        ),
        SizedBox(height: l.dp(4)),
        Container(
          height: l.dp(3),
          margin: EdgeInsets.symmetric(horizontal: l.dp(3)),
          decoration: BoxDecoration(
            color: metric.color.withOpacity(0.35),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation bas v2 — 5 onglets (Stock Mag, Web, Alentours, Avis, Réserve)
// UI     : bottomNavigationBar — même structure que _BottomNav v1.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _BottomNav2 extends StatelessWidget {
  final _Layout2 l;
  final int index;
  final ValueChanged<int> onChanged;

  const _BottomNav2({
    required this.l,
    required this.index,
    required this.onChanged,
  });

  static const _icons = [
    Icons.inventory_2_outlined,
    Icons.language,
    Icons.place_outlined,
    Icons.star_outline,
    Icons.bookmark_border,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final labels = [
      l10n.navStockMag,
      l10n.navStockWeb,
      l10n.navNearby,
      l10n.navReviews,
      l10n.navReserve,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: l.dp(12),
            offset: Offset(0, -l.dp(2)),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: l.dp(8),
        bottom: MediaQuery.paddingOf(context).bottom + l.dp(6),
      ),
      child: Row(
        children: List.generate(_icons.length, (i) {
          final selected = i == index;
          return Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onChanged(i);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      horizontal: l.dp(8),
                      vertical: l.dp(5),
                    ),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primarySoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(l.dp(16)),
                    ),
                    child: Icon(
                      _icons[i],
                      color: selected ? AppColors.primaryDark : AppColors.textMuted,
                      size: l.dp(20),
                    ),
                  ),
                  SizedBox(height: l.dp(3)),
                  Text(
                    labels[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? AppColors.primaryDark : AppColors.textSecondary,
                      fontSize: l.sp(10),
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
