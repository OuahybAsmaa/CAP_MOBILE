// =============================================================================
// CapMobile — Module Swapp — Page Produit v1 (DetailProduitPage)
// -----------------------------------------------------------------------------
// Fonctionnalité : Fiche produit magasin — stock par taille, stock web, avis,
//                  scan QR / DataWedge, sélection magasin, i18n FR/EN/NL.
// Design         : Layout responsive Zebra TC53E ; carte hero + tableau stock ;
//                  barre nav 5 onglets ; thème bleu AppColors.
// UI             : Scaffold Column → [_TopBar | _HeaderDivider | Expanded contenu |
//                  _BottomNav] ; contenu = bannière erreur + _ProductHeroCard +
//                  _buildTabBody (tableau / avis / placeholder).
// Spécifications : Riverpod swappProductProvider + stockWebProvider ;
//                  codeMag sélectionnable ; widgets extraits dans lib/swapp/widgets.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'dart:io';

import 'package:cap_mobile/core/api/api_constants.dart';
import 'package:cap_mobile/core/l10n/app_localizations.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/core/l10n/language_menu_button.dart';
import 'package:cap_mobile/core/apiswap/produit/nearby_stock/providers/nearby_stock_provider.dart';
import 'package:cap_mobile/core/apiswap/produit/reviews/providers/product_review_provider.dart';
import 'package:cap_mobile/core/apiswap/models/product_review_item.dart';
import 'package:cap_mobile/core/apiswap/produit/stock_web/providers/stock_web_provider.dart';
import 'package:cap_mobile/core/apiswap/shared/config/swapp_api_constants.dart';
import 'package:cap_mobile/core/apiswap/produit/providers/swapp_product_provider.dart';
import 'package:cap_mobile/core/apiswap/produit/data/product_test_data.dart';
import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/core/widgets/photo_annotation_editor.dart';
import 'package:cap_mobile/features/article/providers/article_provider.dart';
import 'package:cap_mobile/swapp/models/product_stock_view.dart';
import 'package:cap_mobile/swapp/models/stock_column.dart';
import 'package:cap_mobile/swapp/pages/produit/reserve_produit_page.dart';
import 'package:cap_mobile/swapp/pages/client/client_search_page.dart';
import 'package:cap_mobile/swapp/utils/swapp_scan_flow.dart';
import 'package:cap_mobile/features/auth/providers/auth_provider.dart';
import 'package:cap_mobile/swapp/widgets/article_code_dialog.dart';
import 'package:cap_mobile/swapp/widgets/reassort_chip.dart';
import 'package:cap_mobile/swapp/widgets/colis_depot_chips.dart';
import 'package:cap_mobile/swapp/widgets/product_photo_circle.dart';
import 'package:cap_mobile/swapp/widgets/store_picker_dialog.dart';
import 'package:cap_mobile/swapp/widgets/store_select_button.dart';
import 'package:cap_mobile/swapp/widgets/ranger_panel.dart';
import 'package:cap_mobile/swapp/widgets/qr_camera_scanner_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

const String _monoFamily = 'monospace';
const String _condensedFamily = 'sans-serif-condensed';

/// UI : Couleur chiffre stock — 0 bleu, >0 vert foncé, <0 rouge.
Color _stockAmountColor(int value) {
  if (value < 0) return AppColors.error;
  if (value == 0) return AppColors.primary;
  return const Color(0xFF047857);
}

Color _stockAmountBorderColor(int value) {
  if (value < 0) return AppColors.error;
  if (value == 0) return AppColors.primary.withValues(alpha: 0.45);
  return const Color(0xFF047857).withValues(alpha: 0.55);
}

Color _stockAmountBackgroundColor(int value) {
  if (value < 0) return AppColors.error.withValues(alpha: 0.12);
  if (value == 0) return AppColors.primarySoft.withValues(alpha: 0.65);
  return const Color(0xFFD1FAE5).withValues(alpha: 0.85);
}

/// Mise à l'échelle responsive — optimisé Zebra TC53E (~360×720 logical, 6").
/// Chaque getter alimente une zone UI concrète de l'écran produit v1.
class _ProduitLayout {
  _ProduitLayout(BuildContext context)
    : width = MediaQuery.sizeOf(context).width,
      height = MediaQuery.sizeOf(context).height,
      padding = MediaQuery.paddingOf(context),
      scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.4);

  final double width;
  final double height;
  final EdgeInsets padding;
  final double scale;

  double dp(double v) => v * scale;
  double sp(double v) => v * scale;

  /// UI : mode compact si écran étroit — réduit polices hero card.
  bool get compact => width < 340;
  bool get tallScreen => height / width > 1.9;

  /// UI : marges internes du corps (_buildContent Padding).
  EdgeInsets get pagePadding =>
      EdgeInsets.fromLTRB(dp(12), dp(8), dp(12), dp(10));

  /// UI : taille minimale zones tactiles (accessibilité).
  double get minTouch => dp(44).clamp(40.0, 50.0);

  /// UI : diamètre boutons _CompactToolbar (grille, NFC, QR).
  double get toolbarBtn => dp(36).clamp(32.0, 42.0);
  double get toolBtn => minTouch;

  /// UI : côté carré ProductPhotoCircle (colonne droite hero card).
  double get thumbSize => compact ? dp(72) : dp(88).clamp(76.0, 104.0);

  /// UI : rayon coins _ProductHeroCard et panneaux.
  double get cardRadius => dp(14);
  double get statRadius => dp(10);

  /// UI : hauteur barre _BottomNav (5 onglets bas écran).
  double get bottomNavH => dp(52).clamp(48.0, 58.0);

  /// UI : largeur colonne _StockTable / _ValueCircle (répartie égale).
  double stockColumnWidth(double tableWidth, int columnCount) {
    if (columnCount <= 0) return tableWidth;
    return tableWidth / columnCount;
  }
}

/// Écran principal Swapp v1 — point d'entrée depuis HomePage.
class DetailProduitPage extends ConsumerStatefulWidget {
  const DetailProduitPage({super.key, this.loadDefaultProduct = true});

  /// False lorsque le produit vient d'etre charge par l'ecran de scan.
  final bool loadDefaultProduct;

  /// Route fade-in vers la fiche détail produit v1 (Infos Stocks…).
  static Route<void> fadeRoute({bool loadDefaultProduct = true}) => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => DetailProduitPage(
      loadDefaultProduct: loadDefaultProduct,
    ),
    transitionsBuilder: (_, anim, _, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 300),
  );

  @override
  ConsumerState<DetailProduitPage> createState() => _DetailProduitPageState();
}

class _DetailProduitPageState extends ConsumerState<DetailProduitPage> {
  final _dataWedge = SwappDataWedgeListener();

  /// UI → ProductPhotoCircle.showImage (bouton œil masque/affiche la photo).
  bool _available = true;

  /// UI → _BottomNav index ; 0=Stock Mag, 1=Web, 2=Alentours, 3=Avis, 4=Réserve.
  int _navIndex = 0;

  /// UI → RangerPanel remplace le corps (_buildTabBody) si true.
  bool _showRangerPanel = false;

  /// Colis dépôt déjà libérés (session courante, par produit).
  final Set<String> _releasedColisIds = {};
  String? _colisSessionRef;

