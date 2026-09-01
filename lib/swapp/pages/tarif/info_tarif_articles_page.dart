// =============================================================================
// CapMobile — Module Swapp — Page Info Tarif Articles
// -----------------------------------------------------------------------------
// Fonctionnalité : Liste articles d'une ou plusieurs opérations tarifaires.
// Design         : Thème SWAPP indigo — header blanc, cartes, pastilles thème.
// UI             : Toolbar scan · filtres · liste refs · œil → fiche produit.
// Spécifications : Données démo ; TODO API articles par opération(s).
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/tarif/data/info_tarif_article_test_data.dart';
import 'dart:math' as math;

import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/swapp/models/info_tarif_article_item.dart';
import 'package:cap_mobile/swapp/models/info_tarif_item.dart';
import 'package:cap_mobile/swapp/pages/produit/detail_produit_page.dart';
import 'package:cap_mobile/swapp/widgets/qr_camera_scanner_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_tool_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cap_mobile/core/apiswap/produit/providers/swapp_product_provider.dart';

/// Largeur d'une pastille prix — identique légende et lignes produit.
double _priceSize(double Function(double) dp) => dp(48);

/// Espacement entre pastilles prix.
double _priceGap(double Function(double) dp) => dp(5);

/// Ombres cartes — ombre portée sans contour.
List<BoxShadow> _cardShadows(double Function(double) dp) {
  return [
    BoxShadow(
      color: SwappMenuColors.ink.withValues(alpha: 0.12),
      blurRadius: dp(16),
      offset: Offset(0, dp(6)),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: SwappMenuColors.ink.withValues(alpha: 0.06),
      blurRadius: dp(4),
      offset: Offset(0, dp(1)),
    ),
  ];
}

/// Liste articles tarifaires — ouverte depuis l'icône œil ou « Continuer ».
class InfoTarifArticlesPage extends ConsumerStatefulWidget {
  final List<InfoTarifItem> operations;

  const InfoTarifArticlesPage({super.key, required this.operations});

  static Route<void> fadeRoute(List<InfoTarifItem> operations) =>
      swappMenuFadeRoute(InfoTarifArticlesPage(operations: operations));

  @override
  ConsumerState<InfoTarifArticlesPage> createState() =>
      _InfoTarifArticlesPageState();
}

class _InfoTarifArticlesPageState extends ConsumerState<InfoTarifArticlesPage> {
  bool _showPhotos = true;
  bool _filterNouveautes = false;

  late List<InfoTarifArticleItem> _articles;

  @override
  void initState() {
    super.initState();
    _articles = InfoTarifArticleDemoData.articlesForOperations(
      widget.operations.map((o) => o.code),
    );
  }

  int get _inStockCount => _articles.where((a) => a.stock > 0).length;

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
    await _openProduct(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.35);
    double dp(double v) => v * scale;
    final top = MediaQuery.paddingOf(context).top;

    final base = _filterNouveautes
        ? _articles.where((a) => a.isNouveaute).toList()
        : List<InfoTarifArticleItem>.from(_articles);
    base.sort((a, b) {
      final aOk = a.stock > 0;
      final bOk = b.stock > 0;
      if (aOk == bOk) return 0;
      return aOk ? -1 : 1;
    });
    final articles = base;

