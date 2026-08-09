// =============================================================================
// CapMobile — Module Swapp — Page Réserve Produit (ReserveProduitPage)
// -----------------------------------------------------------------------------
// Fonctionnalité : Vue réserve magasin — NON RANGE, PAS DE LOGE, chips SKU.
// Design         : Thème bleu Cap Mobile ; toolbar 4 boutons ; Wrap + Chips.
// UI             : Ouverte depuis onglet Réserve (_BottomNav index 4) ;
//                  header dégradé + miniature produit ; toggle SKU uniquement.
// Spécifications : Données mock [ReserveMockData] en attente API ;
//                  PopScope retour → DetailProduitPage.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/swapp/models/product_stock_view.dart';
import 'package:cap_mobile/swapp/models/reserve_mock_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Jaune foncé — bouton NFC toolbar réserve (distinct du warning standard).
const Color _reserveNfcYellow = Color(0xFFB45309);

/// UI : Point d'entrée écran « Réserve Produit » depuis l'onglet Réserve.
class ReserveProduitPage extends StatefulWidget {
  final ProductStockView product;

  const ReserveProduitPage({
    super.key,
    required this.product,
  });

  @override
  State<ReserveProduitPage> createState() => _ReserveProduitPageState();
}

class _ReserveProduitPageState extends State<ReserveProduitPage> {
  bool _skuOnly = false;
  List<ReserveSkuItem> _items = List<ReserveSkuItem>.from(
    ReserveMockData.sampleItems,
  );

  double _dp(double v) {
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.4);
    return v * scale;
  }

  double _sp(double v) {
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.4);
    return v * scale;
  }

  int _count(String sectionId) =>
      ReserveMockData.countForSection(sectionId, _items);

  List<ReserveSkuItem> _sectionItems(String sectionId) =>
      ReserveMockData.itemsForSection(sectionId, source: _items);

  void _clearPasDeLoge() {
    HapticFeedback.mediumImpact();
    setState(() {
      _items = _items
          .where((e) => e.sectionId != ReserveMockData.sectionPasDeLoge)
          .toList(growable: true);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PAS DE LOGE vidé (mode test)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toolbarTap(String label) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label · mode test'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            _ReserveHeader(
              dp: _dp,
              sp: _sp,
              product: product,
              onBack: () => Navigator.pop(context),
              onForward: () => _toolbarTap('Navigation suivante'),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(_dp(12), _dp(12), _dp(12), _dp(20)),
                children: [
                  _ReserveToolbar(
                    dp: _dp,
                    onArticle: () => _toolbarTap('Code article'),
                    onRanger: () => _toolbarTap('Ranger'),
                    onNfc: () => _toolbarTap('NFC'),
                    onQr: () => _toolbarTap('Scan QR'),
                  ),
                  SizedBox(height: _dp(10)),
                  _SkuToggleRow(
                    dp: _dp,
                    sp: _sp,
                    value: _skuOnly,
                    onChanged: (v) => setState(() => _skuOnly = v),
                  ),
                  SizedBox(height: _dp(14)),
                  _ReserveSectionCard(
                    dp: _dp,
                    sp: _sp,
                    title: ReserveMockData.labelNonRange,
                    count: _count(ReserveMockData.sectionNonRange),
                    accent: AppColors.surface,
                    titleColor: AppColors.textPrimary,
                    borderColor: AppColors.border,
                    items: _sectionItems(ReserveMockData.sectionNonRange),
                    skuOnly: _skuOnly,
                    badgeColor: AppColors.primary,
                  ),
                  SizedBox(height: _dp(10)),
                  _ReserveSectionCard(
                    dp: _dp,
                    sp: _sp,
                    title: ReserveMockData.labelPasDeLoge,
                    count: _count(ReserveMockData.sectionPasDeLoge),
                    accent: AppColors.orange,
                    titleColor: AppColors.white,
                    borderColor: AppColors.orange.withValues(alpha: 0.6),
                    leading: Icon(
                      Icons.touch_app_rounded,
                      color: AppColors.tertiary,
                      size: _dp(22),
                    ),
                    trailing: _ClearBadge(onTap: _clearPasDeLoge, dp: _dp),
                    items: _sectionItems(ReserveMockData.sectionPasDeLoge),
                    skuOnly: _skuOnly,
                    badgeColor: AppColors.primaryDark,
                    emptyHint: 'Aucun article sans loge',
                  ),
                  SizedBox(height: _dp(12)),
                  Text(
                    'Mode test · API réserve à brancher',
                    style: TextStyle(
                      fontSize: _sp(10),
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted,
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

// ---------------------------------------------------------------------------
// Header réserve — dégradé bleu Cap Mobile, nav, titre, photo produit
// UI     : Bandeau haut page — équivalent maquette « Réserve Produit ».
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _ReserveHeader extends StatelessWidget {
  final double Function(double) dp;
  final double Function(double) sp;
  final ProductStockView product;
  final VoidCallback onBack;
  final VoidCallback onForward;

  const _ReserveHeader({
    required this.dp,
    required this.sp,
    required this.product,
    required this.onBack,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(dp(8), top + dp(8), dp(8), dp(12)),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _HeaderNavButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
          SizedBox(width: dp(4)),
          Expanded(
            child: Text(
              'Réserve Produit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.white,
                fontSize: sp(16),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
          _ProductThumb(photoUrl: product.photoUrl, size: dp(40)),
          SizedBox(width: dp(6)),
          _HeaderNavButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: onForward,
          ),
        ],
      ),
    );
  }
}

class _HeaderNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
      ),
    );
  }
}

class _ProductThumb extends StatelessWidget {
  final String? photoUrl;
  final double size;

  const _ProductThumb({required this.photoUrl, required this.size});

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(size * 0.18),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url != null && url.isNotEmpty
          ? Image.network(url, fit: BoxFit.cover)
          : Icon(Icons.image_outlined, color: AppColors.textMuted, size: size * 0.45),
    );
  }
}