  /// UI → magasin de référence (auth) pour Stock Mag et API alentours.
  int _referenceCodeMag = SwappApiConstants.defaultCodeMag;

  int get _nearbyReferenceCodeMag => SwappApiConstants.resolveCodeMagFromCollab(
    ref.read(authProvider).collaborateur,
    fallback: _referenceCodeMag,
  );

  int get _referenceCodeMagFromAuth => _nearbyReferenceCodeMag;

  String _articleCodeForNearby(ProductStockView product) {
    final lastScan = ref.read(swappProductProvider).lastScannedGencode;
    if (lastScan != null &&
        lastScan.isNotEmpty &&
        _looksLikeGencode(lastScan)) {
      return lastScan;
    }
    if (_looksLikeGencode(product.gencode)) return product.gencode;

    final article = ref.read(articleProvider).article;
    final scanned = article?.gencode.trim();
    if (scanned != null && scanned.isNotEmpty && _looksLikeGencode(scanned)) {
      final codeMod = article?.codeMod ?? '';
      if (codeMod.isEmpty ||
          codeMod == product.reference ||
          codeMod == product.gencode) {
        return scanned;
      }
    }

    if (_looksLikeGencode(product.reference)) return product.reference;
    if (product.gencode.isNotEmpty) return product.gencode;
    return product.reference;
  }

  bool _looksLikeGencode(String code) {
    final trimmed = code.trim();
    return trimmed.length >= 13 && RegExp(r'^\d+$').hasMatch(trimmed);
  }

  Future<void> _pickNearbyStore() async {
    final nearbyState = ref.read(nearbyStockProvider);
    if (nearbyState.stores.isEmpty) return;

    final selected =
        nearbyState.selectedCodeMag ?? nearbyState.stores.first.codeMag;
    final picked = await showNearbyStorePickerDialog(
      context: context,
      stores: nearbyState.stores,
      selectedCodeMag: selected,
    );
    if (!mounted || picked == null) return;
    ref.read(nearbyStockProvider.notifier).selectStore(picked);
  }

  String _nearbyStoreLabel(NearbyStockState nearbyState) {
    final store = nearbyState.selectedStore;
    if (store == null) return context.l10n.selectStoreTitle;
    return store.nomMag;
  }

  List<ColisDepotChip> _pendingColisChips(ProductStockView product) {
    if (_colisSessionRef != product.reference) {
      _colisSessionRef = product.reference;
      _releasedColisIds.clear();
    }
    return product.colisDepotChips
        .where((c) => !_releasedColisIds.contains(c.id))
        .toList();
  }

