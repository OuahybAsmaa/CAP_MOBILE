// =============================================================================
// CapMobile — Module Swapp — Kit UI menu (indigo)
// -----------------------------------------------------------------------------
// Fonctionnalité : Composants partagés des menus SWApp (hub + sous-menus).
// Design         : Palette indigo, en-tête blanc, grilles 3 colonnes, tuiles
//                  de hauteur fixe (alignement visuel uniforme).
// UI             : SwappMenuShell enveloppe toute page menu ; SwappMenuSection
//                  affiche une grille Wrap ; SwappMenuTile = carte cliquable.
// Spécifications : Consommé par SwappMenuPage et SwappInfosProduitMenuPage ;
//                  authProvider pour avatar agent et magasin.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/features/auth/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Tokens couleur — palette indigo SWApp
// UI     : Fond lavande, cartes blanches, pastels icônes p1…p6.
// ---------------------------------------------------------------------------
/// Couleurs du design system menu SWApp (indigo).
abstract final class SwappMenuColors {
  /// Fond page menu (lavande clair).
  static const bg = Color(0xFFEEF0FA);

  /// Texte principal (titres tuiles, SWAPP).
  static const ink = Color(0xFF1B1D2B);

  /// Texte secondaire (sous-titres, compteur section).
  static const inkDim = Color(0xFF8C8FA3);

  /// Cartes tuiles et en-tête (blanc).
  static const panel = Color(0xFFFFFFFF);

  /// Ligne shimmer section (gris très léger).
  static const line = Color(0x0F1B1D2B);

  /// Accent indigo (barre pulse, icône notification).
  static const indigo = Color(0xFF4640D6);

  /// Pastel 1 — violet (icône + fond).
  static const p1Bg = Color(0xFFECEAFB);
  static const p1 = Color(0xFF6355D9);

  /// Pastel 2 — vert.
  static const p2Bg = Color(0xFFDDF5EA);
  static const p2 = Color(0xFF10A96C);

  /// Pastel 3 — teal.
  static const p3Bg = Color(0xFFD9F1F6);
  static const p3 = Color(0xFF159AAF);

  /// Pastel 4 — lavande.
  static const p4Bg = Color(0xFFE8E7FC);
  static const p4 = Color(0xFF6E6BDE);

  /// Pastel 5 — orange.
  static const p5Bg = Color(0xFFFDECD9);
  static const p5 = Color(0xFFDE8A2C);

  /// Pastel 6 — rose.
  static const p6Bg = Color(0xFFFBE1EC);
  static const p6 = Color(0xFFD3548A);
}

// ---------------------------------------------------------------------------
// Layout grille — espacements et dimensions tuiles
// UI     : 3 colonnes ; tuiles même largeur ET même hauteur (tileHeight).
// ---------------------------------------------------------------------------
/// Constantes de mise en page — modifier ici pour ajuster la grille.
abstract final class SwappMenuLayout {
  /// Espace vertical entre sections (ex. Consultation → RFID).
  static const sectionGap = 10.0;

  /// Espace entre titre de section et grille de tuiles.
  static const headToGridGap = 14.0;

  /// Espace horizontal entre tuiles (colonnes).
  static const gridCrossSpacing = 8.0;

  /// Espace vertical entre lignes de tuiles.
  static const gridMainSpacing = 8.0;

  /// Nombre de colonnes par ligne (grille 3×N).
  static const gridColumnCount = 3;

  /// Espace sous l'en-tête blanc SWAPP.
  static const headerToContentGap = 10.0;

  /// Hauteur fixe de chaque tuile — garantit des boutons de même taille.
  static const tileHeight = 80.0;
}

/// Données d'une tuile menu — titre, sous-titre, icône colorée et callback tap.
class SwappMenuTileData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback? onTap;

  const SwappMenuTileData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.onTap,
  });
}

/// Données d'une section menu — libellé, compteur affiché et liste de tuiles.
class SwappMenuSectionData {
  final String title;
  final String count;
  final List<SwappMenuTileData> tiles;

  const SwappMenuSectionData({
    required this.title,
    required this.count,
    required this.tiles,
  });
}

