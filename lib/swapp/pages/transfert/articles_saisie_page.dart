// =============================================================================
// CapMobile — Module Swapp — Articles d'un transfert / retour
// -----------------------------------------------------------------------------
// Fonctionnalité : Détail des lignes saisies — progression validés / alertes /
//                  en attente, tableau ARTICLE · STATUT · STK. · TRF.
// Design         : Header navy (photo + validation) · barre de progression
//                  segmentée · tableau blanc, ligne courante surlignée indigo.
// UI             : Ouverte au double tap sur une carte de OperationsTransfertPage
//                  ou RetourDepotPage ; tap sur une ligne = ligne courante.
// Spécifications : Données [ArticleSaisieDemoData] ; photos via
//                  SwappApiConstants.productPhotoUrl ; API TODO.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/transfert/data/article_saisie_test_data.dart';
import 'package:cap_mobile/core/apiswap/shared/config/swapp_api_constants.dart';
import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/swapp/models/article_saisie_item.dart';
import 'package:cap_mobile/swapp/widgets/swapp_attente_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Flux d'appel — adapte les libellés de l'écran.
enum ArticlesFlux {
  transfert('TRANSFERT', 'ARTICLES DU TRANSFERT'),
  retour('RETOUR DÉPÔT', 'ARTICLES DU RETOUR');

  const ArticlesFlux(this.kicker, this.sectionTitle);

  /// Surtitre affiché au-dessus de la destination.
  final String kicker;

  /// Titre de la section listant les articles.
  final String sectionTitle;
}

/// Écran des articles saisis d'un transfert ou d'un retour.
class ArticlesSaisiePage extends StatefulWidget {
  final ArticlesFlux flux;

  /// Destination affichée en titre (magasin ou dépôt).
  final String destination;

  const ArticlesSaisiePage({
    super.key,
    required this.flux,
    required this.destination,
  });

  static Route<void> fadeRoute({
    required ArticlesFlux flux,
    required String destination,
  }) => swappMenuFadeRoute(
    ArticlesSaisiePage(flux: flux, destination: destination),
  );

  @override
  State<ArticlesSaisiePage> createState() => _ArticlesSaisiePageState();
}

class _ArticlesSaisiePageState extends State<ArticlesSaisiePage> {
  static const _green = Color(0xFF22C55E);
  static const _slate = Color(0xFF64748B);
  static const _cameraBg = Color(0xFF1E1F4E);

  // TODO(API) : remplacer par SwappApiService.fetchArticlesSaisie()
  final _items = ArticleSaisieDemoData.items();

  /// Ligne courante — dernier article scanné (démo : dernière ligne en attente).
  String? _currentId;

  @override
  void initState() {
    super.initState();
    final enAttente = _items
        .where((item) => item.statut == ArticleSaisieStatut.enAttente)
        .toList();
    _currentId = enAttente.isEmpty ? null : enAttente.last.id;
  }

  int _countOf(ArticleSaisieStatut statut) =>
      _items.where((item) => item.statut == statut).length;

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openPhoto() {
    HapticFeedback.selectionClick();
    _snack('Photo du colis — bientôt');
  }

  void _valider() {
    final restants = _items.length - _countOf(ArticleSaisieStatut.valide);
    if (restants > 0) {
      HapticFeedback.heavyImpact();
      _snack(
        '$restants ligne${restants > 1 ? 's' : ''} à contrôler avant validation.',
      );
      return;
    }
    HapticFeedback.mediumImpact();
    _snack('Saisie validée (mode démo)');
  }

  Color _statutColor(ArticleSaisieStatut statut) => switch (statut) {
    ArticleSaisieStatut.valide => _green,
    ArticleSaisieStatut.alerte => AppColors.warning,
    ArticleSaisieStatut.enAttente => _slate,
  };

  IconData _statutIcon(ArticleSaisieStatut statut) => switch (statut) {
    ArticleSaisieStatut.valide => Icons.check_rounded,
    ArticleSaisieStatut.alerte => Icons.warning_amber_rounded,
    ArticleSaisieStatut.enAttente => Icons.schedule_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.35);
    double dp(double v) => v * scale;
    final insets = MediaQuery.paddingOf(context);

