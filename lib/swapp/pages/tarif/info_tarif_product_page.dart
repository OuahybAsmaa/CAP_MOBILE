import 'dart:math' as math;

import 'package:cap_mobile/core/apiswap/shared/config/swapp_api_constants.dart';
import 'package:cap_mobile/core/apiswap/produit/providers/swapp_product_provider.dart';
import 'package:cap_mobile/core/apiswap/tarif/providers/tarif_api_provider.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/features/auth/providers/auth_provider.dart';
import 'package:cap_mobile/swapp/models/info_tarif_article_item.dart';
import 'package:cap_mobile/swapp/models/info_tarif_item.dart';
import 'package:cap_mobile/swapp/pages/produit/detail_produit_page.dart';
import 'package:cap_mobile/swapp/widgets/qr_camera_scanner_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class InfoTarifProductPage extends ConsumerStatefulWidget {
  final List<InfoTarifItem> operations;

  const InfoTarifProductPage({super.key, required this.operations});

  static Route<void> fadeRoute(List<InfoTarifItem> operations) =>
      swappMenuFadeRoute(InfoTarifProductPage(operations: operations));

  @override
  ConsumerState<InfoTarifProductPage> createState() =>
      _InfoTarifProductPageState();
}

class _InfoTarifProductPageState extends ConsumerState<InfoTarifProductPage> {
  static final _date = DateFormat('dd/MM/yyyy');
  static final _price = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );

  List<InfoTarifArticleItem> _articles = const [];
  InfoTarifArticleItem? _selected;
  bool _loading = true;
  String? _error;
  String _scannedCode = '';

  InfoTarifItem get _operation => widget.operations.first;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final collab = ref.read(authProvider).collaborateur;
      final items = await ref
          .read(tarifApiServiceProvider)
          .fetchArticles(
            codeMag: SwappApiConstants.resolveCodeMagFromCollab(collab),
            operations: widget.operations,
          );
      if (!mounted) return;
      setState(() {
        _articles = items;
        _selected = items.isEmpty ? null : items.first;
        _scannedCode = _selected?.codeArticle ?? '';
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _selectCode(String rawCode) {
    final code = rawCode.trim();
    if (code.isEmpty) return;
    final modelCode = code.length >= 8 ? code.substring(0, 8) : code;
    InfoTarifArticleItem? found;
    for (final item in _articles) {
      if (item.codeModele == modelCode || item.codeArticle == code) {
        found = item;
        break;
      }
    }
    if (found == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Article $code absent de cette opération tarifaire.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _selected = found;
      _scannedCode = code;
    });
  }

  Future<void> _scan() async {
    final code = await openQrCameraScanner(context, context.l10n);
    if (!mounted || code == null) return;
    _selectCode(code);
  }

  Future<void> _enterCode() async {
    final controller = TextEditingController(text: _scannedCode);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Saisir un code-barres'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.keyboard_alt_rounded),
            hintText: 'Code article ou modèle',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Afficher'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || result == null) return;
    _selectCode(result);
  }

  Future<void> _openProductDetails() async {
    final article = _selected;
    if (article == null) return;
    HapticFeedback.lightImpact();
    await ref
        .read(swappProductProvider.notifier)
        .fetchModele(codeModele: article.codeArticle);
    if (!mounted) return;
    await Navigator.push(
      context,
      DetailProduitPage.fadeRoute(loadDefaultProduct: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final scale = (width / 390).clamp(0.86, 1.25);
    double dp(double value) => value * scale;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: Column(
        children: [
          _Header(
            dp: dp,
            top: top,
            onBack: () => Navigator.pop(context),
            onInfo: _openProductDetails,
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _ErrorState(dp: dp, message: _error!, onRetry: _load)
                : _selected == null
                ? const Center(child: Text('Aucun modèle pour cette opération'))
                : LayoutBuilder(
                    builder: (context, constraints) => ClipRect(
                      child: FittedBox(
                        fit: BoxFit.fill,
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: dp(820),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(0, dp(12), 0, dp(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _CodeActions(
                                  dp: dp,
                                  code: _scannedCode,
                                  onEnter: _enterCode,
                                  onScan: _scan,
                                ),
                                SizedBox(height: dp(10)),
                                _ScanBanner(dp: dp),
                                SizedBox(height: dp(12)),
                                _ProductImage(dp: dp, article: _selected!),
                                SizedBox(height: dp(10)),
                                _OperationCard(
                                  dp: dp,
                                  operation: _operation,
                                  date: _date,
                                ),
                                SizedBox(height: dp(10)),
                                _PriceCard(
                                  dp: dp,
                                  article: _selected!,
                                  price: _price,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double Function(double) dp;
  final double top;
  final VoidCallback onBack;
  final VoidCallback onInfo;
  const _Header({
    required this.dp,
    required this.top,
    required this.onBack,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.fromLTRB(dp(4), top + dp(4), dp(8), dp(12)),
    decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
    child: Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        Expanded(
          child: Text(
            'Info Tarif',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: dp(18),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        IconButton(
          onPressed: onInfo,
          tooltip: 'Voir la fiche produit',
          icon: const Icon(
            Icons.info_outline_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    ),
  );
}

class _CodeActions extends StatelessWidget {
  final double Function(double) dp;
  final String code;
  final VoidCallback onEnter;
  final VoidCallback onScan;
  const _CodeActions({
    required this.dp,
    required this.code,
    required this.onEnter,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(dp(12)),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(dp(20)),
      boxShadow: const [BoxShadow(color: Color(0x18062472), blurRadius: 18)],
    ),
    child: Row(
      children: [
        _RoundAction(
          dp: dp,
          icon: Icons.grid_view_rounded,
          color: const Color(0xFFE5092F),
          onTap: onEnter,
        ),
        SizedBox(width: dp(10)),
        _RoundAction(
          dp: dp,
          icon: Icons.dialpad_rounded,
          color: const Color(0xFF0A45C8),
          onTap: onScan,
        ),
        SizedBox(width: dp(14)),
        _BarcodeMark(dp: dp),
        SizedBox(width: dp(12)),
        Expanded(
          child: Text(
            code.isEmpty ? 'Scannez ou saisissez un article' : code,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: dp(16),
              fontWeight: FontWeight.w900,
              color: const Color(0xFF11295D),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RoundAction extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _RoundAction({
    required this.dp,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: const CircleBorder(),
    elevation: 5,
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: dp(52),
        height: dp(52),
        child: Icon(icon, color: Colors.white, size: dp(26)),
      ),
    ),
  );
}

class _BarcodeMark extends StatelessWidget {
  final double Function(double) dp;
  const _BarcodeMark({required this.dp});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: dp(62),
    height: dp(42),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final width in const [2.0, 5.0, 2.0, 3.0, 6.0, 2.0, 4.0]) ...[
          Container(width: dp(width), color: Colors.black),
          SizedBox(width: dp(2)),
        ],
      ],
    ),
  );
}

class _ScanBanner extends StatelessWidget {
  final double Function(double) dp;
  const _ScanBanner({required this.dp});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.symmetric(horizontal: dp(16), vertical: dp(14)),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF073DC5), Color(0xFF064BAE)],
      ),
      borderRadius: BorderRadius.circular(dp(18)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x420532A1),
          blurRadius: 18,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Row(
      children: [
        Icon(Icons.qr_code_2_rounded, color: Colors.white, size: dp(42)),
        SizedBox(width: dp(13)),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                color: Colors.white,
                fontSize: dp(16),
                height: 1.25,
              ),
              children: const [
                TextSpan(
                  text: 'Scannez un article\n',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                TextSpan(text: 'pour consulter le tarif'),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _ProductImage extends StatefulWidget {
  final double Function(double) dp;
  final InfoTarifArticleItem article;
  const _ProductImage({required this.dp, required this.article});

  @override
  State<_ProductImage> createState() => _ProductImageState();
}

class _ProductImageState extends State<_ProductImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotation;

  @override
  void initState() {
    super.initState();
    _rotation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _rotation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Center(
    child: Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _rotation,
          builder: (_, _) => CustomPaint(
            size: Size.square(widget.dp(200)),
            painter: _RotatingProductRingPainter(
              progress: _rotation.value,
              strokeWidth: widget.dp(4),
            ),
          ),
        ),
        Container(
          width: widget.dp(188),
          height: widget.dp(188),
          padding: EdgeInsets.all(widget.dp(16)),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFCFE0FF), width: 1.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x26062472),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Image.network(
            widget.article.resolvedPhotoUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const Icon(
              Icons.image_not_supported_outlined,
              size: 72,
              color: Colors.grey,
            ),
          ),
        ),
        Positioned(
          right: widget.dp(1),
          top: widget.dp(1),
          child: Container(
            width: widget.dp(42),
            height: widget.dp(42),
            decoration: const BoxDecoration(
              color: Color(0xFF087F5B),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: widget.dp(27),
            ),
          ),
        ),
      ],
    ),
  );
}

class _RotatingProductRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  const _RotatingProductRingPainter({
    required this.progress,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final ringRect = rect.deflate(strokeWidth / 2);
    final background = Paint()
      ..color = const Color(0xFFCFE9DF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawOval(ringRect, background);

    final active = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF20B486), Color(0xFF087F5B), Color(0xFF034C3A)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    final start = (progress * math.pi * 2) - math.pi / 2;
    canvas.drawArc(ringRect, start, math.pi * 0.95, false, active);
    canvas.drawArc(
      ringRect,
      start + math.pi * 1.18,
      math.pi * 0.48,
      false,
      active,
    );
  }

  @override
  bool shouldRepaint(covariant _RotatingProductRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.strokeWidth != strokeWidth;
}

class _OperationCard extends StatelessWidget {
  final double Function(double) dp;
  final InfoTarifItem operation;
  final DateFormat date;
  const _OperationCard({
    required this.dp,
    required this.operation,
    required this.date,
  });
  @override
  Widget build(BuildContext context) => _WhiteCard(
    dp: dp,
    child: Row(
      children: [
        CircleAvatar(
          radius: dp(31),
          backgroundColor: const Color(0xFFEAF1FF),
          child: Icon(
            Icons.campaign_rounded,
            color: const Color(0xFF073DC5),
            size: dp(34),
          ),
        ),
        SizedBox(width: dp(14)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                operation.label,
                style: TextStyle(
                  color: const Color(0xFF073DC5),
                  fontSize: dp(17),
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: dp(5)),
              Text(
                'du ${date.format(operation.dateDebut)} au ${date.format(operation.dateFin)}',
                style: TextStyle(
                  fontSize: dp(14),
                  color: const Color(0xFF243B68),
                ),
              ),
              Text(
                '- PROMO -',
                style: TextStyle(
                  fontSize: dp(15),
                  color: const Color(0xFF0865E8),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PriceCard extends StatelessWidget {
  final double Function(double) dp;
  final InfoTarifArticleItem article;
  final NumberFormat price;
  const _PriceCard({
    required this.dp,
    required this.article,
    required this.price,
  });
  @override
  Widget build(BuildContext context) {
    final discount = article.prixInitial <= 0
        ? 0
        : ((1 - article.prixPromo / article.prixInitial) * 100).round();
    return _WhiteCard(
      dp: dp,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: dp(182)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PRIX INITIAL',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF23375E),
                    ),
                  ),
                  Text(
                    price.format(article.prixInitial),
                    style: TextStyle(
                      fontSize: dp(30),
                      color: const Color(0xFF8A909E),
                      decoration: TextDecoration.lineThrough,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Divider(height: dp(22)),
                  const Text(
                    'PRIX PROMO',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF23375E),
                    ),
                  ),
                  Text(
                    price.format(article.prixPromo),
                    style: TextStyle(
                      fontSize: dp(34),
                      color: const Color(0xFFE00828),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            _AnimatedDiscountBadge(dp: dp, discount: discount),
          ],
        ),
      ),
    );
  }
}

class _AnimatedDiscountBadge extends StatefulWidget {
  final double Function(double) dp;
  final int discount;
  const _AnimatedDiscountBadge({required this.dp, required this.discount});

  @override
  State<_AnimatedDiscountBadge> createState() => _AnimatedDiscountBadgeState();
}

class _AnimatedDiscountBadgeState extends State<_AnimatedDiscountBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 0.94,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: _pulse,
    child: SizedBox(
      width: widget.dp(162),
      height: widget.dp(162),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: Size.square(widget.dp(150)),
            painter: const _DiscountBadgePainter(),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: widget.dp(15)),
            child: Text(
              '-${widget.discount}%',
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.dp(34),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Positioned(
            bottom: widget.dp(3),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.dp(13),
                vertical: widget.dp(5),
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD83B), Color(0xFFFFB800)],
                ),
                borderRadius: BorderRadius.circular(widget.dp(3)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                'EN POURCENTAGE',
                style: TextStyle(
                  color: const Color(0xFFD90A28),
                  fontSize: widget.dp(9),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DiscountBadgePainter extends CustomPainter {
  const _DiscountBadgePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final inner = outer * 0.88;
    final path = Path();
    const points = 32;
    for (var i = 0; i < points; i++) {
      final angle = -1.5708 + (i * 6.283185307 / points);
      final radius = i.isEven ? outer : inner;
      final point =
          center + Offset(radius * math.cos(angle), radius * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawShadow(path, const Color(0x66000000), 8, true);
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFF3544), Color(0xFFD90022)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TrustCard extends StatelessWidget {
  final double Function(double) dp;
  const _TrustCard({required this.dp});
  @override
  Widget build(BuildContext context) => _WhiteCard(
    dp: dp,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const [
        _TrustItem(icon: Icons.verified_user_outlined, label: 'Tarifs à jour'),
        _TrustItem(icon: Icons.sell_outlined, label: 'Promo limitée'),
        _TrustItem(icon: Icons.percent_rounded, label: 'Économisez'),
      ],
    ),
  );
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustItem({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFF073DC5), size: 30),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _WhiteCard extends StatelessWidget {
  final double Function(double) dp;
  final Widget child;
  const _WhiteCard({required this.dp, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(dp(18)),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(dp(20)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x16062472),
          blurRadius: 18,
          offset: Offset(0, 7),
        ),
      ],
    ),
    child: child,
  );
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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(dp(24)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          SizedBox(height: dp(12)),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );
}