/// Affiche un SnackBar « bientôt disponible » pour les tuiles non branchées.
void swappMenuSoonSnackBar(BuildContext context, String label) {
  HapticFeedback.selectionClick();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$label · bientôt disponible'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}

/// Style des barres système Swapp.
///
/// [SystemUiOverlayStyle.light] et `.dark` imposent une barre de navigation
/// Android noire : on la repasse sur le fond de l'app pour éviter le cadre noir
/// en bas d'écran. [statusBarIcons] = couleur des icônes de la status bar.
SystemUiOverlayStyle swappOverlayStyle({
  required Color statusBarColor,
  Brightness statusBarIcons = Brightness.light,
}) {
  final base = statusBarIcons == Brightness.light
      ? SystemUiOverlayStyle.light
      : SystemUiOverlayStyle.dark;

  return base.copyWith(
    statusBarColor: statusBarColor,
    systemNavigationBarColor: SwappMenuColors.bg,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  );
}

/// Route fade-in réutilisable pour toutes les pages menu Swapp.
Route<void> swappMenuFadeRoute(Widget page) => PageRouteBuilder<void>(
  pageBuilder: (_, _, _) => page,
  transitionsBuilder: (_, anim, _, child) =>
      FadeTransition(opacity: anim, child: child),
  transitionDuration: const Duration(milliseconds: 300),
);

// ---------------------------------------------------------------------------
// Coque page menu — en-tête blanc + ListView sections
// UI     : Structure commune SwappMenuPage et SwappInfosProduitMenuPage.
// ---------------------------------------------------------------------------
/// Scaffold menu indigo — en-tête agent + liste de [SwappMenuSection].
class SwappMenuShell extends ConsumerWidget {
  final List<SwappMenuSectionData> sections;

  const SwappMenuShell({super.key, required this.sections});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collab = ref.watch(authProvider).collaborateur;
    if (collab == null) return const SizedBox.shrink();

    final photoUrl = ref
        .read(authProvider.notifier)
        .getPhotoUrl(collab.codeCollab);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: SwappMenuColors.panel,
      ),
      child: Scaffold(
        backgroundColor: SwappMenuColors.bg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: SwappMenuColors.panel,
                boxShadow: [
                  BoxShadow(
                    color: SwappMenuColors.ink.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  4,
                  MediaQuery.paddingOf(context).top + 4,
                  16,
                  14,
                ),
                child: SwappMenuAgentHeader(
                  collabPrenom: collab.prenom,
                  collabNom: collab.nom,
                  magasin: collab.magasinNom,
                  photoUrl: photoUrl,
                  onBack: () => Navigator.pop(context),
                ),
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                bottom: true,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    SwappMenuLayout.headerToContentGap,
                    16,
                    32,
                  ),
                  children: [
                    for (var i = 0; i < sections.length; i++) ...[
                      if (i > 0)
                        const SizedBox(height: SwappMenuLayout.sectionGap),
                      SwappMenuSection(section: sections[i]),
                    ],
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

/// Calcule les initiales avatar si la photo agent est indisponible.
String swappMenuInitiales(String prenom, String nom) {
  final p = prenom.trim();
  final n = nom.trim();
  if (p.isNotEmpty && n.isNotEmpty) {
    return '${p[0]}${n[0]}'.toUpperCase();
  }
  return (p.isNotEmpty ? p : n).substring(0, 1).toUpperCase();
}

// ---------------------------------------------------------------------------
// En-tête agent — retour, avatar, SWAPP, magasin, notifications
// ---------------------------------------------------------------------------
/// Barre blanche compacte — avatar agent, titre SWAPP et magasin courant.
class SwappMenuAgentHeader extends StatelessWidget {
  final String collabPrenom;
  final String collabNom;
  final String magasin;
  final String photoUrl;
  final VoidCallback onBack;

  const SwappMenuAgentHeader({
    super.key,
    required this.collabPrenom,
    required this.collabNom,
    required this.magasin,
    required this.photoUrl,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: SwappMenuColors.ink,
            tooltip: 'Retour',
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          Stack(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: SwappMenuColors.indigo.withValues(alpha: 0.25),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: SwappMenuColors.indigo.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: SwappMenuColors.p1Bg,
                  backgroundImage: photoUrl.isNotEmpty
                      ? NetworkImage(photoUrl)
                      : null,
                  onBackgroundImageError: photoUrl.isNotEmpty
                      ? (_, _) {}
                      : null,
                  child: photoUrl.isEmpty
                      ? Text(
                          swappMenuInitiales(collabPrenom, collabNom),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: SwappMenuColors.indigo,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    color: SwappMenuColors.p2,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: SwappMenuColors.panel,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'SWAPP',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: SwappMenuColors.ink,
                    letterSpacing: 1.6,
                  ),
                ),
                Text(
                  magasin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: SwappMenuColors.inkDim,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: SwappMenuColors.p1Bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: SwappMenuColors.indigo,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section menu — en-tête animé + grille Wrap tuiles taille fixe
// ---------------------------------------------------------------------------
/// Bloc section — titre animé + grille 3 colonnes de [SwappMenuTile].
class SwappMenuSection extends StatelessWidget {
  final SwappMenuSectionData section;

  const SwappMenuSection({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SwappMenuSectionHead(title: section.title, count: section.count),
        const SizedBox(height: SwappMenuLayout.headToGridGap),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = SwappMenuLayout.gridColumnCount;
            final gap = SwappMenuLayout.gridCrossSpacing;
            final tileWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;

            return Wrap(
              spacing: gap,
              runSpacing: SwappMenuLayout.gridMainSpacing,
              children: [
                for (final tile in section.tiles)
                  SizedBox(
                    width: tileWidth,
                    height: SwappMenuLayout.tileHeight,
                    child: SwappMenuTile(tile: tile),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// En-tête section — barre pulse, titre, shimmer, compteur
// ---------------------------------------------------------------------------
/// Ligne « Consultation ——— 04 » au-dessus de chaque grille.
class SwappMenuSectionHead extends StatefulWidget {
  final String title;
  final String count;

  const SwappMenuSectionHead({
    super.key,
    required this.title,
    required this.count,
  });

  @override
  State<SwappMenuSectionHead> createState() => _SwappMenuSectionHeadState();
}

/// État animation — pulse barre indigo + shimmer ligne horizontale.
class _SwappMenuSectionHeadState extends State<SwappMenuSectionHead>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 22,
          child: Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (context, child) {
                final scaleY = 1.0 + _ctrl.value * 0.35;
                final glow = 0.1 + _ctrl.value * 0.22;
                return Transform.scale(
                  scaleY: scaleY,
                  alignment: Alignment.center,
                  child: Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: SwappMenuColors.indigo,
                      boxShadow: [
                        BoxShadow(
                          color: SwappMenuColors.indigo.withValues(alpha: glow),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: SwappMenuColors.ink,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _SwappMenuShimmerLine(animation: _ctrl)),
        const SizedBox(width: 20),
        Text(
          widget.count,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10.5,
            color: SwappMenuColors.inkDim,
            letterSpacing: 0.02,
          ),
        ),
      ],
    );
  }
}

/// Ligne horizontale animée — effet shimmer entre titre et compteur.
class _SwappMenuShimmerLine extends StatelessWidget {
  final Animation<double> animation;

  const _SwappMenuShimmerLine({required this.animation});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final w = constraints.maxWidth;
            final left = -w * 0.35 + animation.value * w * 1.35;
            return Container(
              height: 2,
              decoration: BoxDecoration(
                color: SwappMenuColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  Positioned(
                    left: left,
                    top: 0,
                    bottom: 0,
                    width: w * 0.35,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            SwappMenuColors.indigo.withValues(alpha: 0.85),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Tuile menu — carte blanche hauteur fixe, icône + titre + sous-titre
// ---------------------------------------------------------------------------
/// Carte cliquable — remplit [SwappMenuLayout.tileHeight] pour taille uniforme.
class SwappMenuTile extends StatelessWidget {
  final SwappMenuTileData tile;

  const SwappMenuTile({super.key, required this.tile});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SwappMenuColors.panel,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: tile.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: SwappMenuColors.ink.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: -8,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: tile.iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(tile.icon, size: 15, color: tile.iconColor),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tile.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: SwappMenuColors.ink,
                        height: 1.15,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      tile.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: SwappMenuColors.inkDim,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