    final nbValide = _countOf(ArticleSaisieStatut.valide);
    final nbAlerte = _countOf(ArticleSaisieStatut.alerte);
    final nbAttente = _countOf(ArticleSaisieStatut.enAttente);

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
              kicker: widget.flux.kicker,
              destination: widget.destination,
              nbValide: nbValide,
              nbAlerte: nbAlerte,
              nbAttente: nbAttente,
              green: _green,
              slate: _slate,
              cameraBg: _cameraBg,
              onBack: () => Navigator.pop(context),
              onPhoto: _openPhoto,
              onValider: _valider,
            ),
            SwappAttenteSectionBar(dp: dp, title: widget.flux.sectionTitle),
            Expanded(
              child: ListView(
                // Marge basse = barre de navigation Android incluse.
                padding: EdgeInsets.fromLTRB(
                  dp(14),
                  0,
                  dp(14),
                  dp(24) + insets.bottom,
                ),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: SwappMenuColors.panel,
                      borderRadius: BorderRadius.circular(dp(16)),
                      boxShadow: [
                        BoxShadow(
                          color: SwappMenuColors.ink.withValues(alpha: 0.08),
                          blurRadius: dp(16),
                          offset: Offset(0, dp(5)),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        _TableHeader(dp: dp),
                        for (var i = 0; i < _items.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: SwappMenuColors.ink.withValues(
                                alpha: 0.06,
                              ),
                            ),
                          _ArticleRow(
                            dp: dp,
                            index: i + 1,
                            item: _items[i],
                            current: _items[i].id == _currentId,
                            statutColor: _statutColor(_items[i].statut),
                            statutIcon: _statutIcon(_items[i].statut),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _currentId = _items[i].id);
                            },
                          ),
                        ],
                      ],
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
// Header navy — destination, actions, progression
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final double Function(double) dp;
  final double top;
  final String kicker;
  final String destination;
  final int nbValide;
  final int nbAlerte;
  final int nbAttente;
  final Color green;
  final Color slate;
  final Color cameraBg;
  final VoidCallback onBack;
  final VoidCallback onPhoto;
  final VoidCallback onValider;

  const _Header({
    required this.dp,
    required this.top,
    required this.kicker,
    required this.destination,
    required this.nbValide,
    required this.nbAlerte,
    required this.nbAttente,
    required this.green,
    required this.slate,
    required this.cameraBg,
    required this.onBack,
    required this.onPhoto,
    required this.onValider,
  });

  int get _total => nbValide + nbAlerte + nbAttente;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SwappAttenteColors.headerNavy,
      child: Padding(
        padding: EdgeInsets.fromLTRB(dp(14), top + dp(8), dp(14), dp(14)),
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
                        kicker,
                        style: TextStyle(
                          fontSize: dp(9.5),
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.55),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: dp(2)),
                      Text(
                        destination,
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
                _PhotoButton(dp: dp, bg: cameraBg, dot: green, onTap: onPhoto),
                SizedBox(width: dp(10)),
                Material(
                  color: green,
                  borderRadius: BorderRadius.circular(dp(14)),
                  elevation: 4,
                  shadowColor: green.withValues(alpha: 0.5),
                  child: InkWell(
                    onTap: onValider,
                    borderRadius: BorderRadius.circular(dp(14)),
                    child: SizedBox(
                      width: dp(44),
                      height: dp(44),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: dp(26),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: dp(16)),
            Row(
              children: [
                Text(
                  'Progression',
                  style: TextStyle(
                    fontSize: dp(12.5),
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const Spacer(),
                Text(
                  '$nbValide / $_total articles validés',
                  style: TextStyle(
                    fontSize: dp(12.5),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: dp(8)),
            ClipRRect(
              borderRadius: BorderRadius.circular(dp(6)),
              child: SizedBox(
                height: dp(7),
                child: Row(
                  children: [
                    if (nbValide > 0)
                      Expanded(
                        flex: nbValide,
                        child: ColoredBox(color: green),
                      ),
                    if (nbAlerte > 0)
                      Expanded(
                        flex: nbAlerte,
                        child: const ColoredBox(color: AppColors.warning),
                      ),
                    if (nbAttente > 0)
                      Expanded(
                        flex: nbAttente,
                        child: ColoredBox(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: dp(10)),
            Row(
              children: [
                _Legend(dp: dp, color: green, label: '$nbValide validés'),
                SizedBox(width: dp(14)),
                _Legend(
                  dp: dp,
                  color: AppColors.warning,
                  label: '$nbAlerte alertes',
                ),
                SizedBox(width: dp(14)),
                _Legend(dp: dp, color: slate, label: '$nbAttente en attente'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton appareil photo avec pastille verte « photo disponible ».
class _PhotoButton extends StatelessWidget {
  final double Function(double) dp;
  final Color bg;
  final Color dot;
  final VoidCallback onTap;

  const _PhotoButton({
    required this.dp,
    required this.bg,
    required this.dot,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: bg,
          borderRadius: BorderRadius.circular(dp(14)),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(dp(14)),
            child: SizedBox(
              width: dp(44),
              height: dp(44),
              child: Icon(
                Icons.photo_camera_rounded,
                color: Colors.white,
                size: dp(22),
              ),
            ),
          ),
        ),
        Positioned(
          right: dp(-1),
          top: dp(-1),
          child: Container(
            width: dp(11),
            height: dp(11),
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
              border: Border.all(
                color: SwappAttenteColors.headerNavy,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final double Function(double) dp;
  final Color color;
  final String label;

  const _Legend({required this.dp, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dp(7),
          height: dp(7),
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: dp(5)),
        Text(
          label,
          style: TextStyle(
            fontSize: dp(10.5),
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tableau — en-tête et lignes
// ---------------------------------------------------------------------------
class _TableHeader extends StatelessWidget {
  final double Function(double) dp;

  const _TableHeader({required this.dp});

  @override
  Widget build(BuildContext context) {
    TextStyle style() => TextStyle(
      fontSize: dp(10),
      fontWeight: FontWeight.w800,
      color: Colors.white.withValues(alpha: 0.85),
      letterSpacing: 0.6,
    );

    return ColoredBox(
      color: SwappMenuColors.ink,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(11)),
        child: Row(
          children: [
            Expanded(child: Text('ARTICLE', style: style())),
            SizedBox(
              width: dp(52),
              child: Text(
                'STATUT',
                textAlign: TextAlign.center,
                style: style(),
              ),
            ),
            SizedBox(
              width: dp(38),
              child: Text('STK.', textAlign: TextAlign.center, style: style()),
            ),
            SizedBox(
              width: dp(38),
              child: Text('TRF.', textAlign: TextAlign.center, style: style()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArticleRow extends StatelessWidget {
  final double Function(double) dp;
  final int index;
  final ArticleSaisieItem item;
  final bool current;
  final Color statutColor;
  final IconData statutIcon;
  final VoidCallback onTap;

  const _ArticleRow({
    required this.dp,
    required this.index,
    required this.item,
    required this.current,
    required this.statutColor,
    required this.statutIcon,
    required this.onTap,
  });

  /// Pastille pastel derrière la photo, teintée selon la couleur produit.
  Color get _thumbBg {
    final couleur = item.couleur.toLowerCase();
    if (couleur.contains('rouge') || couleur.contains('rose')) {
      return const Color(0xFFFDE7EF);
    }
    if (couleur.contains('noir')) return const Color(0xFFE9EAEE);
    return const Color(0xFFF1F5F9);
  }

  /// TRF. : vert si validé, orange si alerte, navy plein si en attente.
  ({Color bg, Color fg}) get _trfColors => switch (item.statut) {
    ArticleSaisieStatut.valide => (
      bg: const Color(0xFFDCFCE7),
      fg: const Color(0xFF15803D),
    ),
    ArticleSaisieStatut.alerte => (
      bg: SwappMenuColors.p5Bg,
      fg: SwappMenuColors.p5,
    ),
    ArticleSaisieStatut.enAttente => (
      bg: SwappMenuColors.ink,
      fg: Colors.white,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final trf = _trfColors;

    return Material(
      color: current ? const Color(0xFFEDEAFB) : SwappMenuColors.panel,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: dp(4),
                color: current ? SwappMenuColors.indigo : Colors.transparent,
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(dp(8), dp(10), dp(12), dp(10)),
                  child: Row(
                    children: [
                      _Thumb(dp: dp, item: item, index: index, bg: _thumbBg),
                      SizedBox(width: dp(10)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.codeArticle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: dp(12.5),
                                fontWeight: FontWeight.w900,
                                color: SwappMenuColors.ink,
                              ),
                            ),
                            SizedBox(height: dp(3)),
                            Text(
                              item.displayVariante,
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
                        width: dp(52),
                        child: Center(
                          child: Container(
                            width: dp(30),
                            height: dp(30),
                            decoration: BoxDecoration(
                              color: statutColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statutColor.withValues(alpha: 0.35),
                                  blurRadius: dp(6),
                                  offset: Offset(0, dp(2)),
                                ),
                              ],
                            ),
                            child: Icon(
                              statutIcon,
                              color: Colors.white,
                              size: dp(17),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: dp(38),
                        child: Center(
                          child: _CountBox(
                            dp: dp,
                            value: item.stock,
                            bg: const Color(0xFFF1F5F9),
                            fg: SwappMenuColors.inkDim,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: dp(38),
                        child: Center(
                          child: _CountBox(
                            dp: dp,
                            value: item.quantite,
                            bg: trf.bg,
                            fg: trf.fg,
                          ),
                        ),
                      ),
                    ],
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

/// Photo produit avec badge numéro d'ordre de saisie.
class _Thumb extends StatelessWidget {
  final double Function(double) dp;
  final ArticleSaisieItem item;
  final int index;
  final Color bg;

  const _Thumb({
    required this.dp,
    required this.item,
    required this.index,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final size = dp(44);

    return SizedBox(
      width: size + dp(6),
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(dp(12)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                SwappApiConstants.productPhotoUrl(item.codeArticle),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(
                  Icons.directions_run_rounded,
                  size: dp(22),
                  color: SwappMenuColors.ink.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: dp(18),
              height: dp(18),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: SwappMenuColors.ink,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: dp(9),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pastille chiffrée des colonnes STK. / TRF.
class _CountBox extends StatelessWidget {
  final double Function(double) dp;
  final int value;
  final Color bg;
  final Color fg;

  const _CountBox({
    required this.dp,
    required this.value,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dp(30),
      padding: EdgeInsets.symmetric(vertical: dp(5)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(dp(9)),
      ),
      child: Text(
        '$value',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: dp(12),
          fontWeight: FontWeight.w900,
          color: fg,
        ),
      ),
    );
  }
}