// ---------------------------------------------------------------------------
// Toolbar réserve — 4 boutons rond (rouge, vert, bleu, jaune foncé)
// UI     : Remplace la douchette scanner de la maquette.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _ReserveToolbar extends StatelessWidget {
  final double Function(double) dp;
  final VoidCallback onArticle;
  final VoidCallback onRanger;
  final VoidCallback onNfc;
  final VoidCallback onQr;

  const _ReserveToolbar({
    required this.dp,
    required this.onArticle,
    required this.onRanger,
    required this.onNfc,
    required this.onQr,
  });

  @override
  Widget build(BuildContext context) {
    final size = dp(38);
    final gap = dp(8);

    return Container(
      padding: EdgeInsets.all(dp(10)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(dp(14)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: dp(10),
            offset: Offset(0, dp(3)),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _RoundActionButton(
            size: size,
            color: AppColors.error,
            icon: Icons.apps_rounded,
            onTap: onArticle,
          ),
          SizedBox(width: gap),
          _RoundActionButton(
            size: size,
            color: AppColors.success,
            icon: Icons.move_to_inbox_rounded,
            onTap: onRanger,
          ),
          SizedBox(width: gap),
          _RoundActionButton(
            size: size,
            color: AppColors.primaryDark,
            icon: Icons.qr_code_scanner_rounded,
            onTap: onQr,
          ),
          SizedBox(width: gap),
          _RoundActionButton(
            size: size,
            color: _reserveNfcYellow,
            icon: Icons.nfc_rounded,
            onTap: onNfc,
          ),
        ],
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  final double size;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _RoundActionButton({
    required this.size,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: 2,
      shadowColor: color.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: AppColors.white, size: size * 0.44),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Toggle « Affichage SKU uniquement »
// UI     : Sous la toolbar — filtre libellé des chips.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _SkuToggleRow extends StatelessWidget {
  final double Function(double) dp;
  final double Function(double) sp;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SkuToggleRow({
    required this.dp,
    required this.sp,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(8)),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(dp(12)),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primary,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
          SizedBox(width: dp(6)),
          Expanded(
            child: Text(
              'Affichage SKU uniquement',
              style: TextStyle(
                fontSize: sp(12),
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section réserve — bandeau titre + compteur + Wrap chips SKU
// UI     : Blocs NON RANGE (blanc) et PAS DE LOGE (orange).
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _ReserveSectionCard extends StatelessWidget {
  final double Function(double) dp;
  final double Function(double) sp;
  final String title;
  final int count;
  final Color accent;
  final Color titleColor;
  final Color borderColor;
  final Color badgeColor;
  final List<ReserveSkuItem> items;
  final bool skuOnly;
  final Widget? leading;
  final Widget? trailing;
  final String? emptyHint;

  const _ReserveSectionCard({
    required this.dp,
    required this.sp,
    required this.title,
    required this.count,
    required this.accent,
    required this.titleColor,
    required this.borderColor,
    required this.badgeColor,
    required this.items,
    required this.skuOnly,
    this.leading,
    this.trailing,
    this.emptyHint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(dp(12)),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: dp(8),
            offset: Offset(0, dp(2)),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: accent,
            padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(10)),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  SizedBox(width: dp(8)),
                ],
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: sp(13),
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                _CountBadge(count: count, color: badgeColor, dp: dp, sp: sp),
                if (trailing != null) ...[
                  SizedBox(width: dp(6)),
                  trailing!,
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(dp(10)),
            child: items.isEmpty
                ? Text(
                    emptyHint ?? 'Aucun article',
                    style: TextStyle(
                      fontSize: sp(11),
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted,
                    ),
                  )
                : Wrap(
                    spacing: dp(6),
                    runSpacing: dp(6),
                    children: [
                      for (final item in items)
                        _SkuChip(
                          dp: dp,
                          sp: sp,
                          label: skuOnly ? item.sku : '${item.sku} · ${item.label}',
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;
  final double Function(double) dp;
  final double Function(double) sp;

  const _CountBadge({
    required this.count,
    required this.color,
    required this.dp,
    required this.sp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dp(30),
      height: dp(30),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.white,
        border: Border.all(color: color, width: 1.6),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: sp(12),
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _ClearBadge extends StatelessWidget {
  final VoidCallback onTap;
  final double Function(double) dp;

  const _ClearBadge({required this.onTap, required this.dp});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error,
      borderRadius: BorderRadius.circular(dp(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(dp(8)),
        onTap: onTap,
        child: SizedBox(
          width: dp(32),
          height: dp(32),
          child: Icon(
            Icons.cleaning_services_rounded,
            color: AppColors.white,
            size: dp(18),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chip SKU réserve — pill bleu Cap Mobile
// UI     : Élément du Wrap sous chaque section.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
class _SkuChip extends StatelessWidget {
  final double Function(double) dp;
  final double Function(double) sp;
  final String label;

  const _SkuChip({
    required this.dp,
    required this.sp,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        Icons.inventory_2_outlined,
        size: dp(15),
        color: AppColors.primaryDark,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: sp(10),
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
      backgroundColor: AppColors.primarySoft,
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.22)),
      padding: EdgeInsets.symmetric(horizontal: dp(2)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dp(18)),
      ),
    );
  }
}