  Future<void> _openColisPopup(
    ProductStockView product,
    _ProduitLayout layout,
  ) async {
    final pending = _pendingColisChips(product);
    if (pending.isEmpty || !mounted) return;
    await showColisDepotPopup(
      context: context,
      chips: pending,
      dp: layout.dp,
      sp: layout.sp,
      onReleased: (id) => setState(() => _releasedColisIds.add(id)),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final collab = ref.read(authProvider).collaborateur;
      setState(
        () => _referenceCodeMag = SwappApiConstants.resolveCodeMagFromCollab(
          collab,
        ),
      );
      _initDataWedge();
      if (widget.loadDefaultProduct) {
        _loadDefaultProduct();
      }
    });
  }

  Future<void> _loadDefaultProduct() async {
    await ref
        .read(swappProductProvider.notifier)
        .fetchModele(
          codeModele: SwappApiConstants.defaultCodeModele,
          codeMag: _referenceCodeMag,
        );
    _fetchStockWebForProduct(SwappApiConstants.defaultCodeModele);
  }

  void _fetchStockWebForProduct(String codeModele) {
    ref.read(stockWebProvider.notifier).fetchStockWeb(codeModele);
  }

  void _fetchNearbyForProduct(ProductStockView product, {bool force = false}) {
    ref
        .read(nearbyStockProvider.notifier)
        .fetchNearbyStock(
          codeArticle: _articleCodeForNearby(product),
          codeMag: _nearbyReferenceCodeMag,
          force: force,
        );
  }

  int get _codeCollab =>
      ref.read(authProvider).collaborateur?.codeCollab ?? 0;

  void _fetchReviewsForProduct(ProductStockView product, {bool force = false}) {
    ref
        .read(productReviewProvider.notifier)
        .fetchReviews(
          codeArticle: _articleCodeForNearby(product),
          codeCollab: _codeCollab,
          force: force,
        );
  }

  void _afterProductScan() {
    if (!mounted) return;
    final product = ref.read(swappProductProvider).product;
    if (product == null) return;
    if (_navIndex == 1) {
      _fetchStockWebForProduct(product.reference);
    } else if (_navIndex == 2) {
      _fetchNearbyForProduct(product, force: true);
    } else if (_navIndex == 3) {
      _fetchReviewsForProduct(product, force: true);
    }
  }

  Future<void> _processScan(String code) async {
    await processSwappProductScanUi(
      context: context,
      ref: ref,
      code: code,
      codeMag: _nearbyReferenceCodeMag,
      onProductLoaded: _afterProductScan,
    );
  }

  Future<void> _initDataWedge() async {
    await _dataWedge.start(ref: ref, onScan: _processScan);
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

  @override
  Widget build(BuildContext context) {
    // UI — Assemble l'écran : barre haut, corps scrollable, nav bas.
    final swappState = ref.watch(swappProductProvider);
    final stockWebState = ref.watch(stockWebProvider);
    final nearbyState = ref.watch(nearbyStockProvider);
    final layout = _ProduitLayout(context);
    final product = _resolveProduct(swappState);
    final isInitialMagLoad = swappState.isLoading && swappState.product == null;
    final isInitialWebLoad =
        stockWebState.isLoading && stockWebState.stockBySize.isEmpty;
    final showLoader =
        (_navIndex == 0 && isInitialMagLoad) ||
        (_navIndex == 1 && isInitialWebLoad);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            _TopBar(
              layout: layout,
              onBack: () => Navigator.pop(context),
              // UI : Navigation fade vers ClientSearchPage (icône bonhomme header).
              onClientSearch: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, _, _) => const ClientSearchPage(),
                    transitionsBuilder: (_, anim, _, child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 300),
                  ),
                );
              },
            ),
            _HeaderDivider(layout: layout),
            Expanded(
              child: showLoader
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContent(
                      product,
                      layout,
                      swappState.error,
                      stockWebState,
                      nearbyState,
                    ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          layout: layout,
          index: _navIndex,
          onChanged: (i) {
            if (i == 4) {
              _openReservePage(product);
              return;
            }
            setState(() {
              _navIndex = i;
              _showRangerPanel = false;
            });
            if (i == 1) {
              _fetchStockWebForProduct(product.reference);
            } else if (i == 2) {
              _fetchNearbyForProduct(product);
            } else if (i == 3) {
              _fetchReviewsForProduct(product);
            }
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    ProductStockView product,
    _ProduitLayout layout,
    String? magError,
    StockWebState stockWebState,
    NearbyStockState nearbyState,
  ) {
    final tableError = switch (_navIndex) {
      1 => stockWebState.error,
      2 => nearbyState.error,
      0 => magError,
      _ => null,
    };

    return Padding(
      padding: layout.pagePadding,
      child: Column(
        children: [
          if (tableError != null) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(layout.dp(10)),
              margin: EdgeInsets.only(bottom: layout.dp(8)),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(layout.dp(8)),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                tableError,
                style: TextStyle(
                  fontSize: layout.sp(12),
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          _ProductHeroCard(
            layout: layout,
            product: product,
            available: _available,
            onAvailableChanged: (v) => setState(() => _available = v),
            onArticleSearch: _showArticleCodeDialog,
            onQrScan: _openQrScanner,
            onPlusProduitTap: () {
              setState(() => _showRangerPanel = !_showRangerPanel);
            },
            plusProduitActive: _showRangerPanel,
            showStoreSelect: _navIndex == 2,
            storeLabel: _navIndex == 2 ? _nearbyStoreLabel(nearbyState) : null,
            onStoreSelect: _navIndex == 2 ? _pickNearbyStore : null,
            showColisButton: _navIndex == 0,
            pendingColisCount: _navIndex == 0
                ? _pendingColisChips(product).length
                : 0,
            onColisPackTap: () => _openColisPopup(product, layout),
          ),
          SizedBox(height: layout.dp(10)),
          Expanded(
            child: _showRangerPanel
                ? RangerPanel(dp: layout.dp, sp: layout.sp)
                : _buildTabBody(product, layout, stockWebState, nearbyState),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody(
    ProductStockView product,
    _ProduitLayout layout,
    StockWebState stockWebState,
    NearbyStockState nearbyState,
  ) {
    // UI — Contenu zone Expanded selon onglet _BottomNav actif.
    switch (_navIndex) {
      case 0:
        return _StockTable(layout: layout, product: product);
      case 1:
        return _StockTable(
          layout: layout,
          product: product,
          stockBySize: stockWebState.stockBySize,
          columns: StockColumns.web,
        );
      case 2:
        return _NearbyStockPanel(
          layout: layout,
          product: product,
          nearbyState: nearbyState,
        );
      case 3:
        return _AvisPanel(
          layout: layout,
          product: product,
          codeArticle: _articleCodeForNearby(product),
          codeCollab: _codeCollab,
        );
      case 4:
        return _TabPlaceholderPanel(
          layout: layout,
          icon: Icons.inventory_2_outlined,
          title: context.l10n.navReserve,
        );
      default:
        return _StockTable(layout: layout, product: product);
    }
  }

  ProductStockView _resolveProduct(SwappProductState state) {
    var product = state.product ?? demoProductStockView();
    final article = ref.read(articleProvider).article;
    final articlePlus = article?.libPlusProduit?.trim();
    if ((product.libPlusProduit == null ||
            product.libPlusProduit!.trim().isEmpty) &&
        articlePlus != null &&
        articlePlus.isNotEmpty) {
      product = product.copyWith(libPlusProduit: articlePlus);
    }
    return product;
  }

  Future<void> _openReservePage(ProductStockView product) async {
    await Navigator.push<void>(
      context,
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, _, _) => ReserveProduitPage(product: product),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Future<void> _showArticleCodeDialog() async {
    if (!mounted) return;

    final swapp = ref.read(swappProductProvider);
    final product = swapp.product;
    final currentCode = swapp.lastScannedGencode?.isNotEmpty == true
        ? swapp.lastScannedGencode!
        : (product?.gencode.isNotEmpty == true
              ? product!.gencode
              : product?.reference ?? SwappApiConstants.defaultCodeModele);

    final code = await showArticleCodeDialog(context, initialCode: currentCode);

    if (!mounted || code == null || code.isEmpty) return;

    await ref
        .read(swappProductProvider.notifier)
        .fetchModele(
          codeModele: code,
          codeMag: _referenceCodeMag,
          scannedGencode: _looksLikeGencode(code) ? code : null,
        );
    _fetchStockWebForProduct(code);
    if (_navIndex == 2) {
      ref.read(nearbyStockProvider.notifier).clear();
      _fetchNearbyForProduct(
        ref.read(swappProductProvider).product ?? demoProductStockView(),
      );
    } else if (_navIndex == 3) {
      ref.read(productReviewProvider.notifier).clear();
      final loadedProduct = ref.read(swappProductProvider).product;
      if (loadedProduct != null) {
        _fetchReviewsForProduct(loadedProduct, force: true);
      }
    }
  }
}

// ---------------------------------------------------------------------------
// En-tête page — titre PRODUIT, retour, langue, clients, panier, menu
// UI     : Barre fixe tout en haut (AppBar-like) — fond primaryDark ;
//          person_outline → ClientSearchPage (recherche / liste clients).
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  final _ProduitLayout layout;
  final VoidCallback onBack;
  final VoidCallback? onClientSearch;

  const _TopBar({
    required this.layout,
    required this.onBack,
    this.onClientSearch,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final l10n = context.l10n;

    return Container(
      color: AppColors.primaryDark,
      padding: EdgeInsets.only(
        top: top,
        left: 0,
        right: 0,
        bottom: layout.dp(4),
      ),
      child: Row(
        children: [
          _IconTap(
            size: layout.minTouch,
            onTap: onBack,
            child: Icon(
              Icons.arrow_back,
              color: AppColors.white,
              size: layout.dp(22),
            ),
          ),
          SizedBox(width: layout.dp(4)),
          Text(
            l10n.productTitle,
            style: TextStyle(
              color: AppColors.white,
              fontFamily: _condensedFamily,
              fontSize: layout.sp(21),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const Spacer(),
          LanguageMenuButton(
            iconSize: layout.dp(22),
            iconColor: AppColors.white.withValues(alpha: 0.85),
          ),
          // UI : Accès module Swapp — recherche / liste clients (ClientSearchPage).
          _IconTap(
            size: layout.minTouch,
            onTap: onClientSearch ?? () {},
            child: Icon(
              Icons.person_outline,
              color: AppColors.white.withValues(alpha: 0.7),
              size: layout.dp(22),
            ),
          ),
          _IconTap(
            size: layout.minTouch,
            onTap: () {},
            child: Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.white.withValues(alpha: 0.7),
              size: layout.dp(22),
            ),
          ),
          _IconTap(
            size: layout.minTouch,
            onTap: () {},
            child: Icon(
              Icons.more_vert,
              color: AppColors.white.withValues(alpha: 0.7),
              size: layout.dp(22),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Zone tap icône — InkWell carré pour boutons header / toolbar
// UI     : Zone tactile invisible autour icônes _TopBar et _ToolButton.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _IconTap extends StatelessWidget {
  final double size;
  final VoidCallback onTap;
  final Widget child;

  const _IconTap({
    required this.size,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Séparateur horizontal sous l'en-tête page.
/// UI : Fine ligne grise entre _TopBar et corps scrollable.
class _HeaderDivider extends StatelessWidget {
  final _ProduitLayout layout;

  const _HeaderDivider({required this.layout});

  @override
  Widget build(BuildContext context) {
    return Container(height: layout.dp(4), color: AppColors.primaryDark);
  }
}

// ---------------------------------------------------------------------------
// Tableau stock — une ligne par taille, colonnes métriques dynamiques
// UI     : Zone Expanded sous hero card — onglets Stock Mag (0) / Stock Web (1).
// Design : cercles colorés par rubrique ; ligne totaux en en-tête.
// Spec   : Mode mag (toutes colonnes visibles) ou web (Taille + Dispo).
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _StockTable extends StatelessWidget {
  final _ProduitLayout layout;
  final ProductStockView product;
  final Map<String, Map<String, int>>? stockBySize;
  final List<StockColumnDef>? columns;

  const _StockTable({
    required this.layout,
    required this.product,
    this.stockBySize,
    this.columns,
  });

  Map<String, Map<String, int>> get _stockBySize =>
      stockBySize ?? product.stockBySize;

  List<StockColumnDef> get _columns => columns ?? product.visibleStockColumns;

  Map<String, int> get _totals {
    final totals = {for (final column in _columns) column.key: 0};
    if (totals.containsKey(StockColumns.taille.key)) {
      totals.remove(StockColumns.taille.key);
    }
    for (final line in _stockBySize.values) {
      for (final entry in line.entries) {
        totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
      }
    }
    return totals;
  }

  List<String> _sizesFromRange() {
    if (_stockBySize.isNotEmpty) {
      return _stockBySize.keys.toList()..sort((a, b) {
        final ai = int.tryParse(a);
        final bi = int.tryParse(b);
        if (ai != null && bi != null) return ai.compareTo(bi);
        return a.compareTo(b);
      });
    }

    final match = RegExp(
      r'(\d+)\s*au\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(product.sizeRange);
    if (match != null) {
      final from = int.parse(match.group(1)!);
      final to = int.parse(match.group(2)!);
      if (to >= from && to - from <= 20) {
        return [for (var i = from; i <= to; i++) '$i'];
      }
    }
    if (product.size.isNotEmpty) return [product.size];
    return ['—'];
  }

  @override
  Widget build(BuildContext context) {
    final sizes = _sizesFromRange();
    final tableColumns = _columns;
    final totals = _totals;
    final l10n = context.l10n;

    final summaryCells = tableColumns.map((column) {
      if (column.key == StockColumns.taille.key) return 'Σ';
      return '${totals[column.key] ?? 0}';
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final colW = layout.stockColumnWidth(
          constraints.maxWidth,
          tableColumns.length,
        );

        return Container(
          width: double.infinity,
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(layout.dp(12)),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.05),
                blurRadius: layout.dp(8),
                offset: Offset(0, layout.dp(2)),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ColoredBox(
                color: AppColors.bg.withValues(alpha: 0.35),
                child: _StockTableRow(
                  layout: layout,
                  columns: tableColumns,
                  columnWidth: colW,
                  cells: tableColumns
                      .map((c) => l10n.stockColumnLabel(c.key))
                      .toList(),
                  isHeader: true,
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              _StockTableRow(
                layout: layout,
                columns: tableColumns,
                columnWidth: colW,
                cells: summaryCells,
                isSummary: true,
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
              Expanded(
                child: Column(
                  children: sizes.asMap().entries.map((entry) {
                    final line = _stockBySize[entry.value] ?? const {};
                    final cells = tableColumns.map((column) {
                      if (column.key == StockColumns.taille.key) {
                        return entry.value;
                      }
                      return '${line[column.key] ?? 0}';
                    }).toList();
                    return Expanded(
                      child: _StockTableRow(
                        layout: layout,
                        columns: tableColumns,
                        columnWidth: colW,
                        cells: cells,
                        isSizeRow: true,
                        rowIndex: entry.key,
                        highlightSize: entry.value == product.size,
                        expandVertically: true,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StockTableRow extends StatelessWidget {
  final _ProduitLayout layout;
  final List<StockColumnDef> columns;
  final double columnWidth;
  final List<String> cells;
  final bool isHeader;
  final bool isSummary;
  final bool isSizeRow;
  final int rowIndex;
  final bool highlightSize;
  final bool expandVertically;

  const _StockTableRow({
    required this.layout,
    required this.columns,
    required this.columnWidth,
    required this.cells,
    this.isHeader = false,
    this.isSummary = false,
    this.isSizeRow = false,
    this.rowIndex = 0,
    this.highlightSize = false,
    this.expandVertically = false,
  });

  Color _colorAt(int i) => columns[i].color;

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.transparent;
    if (isSummary) {
      bg = AppColors.primarySoft.withValues(alpha: 0.55);
    } else if (isSizeRow) {
      bg = rowIndex.isEven
          ? Colors.transparent
          : AppColors.bg.withValues(alpha: 0.65);
    }

    final content = Padding(
      padding: EdgeInsets.symmetric(
        vertical: expandVertically
            ? 0
            : isHeader
            ? layout.dp(6)
            : isSizeRow
            ? layout.dp(3)
            : layout.dp(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(cells.length, (i) {
          final label = cells[i];
          final isTailleColumn = columns[i].key == StockColumns.taille.key;

          if (isSummary && isTailleColumn && label == 'Σ') {
            return Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: layout.dp(10)),
                  child: Text(
                    'Σ',
                    style: TextStyle(
                      fontFamily: _monoFamily,
                      fontSize: layout.sp(18),
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                      height: 1,
                    ),
                  ),
                ),
              ),
            );
          }

          return Expanded(
            child: isHeader
                ? _headerCell(columns[i], label)
                : Center(
                    child: _ValueCircle(
                      layout: layout,
                      value: label,
                      color: _colorAt(i),
                      maxSize: columnWidth * 0.84,
                      isSize: isSizeRow && isTailleColumn,
                      isSummary: isSummary,
                      highlighted: highlightSize && isTailleColumn,
                    ),
                  ),
          );
        }),
      ),
    );

    return ColoredBox(
      color: bg,
      child: expandVertically ? Center(child: content) : content,
    );
  }

  Widget _headerCell(StockColumnDef column, String label) {
    final badgeSize = (columnWidth * 0.68).clamp(layout.dp(18), layout.dp(23));

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: column.color,
                shape: BoxShape.circle,
              ),
              child: Icon(
                column.icon,
                size: badgeSize * 0.54,
                color: AppColors.white,
              ),
            ),
            SizedBox(height: layout.dp(2)),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontSize: layout.sp(11),
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                height: 1.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cercle valeur stock — chiffre dans pastille colorée (taille ou métrique)
// UI     : Cellule _StockTableRow — cercle coloré par StockColumnDef.color.
// Design : taille récap plus grande ; highlight si valeur > 0.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _ValueCircle extends StatelessWidget {
  final _ProduitLayout layout;
  final String value;
  final Color color;
  final double maxSize;
  final bool isSize;
  final bool isSummary;
  final bool highlighted;

  const _ValueCircle({
    required this.layout,
    required this.value,
    required this.color,
    required this.maxSize,
    this.isSize = false,
    this.isSummary = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cap = isSummary
        ? layout.dp(32)
        : isSize
        ? layout.dp(30)
        : layout.dp(28);
    final fillRatio = isSummary
        ? 0.76
        : isSize
        ? 0.74
        : 0.72;
    final size = (maxSize * fillRatio).clamp(layout.dp(22), cap);
    final fontSize = (size * 0.4).clamp(layout.sp(11), layout.sp(14));

    final numericValue = isSize ? null : int.tryParse(value.trim());
    final isNegative = numericValue != null && numericValue < 0;
    final isStockAmount = numericValue != null && !isSize;

    final bg = isStockAmount
        ? _stockAmountBackgroundColor(numericValue)
        : isNegative
        ? AppColors.error.withValues(alpha: 0.12)
        : highlighted
        ? color.withValues(alpha: 0.22)
        : isSize
        ? color.withValues(alpha: 0.14)
        : isSummary
        ? AppColors.white
        : AppColors.surface;

    final borderColor = isStockAmount
        ? _stockAmountBorderColor(numericValue)
        : isNegative
        ? AppColors.error
        : highlighted
        ? color
        : color.withValues(alpha: isSize ? 0.45 : 0.3);

    final textColor = isStockAmount
        ? _stockAmountColor(numericValue)
        : isNegative
        ? AppColors.error
        : highlighted || isSummary
        ? color
        : AppColors.primaryDark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: bg,
        border: Border.all(color: borderColor, width: highlighted ? 1.5 : 1),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          maxLines: 1,
          style: TextStyle(
            fontFamily: _monoFamily,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bouton circulaire toolbar — icône colorée (grille, ranger, NFC, QR)
// UI     : Cercle coloré dans _CompactToolbar — même taille / style pour tous.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _ToolButton extends StatelessWidget {
  final _ProduitLayout layout;
  final IconData icon;
  final Color color;
  final double? size;
  final VoidCallback? onTap;
  final bool highlighted;

  const _ToolButton({
    required this.layout,
    required this.icon,
    required this.color,
    this.size,
    this.onTap,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final btnSize = size ?? layout.toolBtn;
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: color,
        elevation: highlighted ? 4 : 0,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled
              ? () {
                  HapticFeedback.selectionClick();
                  onTap!.call();
                }
              : null,
          child: SizedBox(
            width: btnSize,
            height: btnSize,
            child: Icon(icon, color: AppColors.white, size: layout.dp(17)),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte produit hero — réassort, infos, prix, magasin, photo, 3 boutons action
// UI     : Carte blanche sous header — L1 [ReassortChip | Toolbar] ;
//          L1 [réf · colorway · taille] ; L2 plage · catégorie ; L3 segment ;
//          L4 [Pill modèle | Pill prix | StoreSelect].
// Design : chip réassort + toolbar ; pastilles prix/modèle ; photo carré arrondi.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _ProductHeroCard extends StatelessWidget {
  final _ProduitLayout layout;
  final ProductStockView product;
  final bool available;
  final ValueChanged<bool> onAvailableChanged;
  final VoidCallback onArticleSearch;
  final VoidCallback onQrScan;
  final VoidCallback onPlusProduitTap;
  final bool plusProduitActive;
  final bool showStoreSelect;
  final String? storeLabel;
  final VoidCallback? onStoreSelect;
  final int pendingColisCount;
  final VoidCallback onColisPackTap;
  final bool showColisButton;

  const _ProductHeroCard({
    required this.layout,
    required this.product,
    required this.available,
    required this.onAvailableChanged,
    required this.onArticleSearch,
    required this.onQrScan,
    required this.onPlusProduitTap,
    this.plusProduitActive = false,
    this.showStoreSelect = false,
    this.storeLabel,
    this.onStoreSelect,
    this.pendingColisCount = 0,
    required this.onColisPackTap,
    this.showColisButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.05),
            blurRadius: layout.dp(12),
            offset: Offset(0, layout.dp(4)),
          ),
        ],
      ),
      padding: EdgeInsets.all(layout.dp(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: ReassortChip(
                  ok: product.reassortOk,
                  dp: layout.dp,
                  sp: layout.sp,
                ),
              ),
              SizedBox(width: layout.dp(4)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: _CompactToolbar(
                  layout: layout,
                  onArticleSearch: onArticleSearch,
                  onQrScan: onQrScan,
                  onPlusProduitTap: onPlusProduitTap,
                  plusProduitActive: plusProduitActive,
                ),
              ),
            ],
          ),
          if (_hasPlusProduit) ...[
            SizedBox(height: layout.dp(4)),
            _PlusProduitLine(
              layout: layout,
              libPlusProduit: product.libPlusProduit!.trim(),
            ),
          ],
          SizedBox(height: layout.dp(_hasPlusProduit ? 4 : 6)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _buildInfoLines(l10n),
                ),
              ),
              SizedBox(width: layout.dp(6)),
              _buildThumbColumn(),
            ],
          ),
        ],
      ),
    );
  }

  bool get _hasPlusProduit {
    final value = product.libPlusProduit?.trim();
    return value != null && value.isNotEmpty;
  }

  Widget _buildThumbColumn() {
    // Photo produit — taille œil : eyeSize (position dans product_photo_circle.dart).
    return ProductPhotoCircle(
      size: layout.thumbSize,
      photoUrl: product.photoUrl,
      showImage: available,
      onToggleVisibility: () => onAvailableChanged(!available),
      eyeSize: layout.dp(28),
    );
  }

  List<Widget> _buildInfoLines(AppLocalizations l10n) {
    return [
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          '${product.reference}  ${l10n.displayColorway(product.colorway)}  ${l10n.displaySizeLabel(product.size)}',
          maxLines: 1,
          style: TextStyle(
            fontFamily: _monoFamily,
            fontSize: layout.sp(layout.compact ? 12 : 13),
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
      ),
      SizedBox(height: layout.dp(3)),
      Text(
        '${l10n.displaySizeOrRange(product.sizeRange)} · ${l10n.displayCategory(product.category)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: layout.sp(12),
          fontWeight: FontWeight.w600,
          color: AppColors.orange,
          height: 1.2,
        ),
      ),
      if (product.segment.isNotEmpty) ...[
        SizedBox(height: layout.dp(2)),
        Text(
          l10n.displaySegment(product.segment),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: layout.sp(11),
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            height: 1.2,
          ),
        ),
      ],
      SizedBox(height: layout.dp(6)),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _Pill(
              layout: layout,
              text: product.model,
              filled: false,
              compact: true,
              expandWidth: true,
            ),
          ),
          SizedBox(width: layout.dp(6)),
          _Pill(
            layout: layout,
            text: '${product.price.toStringAsFixed(0)}€',
            filled: true,
          ),
          SizedBox(width: layout.dp(6)),
          ColisDepotPackButton(
            pendingCount: pendingColisCount,
            dp: layout.dp,
            sp: layout.sp,
            visible: showColisButton,
            onTap: onColisPackTap,
          ),
          if (showStoreSelect) ...[
            SizedBox(width: layout.dp(6)),
            StoreSelectButton(
              tooltip: storeLabel ?? '',
              onTap: onStoreSelect ?? () {},
              size: layout.dp(30),
              iconSize: layout.dp(16),
            ),
          ],
        ],
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Ligne PlusP hero — libPlusProduit API entre réassort et code article
// UI     : Petit libellé vert « PlusP: » + valeur orange sous la toolbar.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _PlusProduitLine extends StatelessWidget {
  final _ProduitLayout layout;
  final String libPlusProduit;

  const _PlusProduitLine({required this.layout, required this.libPlusProduit});

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: layout.sp(10),
          height: 1.25,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(
            text: 'PlusP:',
            style: TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: ' $libPlusProduit',
            style: TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar compacte — 4 boutons action (grille rouge, ranger vert, NFC, QR)
// UI     : Row en haut à droite hero card — à côté du ReassortChip.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
/// Barre d'actions : code article, ranger (PlusP), NFC, scan QR caméra.
class _CompactToolbar extends StatelessWidget {
  final _ProduitLayout layout;
  final bool compact;
  final VoidCallback onArticleSearch;
  final VoidCallback onQrScan;
  final VoidCallback onPlusProduitTap;
  final bool plusProduitActive;

  const _CompactToolbar({
    required this.layout,
    required this.onArticleSearch,
    required this.onQrScan,
    required this.onPlusProduitTap,
    this.plusProduitActive = false,
  }) : compact = false;

  @override
  Widget build(BuildContext context) {
    final s = layout.toolbarBtn;
    final gap = layout.dp(8);
    final buttons =
        <({IconData icon, Color color, VoidCallback? onTap, bool active})>[
          (
            icon: Icons.apps_rounded,
            color: AppColors.error,
            onTap: onArticleSearch,
            active: false,
          ),
          (
            icon: Icons.move_to_inbox_rounded,
            color: AppColors.success,
            onTap: onPlusProduitTap,
            active: plusProduitActive,
          ),
          (
            icon: Icons.nfc_rounded,
            color: AppColors.warning,
            onTap: null,
            active: false,
          ),
          (
            icon: Icons.qr_code_scanner_rounded,
            color: AppColors.primaryDark,
            onTap: onQrScan,
            active: false,
          ),
        ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          _ToolButton(
            layout: layout,
            icon: buttons[i].icon,
            color: buttons[i].color,
            size: s,
            onTap: buttons[i].onTap,
            highlighted: buttons[i].active,
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pastille texte — modèle (outline) ou prix (filled primaryDark)
// UI     : Ligne bas hero card — modèle (Expanded) | prix | magasin.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
/// Pastille libellé (modèle) ou prix — bordure ou fond primaryDark.
class _Pill extends StatelessWidget {
  final _ProduitLayout layout;
  final String text;
  final bool filled;
  final bool compact;
  final bool expandWidth;

  const _Pill({
    required this.layout,
    required this.text,
    required this.filled,
    this.compact = false,
    this.expandWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: expandWidth ? double.infinity : null,
      alignment: expandWidth ? Alignment.center : Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: layout.dp(compact ? 7 : 9),
        vertical: layout.dp(compact ? 4 : 5),
      ),
      decoration: BoxDecoration(
        color: filled ? AppColors.primaryDark : Colors.transparent,
        borderRadius: BorderRadius.circular(layout.dp(10)),
        border: filled
            ? null
            : Border.all(color: AppColors.primaryDark, width: 1.3),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: layout.sp(compact ? 10 : 12),
          fontWeight: FontWeight.w700,
          color: filled ? AppColors.white : AppColors.primaryDark,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onglet Avis — formulaire + liste avis API (page unique scrollable)
// ---------------------------------------------------------------------------
class _AvisPanel extends ConsumerStatefulWidget {
  final _ProduitLayout layout;
  final ProductStockView product;
  final String codeArticle;
  final int codeCollab;

  const _AvisPanel({
    required this.layout,
    required this.product,
    required this.codeArticle,
    required this.codeCollab,
  });

  @override
  ConsumerState<_AvisPanel> createState() => _AvisPanelState();
}

class _AvisPanelState extends ConsumerState<_AvisPanel> {
  int _newRating = 0;
  bool _reportDefect = false;
  String? _photoPath;
  bool _pickingPhoto = false;
  final _commentController = TextEditingController();
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadReviews();
    });
  }

  @override
  void didUpdateWidget(covariant _AvisPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.codeArticle != widget.codeArticle ||
        oldWidget.codeCollab != widget.codeCollab) {
      _loadReviews(force: true);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadReviews({bool force = false}) {
    if (!mounted) return;
    ref
        .read(productReviewProvider.notifier)
        .fetchReviews(
          codeArticle: widget.codeArticle,
          codeCollab: widget.codeCollab,
          force: force,
        );
  }

  Future<void> _pickPhotoFromCamera() async {
    if (_pickingPhoto) return;
    setState(() => _pickingPhoto = true);
    try {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.cameraPermissionDenied)),
        );
        return;
      }

      final photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1400,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (!mounted || photo == null) return;
      final selectedPath = await PhotoAnnotationEditor.open(
        context,
        photo.path,
      );
      if (!mounted || selectedPath == null) return;
      setState(() => _photoPath = selectedPath);
      HapticFeedback.lightImpact();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.cameraOpenFailed)));
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  void _removePhoto() {
    setState(() => _photoPath = null);
    HapticFeedback.selectionClick();
  }

  void _submitAvis() {
    if (_newRating == 0) return;
    setState(() {
      _newRating = 0;
      _reportDefect = false;
      _photoPath = null;
      _commentController.clear();
    });
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.sendReview)));
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    final reviewState = ref.watch(productReviewProvider);
    final reviews = reviewState.reviews;
    final average = reviews.isEmpty
        ? 0.0
        : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
    final distribution = {for (var i = 1; i <= 5; i++) i: 0};
    for (final review in reviews) {
      if (review.rating >= 1 && review.rating <= 5) {
        distribution[review.rating] = (distribution[review.rating] ?? 0) + 1;
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(layout.dp(14)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: layout.dp(12),
            offset: Offset(0, layout.dp(4)),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          layout.dp(12),
          layout.dp(12),
          layout.dp(12),
          layout.dp(12),
        ),
        children: [
          Text(
            context.l10n.giveReview,
            style: TextStyle(
              fontSize: layout.sp(13),
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: layout.dp(10)),
          _DonnerAvisView(
            layout: layout,
            rating: _newRating,
            reportDefect: _reportDefect,
            commentController: _commentController,
            photoPath: _photoPath,
            pickingPhoto: _pickingPhoto,
            onRatingChanged: (r) => setState(() => _newRating = r),
            onDefectChanged: (v) => setState(() => _reportDefect = v),
            onPickPhoto: _pickPhotoFromCamera,
            onRemovePhoto: _removePhoto,
            onSubmit: _submitAvis,
            embedded: true,
          ),
          SizedBox(height: layout.dp(16)),
          Divider(color: AppColors.border, height: layout.dp(24)),
          Text(
            context.l10n.manageReviews,
            style: TextStyle(
              fontSize: layout.sp(13),
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          SizedBox(height: layout.dp(10)),
          if (reviewState.isLoading && reviews.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: layout.dp(24)),
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (reviewState.error != null && reviews.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: layout.dp(12)),
              child: Text(
                reviewState.error!,
                style: TextStyle(
                  fontSize: layout.sp(12),
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else if (reviews.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: layout.dp(12)),
              child: Text(
                context.l10n.noReviewsForFilter,
                style: TextStyle(
                  fontSize: layout.sp(12),
                  color: AppColors.textMuted,
                ),
              ),
            )
          else ...[
            _ReviewsSummaryHeader(
              layout: layout,
              average: average,
              count: reviews.length,
              distribution: distribution,
            ),
            SizedBox(height: layout.dp(12)),
            ...reviews.map(
              (review) => Padding(
                padding: EdgeInsets.only(bottom: layout.dp(10)),
                child: _ReviewCard(
                  layout: layout,
                  review: review,
                  currentCodeCollab: widget.codeCollab,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NearbyStockPanel extends StatelessWidget {
  final _ProduitLayout layout;
  final ProductStockView product;
  final NearbyStockState nearbyState;

  const _NearbyStockPanel({
    required this.layout,
    required this.product,
    required this.nearbyState,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (nearbyState.isLoading && nearbyState.stores.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (nearbyState.stores.isEmpty) {
      return _TabPlaceholderPanel(
        layout: layout,
        icon: Icons.map_outlined,
        title: l10n.navNearby,
        message: nearbyState.error ?? 'Aucun magasin alentour pour cet article',
      );
    }

    return _StockTable(
      layout: layout,
      product: product,
      stockBySize: nearbyState.selectedStockBySize,
    );
  }
}

/// Panneau placeholder pour onglets non implémentés (Réserve…).
/// UI : Centre écran — icône grise + titre onglet (nav index 2 ou 4).
class _TabPlaceholderPanel extends StatelessWidget {
  final _ProduitLayout layout;
  final IconData icon;
  final String title;
  final String? message;

  const _TabPlaceholderPanel({
    required this.layout,
    required this.icon,
    required this.title,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(layout.dp(12)),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: layout.dp(36),
              color: const Color.fromARGB(255, 8, 27, 61),
            ),
            SizedBox(height: layout.dp(8)),
            Text(
              title,
              style: TextStyle(
                fontSize: layout.sp(15),
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
            SizedBox(height: layout.dp(4)),
            Text(
              message ?? l10n.comingSoon,
              style: TextStyle(
                fontSize: layout.sp(12),
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvisSectionCard extends StatelessWidget {
  final _ProduitLayout layout;
  final String title;
  final Widget child;

  const _AvisSectionCard({
    required this.layout,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(layout.dp(12)),
      decoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(layout.dp(12)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: layout.sp(11),
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: layout.dp(10)),
          child,
        ],
      ),
    );
  }
}

class _DonnerAvisView extends StatelessWidget {
  final _ProduitLayout layout;
  final int rating;
  final bool reportDefect;
  final TextEditingController commentController;
  final String? photoPath;
  final bool pickingPhoto;
  final ValueChanged<int> onRatingChanged;
  final ValueChanged<bool> onDefectChanged;
  final VoidCallback onPickPhoto;
  final VoidCallback onRemovePhoto;
  final VoidCallback onSubmit;
  final bool embedded;

  const _DonnerAvisView({
    required this.layout,
    required this.rating,
    required this.reportDefect,
    required this.commentController,
    required this.photoPath,
    required this.pickingPhoto,
    required this.onRatingChanged,
    required this.onDefectChanged,
    required this.onPickPhoto,
    required this.onRemovePhoto,
    required this.onSubmit,
    this.embedded = false,
  });

  static const _starBrown = Color(0xFFB45309);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;

    final content = <Widget>[
      _AvisSectionCard(
        layout: layout,
        title: l10n.yourRating,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final star = i + 1;
              final filled = star <= rating;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: layout.dp(2)),
                child: Material(
                  color: filled
                      ? _starBrown.withValues(alpha: 0.12)
                      : AppColors.surface,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => onRatingChanged(star),
                    child: Padding(
                      padding: EdgeInsets.all(layout.dp(6)),
                      child: Icon(
                        filled ? Icons.star_rounded : Icons.star_border_rounded,
                        color: filled ? _starBrown : AppColors.textMuted,
                        size: layout.dp(32),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      SizedBox(height: layout.dp(10)),
      Container(
        padding: EdgeInsets.symmetric(
          horizontal: layout.dp(12),
          vertical: layout.dp(10),
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(layout.dp(12)),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              width: layout.dp(34),
              height: layout.dp(34),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: AppColors.error,
                size: layout.dp(18),
              ),
            ),
            SizedBox(width: layout.dp(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reportDefect,
                    style: TextStyle(
                      fontSize: layout.sp(11),
                      fontWeight: FontWeight.w800,
                      color: AppColors.error,
                    ),
                  ),
                  Text(
                    l10n.reportDefectHint,
                    style: TextStyle(
                      fontSize: layout.sp(9),
                      color: AppColors.error.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: reportDefect,
              onChanged: onDefectChanged,
              activeTrackColor: AppColors.error.withValues(alpha: 0.55),
              activeThumbColor: AppColors.white,
            ),
          ],
        ),
      ),
      SizedBox(height: layout.dp(10)),
      _AvisSectionCard(
        layout: layout,
        title: l10n.comment,
        child: TextField(
          controller: commentController,
          maxLines: 4,
          style: TextStyle(fontSize: layout.sp(11)),
          decoration: InputDecoration(
            hintText: l10n.commentHint,
            hintStyle: TextStyle(
              fontSize: layout.sp(11),
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(layout.dp(10)),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(layout.dp(10)),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(layout.dp(10)),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: EdgeInsets.all(layout.dp(12)),
          ),
        ),
      ),
      SizedBox(height: layout.dp(10)),
      _AvisSectionCard(
        layout: layout,
        title: l10n.photo,
        child: hasPhoto
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(layout.dp(12)),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.file(
                        File(photoPath!),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                  Positioned(
                    top: layout.dp(8),
                    right: layout.dp(8),
                    child: Material(
                      color: AppColors.primaryDark.withValues(alpha: 0.85),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onRemovePhoto,
                        child: Padding(
                          padding: EdgeInsets.all(layout.dp(6)),
                          child: Icon(
                            Icons.close,
                            color: Colors.white,
                            size: layout.dp(18),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: layout.dp(8),
                    right: layout.dp(8),
                    child: FilledButton.icon(
                      onPressed: pickingPhoto ? null : onPickPhoto,
                      icon: Icon(
                        Icons.photo_camera_outlined,
                        size: layout.dp(16),
                      ),
                      label: Text(
                        l10n.retakePhoto,
                        style: TextStyle(fontSize: layout.sp(10)),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        padding: EdgeInsets.symmetric(
                          horizontal: layout.dp(10),
                          vertical: layout.dp(8),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(layout.dp(12)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(layout.dp(12)),
                  onTap: pickingPhoto ? null : onPickPhoto,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: layout.dp(22)),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(layout.dp(12)),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        if (pickingPhoto)
                          SizedBox(
                            width: layout.dp(28),
                            height: layout.dp(28),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary.withValues(alpha: 0.8),
                            ),
                          )
                        else
                          Container(
                            width: layout.dp(48),
                            height: layout.dp(48),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.photo_camera_outlined,
                              color: AppColors.primary,
                              size: layout.dp(26),
                            ),
                          ),
                        SizedBox(height: layout.dp(8)),
                        Text(
                          pickingPhoto ? l10n.openingCamera : l10n.takePhoto,
                          style: TextStyle(
                            fontSize: layout.sp(11),
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: layout.dp(2)),
                        Text(
                          l10n.takePhotoHint,
                          style: TextStyle(
                            fontSize: layout.sp(9),
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
      SizedBox(height: layout.dp(14)),
      SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: rating > 0 ? onSubmit : null,
          icon: Icon(Icons.send_rounded, size: layout.dp(18)),
          label: Text(
            l10n.sendReview,
            style: TextStyle(
              fontSize: layout.sp(13),
              fontWeight: FontWeight.w800,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.orange,
            disabledBackgroundColor: AppColors.orange.withValues(alpha: 0.35),
            foregroundColor: AppColors.white,
            padding: EdgeInsets.symmetric(vertical: layout.dp(14)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(layout.dp(12)),
            ),
            elevation: 2,
            shadowColor: AppColors.orange.withValues(alpha: 0.35),
          ),
        ),
      ),
    ];

    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: content,
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        layout.dp(12),
        layout.dp(4),
        layout.dp(12),
        layout.dp(12),
      ),
      children: content,
    );
  }
}

class _ReviewsSummaryHeader extends StatelessWidget {
  final _ProduitLayout layout;
  final double average;
  final int count;
  final Map<int, int> distribution;

  const _ReviewsSummaryHeader({
    required this.layout,
    required this.average,
    required this.count,
    required this.distribution,
  });

  static const _barOrange = Color(0xFFEA580C);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxCount = distribution.values.fold(0, (a, b) => a > b ? a : b);

    return Container(
      padding: EdgeInsets.all(layout.dp(14)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primarySoft.withValues(alpha: 0.55),
            AppColors.bg.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(layout.dp(14)),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                average.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: layout.sp(34),
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  height: 1,
                ),
              ),
              SizedBox(height: layout.dp(4)),
              Text(
                l10n.reviewsCount(count),
                style: TextStyle(
                  fontSize: layout.sp(11),
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(width: layout.dp(16)),
          Expanded(
            child: Column(
              children: [
                for (var star = 5; star >= 1; star--)
                  Padding(
                    padding: EdgeInsets.only(bottom: layout.dp(4)),
                    child: Row(
                      children: [
                        Text(
                          '$star',
                          style: TextStyle(
                            fontSize: layout.sp(10),
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: layout.dp(6)),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: maxCount == 0
                                  ? 0
                                  : (distribution[star] ?? 0) / maxCount,
                              minHeight: layout.dp(7),
                              backgroundColor: AppColors.border,
                              valueColor: const AlwaysStoppedAnimation(
                                _barOrange,
                              ),
                            ),
                          ),
                        ),
                      ],
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

class _ReviewCard extends StatelessWidget {
  final _ProduitLayout layout;
  final ProductReviewItem review;
  final int currentCodeCollab;

  const _ReviewCard({
    required this.layout,
    required this.review,
    required this.currentCodeCollab,
  });

  static const _starBrown = Color(0xFFB45309);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isOwn = review.codeCollab == currentCodeCollab;
    final authorLabel = isOwn ? l10n.you : review.authorLabel;
    final apiPhotoUrl =
        '${ApiConstants.digitalStoreBaseUrl}/api/collaborateurs/${review.codeCollab}/photo';
    final reviewPhotoUrl = review.collab?.pictureLink.trim() ?? '';
    final photoUrl = reviewPhotoUrl.isNotEmpty ? reviewPhotoUrl : apiPhotoUrl;
    final dateLabel = review.dateReview != null
        ? '${review.dateReview!.day.toString().padLeft(2, '0')}/'
              '${review.dateReview!.month.toString().padLeft(2, '0')}/'
              '${review.dateReview!.year}'
        : null;

    return Container(
      padding: EdgeInsets.all(layout.dp(12)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(layout.dp(12)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: layout.dp(6),
            offset: Offset(0, layout.dp(2)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ReviewAuthorAvatar(
                layout: layout,
                imageUrl: photoUrl,
                authorLabel: review.authorLabel,
              ),
              SizedBox(width: layout.dp(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: layout.sp(11),
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (dateLabel != null) ...[
                      SizedBox(height: layout.dp(2)),
                      Text(
                        dateLabel,
                        style: TextStyle(
                          fontSize: layout.sp(9),
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: layout.dp(14),
                    color: _starBrown,
                  );
                }),
              ),
            ],
          ),
          if (review.isDefective) ...[
            SizedBox(height: layout.dp(6)),
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: layout.dp(14),
                  color: AppColors.error,
                ),
                SizedBox(width: layout.dp(4)),
                Text(
                  l10n.defectiveReported,
                  style: TextStyle(
                    fontSize: layout.sp(10),
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ],
          if (review.comment.isNotEmpty) ...[
            SizedBox(height: layout.dp(8)),
            Text(
              review.comment,
              style: TextStyle(
                fontSize: layout.sp(11),
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewAuthorAvatar extends StatelessWidget {
  final _ProduitLayout layout;
  final String imageUrl;
  final String authorLabel;

  const _ReviewAuthorAvatar({
    required this.layout,
    required this.imageUrl,
    required this.authorLabel,
  });

  String get _initials {
    final words = authorLabel
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    final value = words.map((word) => word[0]).join().toUpperCase();
    return value.isEmpty ? '?' : value;
  }

  @override
  Widget build(BuildContext context) {
    final side = layout.dp(38);
    final fallback = Center(
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: layout.sp(11),
          fontWeight: FontWeight.w900,
          color: AppColors.primary,
        ),
      ),
    );

    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primarySoft,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isEmpty
          ? fallback
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Navigation bas — Stock Mag, Stock Web, Alentours, Avis, Réserve
// UI     : bottomNavigationBar Scaffold — 5 _NavBarItem icône + libellé.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _BottomNav extends StatelessWidget {
  final _ProduitLayout layout;
  final int index;
  final ValueChanged<int> onChanged;

  const _BottomNav({
    required this.layout,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final l10n = context.l10n;
    final items = [
      (Icons.store_outlined, Icons.store_rounded, l10n.navStockMag),
      (Icons.language_outlined, Icons.language, l10n.navStockWeb),
      (Icons.map_outlined, Icons.map_rounded, l10n.navNearby),
      (Icons.star_border_rounded, Icons.star_rounded, l10n.navReviews),
      (Icons.inventory_2_outlined, Icons.inventory_2_rounded, l10n.navReserve),
    ];

    return ColoredBox(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(height: 1, thickness: 1, color: AppColors.border),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemW = constraints.maxWidth / items.length;
                final indicatorW = itemW * 0.36;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 2,
                      child: Stack(
                        children: [
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            left: index * itemW + (itemW - indicatorW) / 2,
                            width: indicatorW,
                            top: 0,
                            bottom: 0,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: layout.bottomNavH,
                      child: Row(
                        children: List.generate(items.length, (i) {
                          final (iconOut, iconSel, label) = items[i];
                          final selected = i == index;
                          return Expanded(
                            child: _NavBarItem(
                              layout: layout,
                              label: label,
                              icon: selected ? iconSel : iconOut,
                              selected: selected,
                              iconsOnly: false,
                              onTap: () {
                                if (selected) return;
                                HapticFeedback.selectionClick();
                                onChanged(i);
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                    if (bottom == 0) SizedBox(height: layout.dp(4)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Item barre nav bas — icône outline/filled + libellé
// UI     : Un onglet _BottomNav — icône selected/unselected + label i18n.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _NavBarItem extends StatelessWidget {
  final _ProduitLayout layout;
  final String label;
  final IconData icon;
  final bool selected;
  final bool iconsOnly;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.layout,
    required this.label,
    required this.icon,
    required this.selected,
    this.iconsOnly = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: SizedBox(
          height: layout.bottomNavH,
          child: iconsOnly
              ? Center(
                  child: Icon(
                    icon,
                    size: layout.dp(selected ? 22 : 20),
                    color: color,
                  ),
                )
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          icon,
                          key: ValueKey('$icon-$selected'),
                          size: layout.dp(selected ? 22 : 21),
                          color: color,
                        ),
                      ),
                      SizedBox(height: layout.dp(2)),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 200),
                        style: TextStyle(
                          fontSize: layout.sp(9.5),
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: color,
                        ),
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