    final opLabel = widget.operations.length == 1
        ? widget.operations.first.label
        : '${widget.operations.length} opérations';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: SwappMenuColors.panel,
      ),
      child: Scaffold(
        backgroundColor: SwappMenuColors.bg,
        body: Column(
          children: [
            _ArticlesHeader(
              dp: dp,
              top: top,
              refCount: articles.length,
              inStockCount: _inStockCount,
              opLabel: opLabel,
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: articles.isEmpty
                  ? _EmptyArticles(dp: dp)
                  : ListView(
                      padding: EdgeInsets.fromLTRB(
                        dp(16),
                        dp(12),
                        dp(16),
                        dp(24),
                      ),
                      children: [
                        _ToolsCard(dp: dp, onScanQr: _openQrScanner),
                        SizedBox(height: dp(10)),
                        _FiltersCard(
                          dp: dp,
                          showPhotos: _showPhotos,
                          filterNouveautes: _filterNouveautes,
                          onTogglePhotos: () =>
                              setState(() => _showPhotos = !_showPhotos),
                          onToggleNouveautes: () => setState(
                            () => _filterNouveautes = !_filterNouveautes,
                          ),
                        ),
                        SizedBox(height: dp(12)),
                        ...List.generate(articles.length, (index) {
                          final item = articles[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: dp(10)),
                            child: _ArticleCard(
                              dp: dp,
                              item: item,
                              showPhoto: _showPhotos,
                              onOpenDetail: () =>
                                  _openProduct(item.codeArticle),
                            ),
                          );
                        }),
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
// En-tête blanc — thème SWAPP
// ---------------------------------------------------------------------------
class _ArticlesHeader extends StatelessWidget {
  final double Function(double) dp;
  final double top;
  final int refCount;
  final int inStockCount;
  final String opLabel;
  final VoidCallback onBack;

  const _ArticlesHeader({
    required this.dp,
    required this.top,
    required this.refCount,
    required this.inStockCount,
    required this.opLabel,
    required this.onBack,
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
        padding: EdgeInsets.fromLTRB(dp(4), top + dp(4), dp(16), dp(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
                        'Info Tarif',
                        style: TextStyle(
                          fontSize: dp(20),
                          fontWeight: FontWeight.w900,
                          color: SwappMenuColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        opLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: dp(11),
                          color: SwappMenuColors.inkDim,
                        ),
                      ),
                    ],
                  ),
                ),
                _HeaderStat(
                  dp: dp,
                  value: '$refCount',
                  label: 'Références',
                  color: SwappMenuColors.indigo,
                  bg: SwappMenuColors.p1Bg,
                ),
                SizedBox(width: dp(8)),
                _HeaderStat(
                  dp: dp,
                  value: '$inStockCount',
                  label: 'En stock',
                  color: SwappMenuColors.p2,
                  bg: SwappMenuColors.p2Bg,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final double Function(double) dp;
  final String value;
  final String label;
  final Color color;
  final Color bg;

  const _HeaderStat({
    required this.dp,
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(8)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(dp(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: dp(14),
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          SizedBox(width: dp(4)),
          Text(
            label,
            style: TextStyle(
              fontSize: dp(10),
              fontWeight: FontWeight.w600,
              color: SwappMenuColors.inkDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolsCard extends StatelessWidget {
  final double Function(double) dp;
  final VoidCallback onScanQr;

  const _ToolsCard({required this.dp, required this.onScanQr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dp(14), vertical: dp(12)),
      decoration: BoxDecoration(
        color: SwappMenuColors.panel,
        borderRadius: BorderRadius.circular(dp(16)),
        boxShadow: _cardShadows(dp),
      ),
      child: Row(
        children: [
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

class _FiltersCard extends StatelessWidget {
  final double Function(double) dp;
  final bool showPhotos;
  final bool filterNouveautes;
  final VoidCallback onTogglePhotos;
  final VoidCallback onToggleNouveautes;

  const _FiltersCard({
    required this.dp,
    required this.showPhotos,
    required this.filterNouveautes,
    required this.onTogglePhotos,
    required this.onToggleNouveautes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dp(12)),
      decoration: BoxDecoration(
        color: SwappMenuColors.panel,
        borderRadius: BorderRadius.circular(dp(16)),
        boxShadow: _cardShadows(dp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _FilterChip(
                dp: dp,
                label: 'Nouveautés',
                active: filterNouveautes,
                onTap: onToggleNouveautes,
              ),
              SizedBox(width: dp(8)),
              _FilterChip(
                dp: dp,
                label: 'Photos',
                active: showPhotos,
                onTap: onTogglePhotos,
              ),
            ],
          ),
          SizedBox(height: dp(10)),
          Align(
            alignment: Alignment.centerRight,
            child: _PriceColumnHeaders(dp: dp),
          ),
        ],
      ),
    );
  }
}

class _PriceColumnHeaders extends StatelessWidget {
  final double Function(double) dp;

  const _PriceColumnHeaders({required this.dp});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderChip(dp: dp, label: 'NEW', bg: const Color(0xFFE53935)),
        SizedBox(width: _priceGap(dp)),
        _HeaderChip(dp: dp, label: 'PV Ini', bg: SwappMenuColors.ink),
        SizedBox(width: _priceGap(dp)),
        _HeaderChip(dp: dp, label: 'Promo', bg: SwappMenuColors.p2),
        SizedBox(width: _priceGap(dp)),
        _HeaderChip(
          dp: dp,
          label: 'Stock',
          bg: SwappMenuColors.bg,
          fg: SwappMenuColors.ink,
        ),
      ],
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final double Function(double) dp;
  final String label;
  final Color bg;
  final Color fg;

  const _HeaderChip({
    required this.dp,
    required this.label,
    required this.bg,
    this.fg = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _priceSize(dp),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: dp(4)),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(dp(6)),
          border: bg == SwappMenuColors.bg
              ? Border.all(color: SwappMenuColors.line.withValues(alpha: 0.5))
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: dp(8),
            fontWeight: FontWeight.w800,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final double Function(double) dp;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.dp,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? SwappMenuColors.p1Bg : SwappMenuColors.bg,
      borderRadius: BorderRadius.circular(dp(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(20)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(6)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: dp(14),
                color: active ? SwappMenuColors.indigo : SwappMenuColors.inkDim,
              ),
              SizedBox(width: dp(6)),
              Text(
                label,
                style: TextStyle(
                  fontSize: dp(11),
                  fontWeight: FontWeight.w800,
                  color: active
                      ? SwappMenuColors.indigo
                      : SwappMenuColors.inkDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  final double Function(double) dp;
  final InfoTarifArticleItem item;
  final bool showPhoto;
  final VoidCallback onOpenDetail;

  const _ArticleCard({
    required this.dp,
    required this.item,
    required this.showPhoto,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SwappMenuColors.panel,
        borderRadius: BorderRadius.circular(dp(16)),
        boxShadow: _cardShadows(dp),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(dp(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpenDetail,
          child: Padding(
            padding: EdgeInsets.fromLTRB(dp(10), dp(10), dp(12), dp(10)),
            child: showPhoto ? _withPhoto() : _withoutPhoto(),
          ),
        ),
      ),
    );
  }

  Widget _codeAndStock({required bool stacked}) {
    final code = Text(
      item.codeArticle,
      style: TextStyle(
        fontSize: dp(14),
        fontWeight: FontWeight.w900,
        color: SwappMenuColors.ink,
        letterSpacing: 0.3,
      ),
    );
    final inStock = item.stock > 0;
    final stock = Text(
      inStock ? 'En stock' : 'Rupture en stock',
      style: TextStyle(
        fontSize: dp(10),
        fontWeight: FontWeight.w800,
        color: inStock ? SwappMenuColors.p2 : const Color(0xFFE53935),
      ),
    );

    if (stacked) {
      return Row(
        children: [
          Expanded(child: code),
          stock,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        code,
        SizedBox(height: dp(2)),
        stock,
      ],
    );
  }

  Widget _priceRow({Widget? leading}) {
    return Row(
      children: [
        if (leading != null) ...[leading, const Spacer()],
        _NewBadge(dp: dp, visible: item.isNouveaute),
        SizedBox(width: _priceGap(dp)),
        _PricePill(
          dp: dp,
          label: item.prixInitialLabel,
          bg: SwappMenuColors.ink,
          strikethrough: true,
        ),
        SizedBox(width: _priceGap(dp)),
        _PricePill(dp: dp, label: item.prixPromoLabel, bg: SwappMenuColors.p2),
        SizedBox(width: _priceGap(dp)),
        _PricePill(
          dp: dp,
          label: '${item.stock}',
          bg: SwappMenuColors.bg,
          fg: SwappMenuColors.ink,
          bordered: true,
        ),
      ],
    );
  }

  Widget _withPhoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _codeAndStock(stacked: true),
        SizedBox(height: dp(8)),
        _priceRow(
          leading: _ProductThumb(dp: dp, photoUrl: item.resolvedPhotoUrl),
        ),
      ],
    );
  }

  Widget _withoutPhoto() {
    return Row(
      children: [
        Expanded(child: _codeAndStock(stacked: false)),
        _priceRow(),
      ],
    );
  }
}

/// Vignette produit ronde — même rendu photo que la fiche produit
/// (remplissage complet, découpe antialiasée, repli icône coureur).
class _ProductThumb extends StatelessWidget {
  final double Function(double) dp;
  final String? photoUrl;

  const _ProductThumb({required this.dp, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    final size = dp(50);
    final url = photoUrl?.trim();

    return Material(
      color: SwappMenuColors.p1Bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: size,
        height: size,
        child: url == null || url.isEmpty
            ? _fallback(size)
            : Image.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.fill,
                alignment: Alignment.center,
                errorBuilder: (_, _, _) => _fallback(size),
              ),
      ),
    );
  }

  Widget _fallback(double size) {
    return Center(
      child: Icon(
        Icons.directions_run_rounded,
        size: size * 0.42,
        color: SwappMenuColors.indigo.withValues(alpha: 0.55),
      ),
    );
  }
}

/// Sticker « NEW » rouge — burst 12 branches, pulse + léger wobble.
class _NewBadge extends StatefulWidget {
  final double Function(double) dp;
  final bool visible;

  const _NewBadge({required this.dp, required this.visible});

  @override
  State<_NewBadge> createState() => _NewBadgeState();
}

class _NewBadgeState extends State<_NewBadge>
    with SingleTickerProviderStateMixin {
  static const _redDark = Color(0xFFC62828);

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.visible) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _NewBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.visible && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = _priceSize(widget.dp);
    if (!widget.visible) {
      return SizedBox(width: size, height: size);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final scale = 0.92 + (t * 0.12);
        final angle = -0.18 + (t * 0.12);
        return Transform.rotate(
          angle: angle,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: const _NewStickerPainter(),
          child: Center(
            child: Text(
              'NEW',
              style: TextStyle(
                fontSize: widget.dp(10),
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.4,
                height: 1,
                shadows: const [
                  Shadow(color: _redDark, blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Peinture sticker — étoile dentelée rouge + liseré blanc.
class _NewStickerPainter extends CustomPainter {
  const _NewStickerPainter();

  static const _red = Color(0xFFE53935);
  static const _redDark = Color(0xFFB71C1C);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.width / 2;
    final inner = outer * 0.72;
    const spikes = 12;
    final path = Path();

    for (var i = 0; i < spikes * 2; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = (i * math.pi / spikes) - math.pi / 2;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawShadow(path, _redDark.withValues(alpha: 0.45), 3, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_red, _redDark],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PricePill extends StatelessWidget {
  final double Function(double) dp;
  final String label;
  final Color bg;
  final Color? fg;
  final bool strikethrough;
  final bool bordered;

  const _PricePill({
    required this.dp,
    required this.label,
    required this.bg,
    this.fg,
    this.strikethrough = false,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = fg ?? Colors.white;

    return Container(
      width: _priceSize(dp),
      height: _priceSize(dp),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: bordered
            ? Border.all(color: SwappMenuColors.line.withValues(alpha: 0.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: (bordered ? SwappMenuColors.ink : bg).withValues(
              alpha: bordered ? 0.10 : 0.28,
            ),
            blurRadius: dp(8),
            offset: Offset(0, dp(3)),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dp(4)),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: dp(13),
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1.05,
              decoration: strikethrough ? TextDecoration.lineThrough : null,
              decorationColor: textColor,
              decorationThickness: 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyArticles extends StatelessWidget {
  final double Function(double) dp;

  const _EmptyArticles({required this.dp});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dp(64),
            height: dp(64),
            decoration: const BoxDecoration(
              color: SwappMenuColors.p1Bg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: dp(28),
              color: SwappMenuColors.indigo,
            ),
          ),
          SizedBox(height: dp(12)),
          Text(
            'Aucun article pour cette opération',
            style: TextStyle(
              color: SwappMenuColors.inkDim,
              fontSize: dp(14),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
