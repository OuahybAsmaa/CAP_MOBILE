// =============================================================================
// CapMobile — Module Swapp — Kit UI listes « en attente »
// -----------------------------------------------------------------------------
// Fonctionnalité : Briques partagées des écrans de reprise (OT de transfert,
//                  retours dépôt) — header navy, statistiques, cartes, sélection,
//                  bandeau d'instruction teal.
// Design         : Header navy #2B2B6E · cartes stats #3C3C88 · cartes blanches
//                  arrondies avec pastille icône, chip articles orange et date.
// UI             : Consommé par OperationsTransfertPage, RetourDepotPage,
//                  CompteurSelectionPage et InfoTransfertDestinationPage ;
//                  [SwappAttenteCard] accepte un leading/trailing pour adapter
//                  la sélection (pastille) ou la suppression (corbeille), et un
//                  onDoubleTap vers le détail des articles.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';

/// Couleurs propres aux écrans de reprise (header sombre).
abstract final class SwappAttenteColors {
  /// Fond du header et de la status bar.
  static const headerNavy = Color(0xFF2B2B6E);

  /// Fond des deux cartes statistiques du header.
  static const statCard = Color(0xFF3C3C88);
}

// ---------------------------------------------------------------------------
// Header navy — navigation + deux compteurs
// ---------------------------------------------------------------------------
/// En-tête sombre : retour, titre, création (+), reprise (→) et statistiques.
class SwappAttenteHeader extends StatelessWidget {
  final double Function(double) dp;
  final double top;
  final String title;

  /// Compteur de gauche (nombre de lignes en attente).
  final int nbEnAttente;

  /// Libellé du compteur de gauche (ex. « OTS EN ATTENTE »).
  final String labelEnAttente;

  /// Total d'articles cumulés sur toutes les lignes.
  final int nbArticles;

  final VoidCallback onBack;
  final VoidCallback onCreate;
  final VoidCallback onForward;

  /// Flèche → active uniquement quand une reprise est possible.
  final bool forwardEnabled;

  const SwappAttenteHeader({
    super.key,
    required this.dp,
    required this.top,
    required this.title,
    required this.nbEnAttente,
    required this.labelEnAttente,
    required this.nbArticles,
    required this.onBack,
    required this.onCreate,
    required this.onForward,
    required this.forwardEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SwappAttenteColors.headerNavy,
      child: Padding(
        padding: EdgeInsets.fromLTRB(dp(14), top + dp(8), dp(14), dp(16)),
        child: Column(
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
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: dp(17),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                SizedBox(width: dp(8)),
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 3,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onCreate,
                    child: SizedBox(
                      width: dp(40),
                      height: dp(40),
                      child: Icon(
                        Icons.add_rounded,
                        color: SwappAttenteColors.headerNavy,
                        size: dp(24),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: dp(10)),
                SwappAttenteNavSquare(
                  dp: dp,
                  icon: Icons.arrow_forward_rounded,
                  onTap: onForward,
                  muted: !forwardEnabled,
                ),
              ],
            ),
            SizedBox(height: dp(14)),
            Row(
              children: [
                Expanded(
                  child: SwappAttenteStatCard(
                    dp: dp,
                    value: '$nbEnAttente',
                    label: labelEnAttente,
                  ),
                ),
                SizedBox(width: dp(12)),
                Expanded(
                  child: SwappAttenteStatCard(
                    dp: dp,
                    value: '$nbArticles',
                    label: 'ARTICLES AU TOTAL',
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

/// Bouton carré translucide des headers sombres (retour, suivant).
class SwappAttenteNavSquare extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final VoidCallback onTap;

  /// Estompé quand l'action n'est pas disponible.
  final bool muted;

  const SwappAttenteNavSquare({
    super.key,
    required this.dp,
    required this.icon,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: muted ? 0.14 : 0.24),
      borderRadius: BorderRadius.circular(dp(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(12)),
        child: SizedBox(
          width: dp(40),
          height: dp(40),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: muted ? 0.5 : 1),
            size: dp(22),
          ),
        ),
      ),
    );
  }
}

/// Carte compteur des headers sombres — grande valeur + libellé.
class SwappAttenteStatCard extends StatelessWidget {
  final double Function(double) dp;
  final String value;
  final String label;

  const SwappAttenteStatCard({
    super.key,
    required this.dp,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(dp(14), dp(10), dp(14), dp(12)),
      decoration: BoxDecoration(
        color: SwappAttenteColors.statCard,
        borderRadius: BorderRadius.circular(dp(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: dp(20),
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.1,
            ),
          ),
          SizedBox(height: dp(2)),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: dp(9.5),
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.72),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bandeau d'instruction teal
// ---------------------------------------------------------------------------
/// Bandeau dégradé teal — consigne de l'étape en cours.
class SwappInstructionBanner extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final String text;

  const SwappInstructionBanner({
    super.key,
    required this.dp,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dp(14)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF0F766E), Color(0xFF0D9488)],
        ),
        borderRadius: BorderRadius.circular(dp(18)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.30),
            blurRadius: dp(14),
            offset: Offset(0, dp(5)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: dp(48),
            height: dp(48),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(dp(12)),
            ),
            child: Icon(icon, color: Colors.white, size: dp(26)),
          ),
          SizedBox(width: dp(14)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: dp(13.5),
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Barre de section — titre gris + actions à droite
// ---------------------------------------------------------------------------
/// Ligne « VOS … EN ATTENTE » avec les actions de sélection à droite.
class SwappAttenteSectionBar extends StatelessWidget {
  final double Function(double) dp;
  final String title;
  final List<Widget> actions;

  const SwappAttenteSectionBar({
    super.key,
    required this.dp,
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(dp(18), dp(16), dp(14), dp(12)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: dp(12),
                fontWeight: FontWeight.w800,
                color: SwappMenuColors.inkDim,
                letterSpacing: 0.6,
              ),
            ),
          ),
          for (final action in actions) ...[SizedBox(width: dp(8)), action],
        ],
      ),
    );
  }
}

/// Actions de la barre de section — pilule « Sélectionner » hors mode, contrôles
/// de sélection multiple (tout cocher, supprimer, quitter) une fois le mode actif.
class SwappAttenteSelectionActions extends StatelessWidget {
  final double Function(double) dp;
  final bool selectionMode;
  final bool hasItems;
  final bool allSelected;
  final bool hasSelection;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleAll;
  final VoidCallback onDeleteSelected;

  const SwappAttenteSelectionActions({
    super.key,
    required this.dp,
    required this.selectionMode,
    required this.hasItems,
    required this.allSelected,
    required this.hasSelection,
    required this.onToggleMode,
    required this.onToggleAll,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (!selectionMode) {
      if (!hasItems) return const SizedBox.shrink();
      return SwappAttentePill(
        dp: dp,
        icon: Icons.check_circle_outline_rounded,
        label: 'Sélectionner',
        onTap: onToggleMode,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: allSelected ? 'Tout désélectionner' : 'Tout sélectionner',
          child: InkWell(
            onTap: onToggleAll,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: EdgeInsets.all(dp(4)),
              child: SwappAttenteSelectDot(dp: dp, selected: allSelected),
            ),
          ),
        ),
        SizedBox(width: dp(8)),
        SwappAttenteDeleteButton(
          dp: dp,
          onTap: onDeleteSelected,
          enabled: hasSelection,
        ),
        SizedBox(width: dp(8)),
        SwappAttentePill(
          dp: dp,
          icon: Icons.close_rounded,
          label: 'Terminé',
          onTap: onToggleMode,
          active: true,
        ),
      ],
    );
  }
}

/// Pastille de sélection — vide (contour gris) ou cochée (indigo plein).
class SwappAttenteSelectDot extends StatelessWidget {
  final double Function(double) dp;
  final bool selected;

  const SwappAttenteSelectDot({
    super.key,
    required this.dp,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: dp(22),
      height: dp(22),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? SwappMenuColors.indigo : Colors.transparent,
        border: selected
            ? null
            : Border.all(
                color: SwappMenuColors.ink.withValues(alpha: 0.22),
                width: 1.8,
              ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, color: Colors.white, size: dp(14))
          : null,
    );
  }
}

/// Bouton pilule d'action de section (ex. « Sélectionner »).
class SwappAttentePill extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Plein indigo quand le mode est actif, pastel sinon.
  final bool active;

  const SwappAttentePill({
    super.key,
    required this.dp,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active ? Colors.white : SwappMenuColors.indigo;

    return Material(
      color: active ? SwappMenuColors.indigo : SwappMenuColors.p1Bg,
      borderRadius: BorderRadius.circular(dp(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(18)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dp(11), vertical: dp(7)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: dp(15), color: fg),
              SizedBox(width: dp(6)),
              Text(
                label,
                style: TextStyle(
                  fontSize: dp(12),
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton corbeille rouge — section (suppression multiple) ou ligne.
class SwappAttenteDeleteButton extends StatelessWidget {
  final double Function(double) dp;
  final VoidCallback onTap;
  final bool enabled;

  const SwappAttenteDeleteButton({
    super.key,
    required this.dp,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AppColors.error : AppColors.error.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(dp(11)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(11)),
        child: SizedBox(
          width: dp(34),
          height: dp(32),
          child: Icon(
            Icons.delete_outline_rounded,
            color: Colors.white,
            size: dp(18),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte d'une ligne en attente
// ---------------------------------------------------------------------------
/// Carte blanche : pastille icône, titre, chip « N art. » et date.
class SwappAttenteCard extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final String title;
  final int nbArticles;
  final String dateLabel;
  final bool selected;
  final VoidCallback onTap;

  /// Double tap — ouverture du détail des articles de la ligne.
  final VoidCallback? onDoubleTap;

  /// Inséré avant la pastille icône (ex. [SwappAttenteSelectDot]).
  final Widget? leading;

  /// Inséré en fin de ligne (ex. [SwappAttenteDeleteButton]).
  final Widget? trailing;

  const SwappAttenteCard({
    super.key,
    required this.dp,
    required this.icon,
    required this.title,
    required this.nbArticles,
    required this.dateLabel,
    required this.onTap,
    this.onDoubleTap,
    this.selected = false,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SwappMenuColors.panel,
      borderRadius: BorderRadius.circular(dp(16)),
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        borderRadius: BorderRadius.circular(dp(16)),
        child: Ink(
          decoration: BoxDecoration(
            color: SwappMenuColors.panel,
            borderRadius: BorderRadius.circular(dp(16)),
            border: Border.all(
              color: selected
                  ? SwappMenuColors.indigo
                  : SwappMenuColors.ink.withValues(alpha: 0.05),
              width: selected ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: SwappMenuColors.ink.withValues(alpha: 0.06),
                blurRadius: dp(14),
                offset: Offset(0, dp(4)),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(14)),
          child: Row(
            children: [
              if (leading != null) ...[leading!, SizedBox(width: dp(10))],
              Container(
                width: dp(42),
                height: dp(42),
                decoration: BoxDecoration(
                  color: SwappMenuColors.p1Bg,
                  borderRadius: BorderRadius.circular(dp(12)),
                ),
                child: Icon(icon, color: SwappMenuColors.p1, size: dp(22)),
              ),
              SizedBox(width: dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dp(13.5),
                        fontWeight: FontWeight.w900,
                        color: SwappMenuColors.ink,
                      ),
                    ),
                    SizedBox(height: dp(8)),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: dp(8),
                            vertical: dp(3),
                          ),
                          decoration: BoxDecoration(
                            color: SwappMenuColors.p5Bg,
                            borderRadius: BorderRadius.circular(dp(10)),
                          ),
                          child: Text(
                            '$nbArticles art.',
                            style: TextStyle(
                              fontSize: dp(11.5),
                              fontWeight: FontWeight.w900,
                              color: SwappMenuColors.p5,
                            ),
                          ),
                        ),
                        SizedBox(width: dp(10)),
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: dp(11.5),
                            fontWeight: FontWeight.w600,
                            color: SwappMenuColors.inkDim,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[SizedBox(width: dp(10)), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

/// État vide partagé — icône, titre et conseil.
class SwappAttenteEmptyState extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final String title;
  final String hint;

  const SwappAttenteEmptyState({
    super.key,
    required this.dp,
    required this.icon,
    required this.title,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(dp(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: dp(44), color: SwappMenuColors.inkDim),
            SizedBox(height: dp(10)),
            Text(
              title,
              style: TextStyle(
                fontSize: dp(14),
                fontWeight: FontWeight.w700,
                color: SwappMenuColors.inkDim,
              ),
            ),
            SizedBox(height: dp(4)),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: dp(12),
                color: SwappMenuColors.inkDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Onglets segmentés des headers sombres
// ---------------------------------------------------------------------------
/// Un onglet de [SwappSegmentedTabs] — libellé, icône et compteur optionnels.
class SwappSegment {
  final String label;
  final IconData? icon;

  /// Compteur affiché en pastille à droite du libellé.
  final int? count;

  const SwappSegment({required this.label, this.icon, this.count});
}

/// Sélecteur segmenté sur fond navy — pastille blanche glissante animée.
class SwappSegmentedTabs extends StatelessWidget {
  static const _animation = Duration(milliseconds: 260);
  static const _curve = Curves.easeOutCubic;

  final double Function(double) dp;
  final List<SwappSegment> segments;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const SwappSegmentedTabs({
    super.key,
    required this.dp,
    required this.segments,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final count = segments.length;

    return Container(
      padding: EdgeInsets.all(dp(4)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(dp(16)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            height: dp(38),
            child: Stack(
              children: [
                // Pastille active : glisse d'un onglet à l'autre.
                AnimatedAlign(
                  duration: _animation,
                  curve: _curve,
                  alignment: count < 2
                      ? Alignment.center
                      : Alignment(-1 + 2 * selectedIndex / (count - 1), 0),
                  child: Container(
                    width: constraints.maxWidth / count,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(dp(12)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: dp(8),
                          offset: Offset(0, dp(2)),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < count; i++)
                      Expanded(
                        child: _SegmentButton(
                          dp: dp,
                          segment: segments[i],
                          active: i == selectedIndex,
                          animation: _animation,
                          curve: _curve,
                          onTap: () => onSelect(i),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final double Function(double) dp;
  final SwappSegment segment;
  final bool active;
  final Duration animation;
  final Curve curve;
  final VoidCallback onTap;

  const _SegmentButton({
    required this.dp,
    required this.segment,
    required this.active,
    required this.animation,
    required this.curve,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = active
        ? SwappAttenteColors.headerNavy
        : Colors.white.withValues(alpha: 0.78);

    // Material transparent : l'onde de tap se dessine au-dessus de la pastille.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(12)),
        splashColor: SwappAttenteColors.headerNavy.withValues(alpha: 0.10),
        highlightColor: Colors.white.withValues(alpha: 0.08),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (segment.icon != null) ...[
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: fg),
                duration: animation,
                curve: curve,
                builder: (context, color, _) =>
                    Icon(segment.icon, size: dp(15), color: color),
              ),
              SizedBox(width: dp(6)),
            ],
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: animation,
                curve: curve,
                style: TextStyle(
                  fontSize: dp(12.5),
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
                child: Text(
                  segment.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (segment.count != null) ...[
              SizedBox(width: dp(6)),
              AnimatedContainer(
                duration: animation,
                curve: curve,
                padding: EdgeInsets.symmetric(
                  horizontal: dp(6),
                  vertical: dp(2),
                ),
                decoration: BoxDecoration(
                  color: active
                      ? SwappAttenteColors.headerNavy.withValues(alpha: 0.10)
                      : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(dp(8)),
                ),
                child: Text(
                  '${segment.count}',
                  style: TextStyle(
                    fontSize: dp(11),
                    fontWeight: FontWeight.w900,
                    color: fg,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tableaux de réception — colonnes, en-tête, pastilles et pied de cumul
// ---------------------------------------------------------------------------
/// Largeurs des colonnes chiffrées des tableaux de réception.
///
/// Partagées par l'en-tête, les lignes et le pied fixe pour garder les chiffres
/// alignés d'un bloc à l'autre.
abstract final class SwappTableLayout {
  static const date = 82.0;
  static const total = 50.0;
  static const restant = 58.0;

  /// Colonne d'état (chip Accepté / Refusé).
  static const etat = 86.0;

  /// Marge horizontale cumulée liste + carte — aligne le pied fixe hors carte.
  static const gutter = 26.0;
}

/// Définition d'une colonne d'en-tête de tableau.
class SwappTableColumn {
  final String label;

  /// Largeur fixe ; `null` = colonne extensible.
  final double? width;

  final TextAlign align;

  const SwappTableColumn({
    required this.label,
    this.width,
    this.align = TextAlign.left,
  });
}

/// En-tête sombre d'un tableau de réception.
class SwappTableHeader extends StatelessWidget {
  final double Function(double) dp;
  final List<SwappTableColumn> columns;

  const SwappTableHeader({
    super.key,
    required this.dp,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
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
            for (final column in columns)
              if (column.width == null)
                Expanded(
                  child: Text(
                    column.label,
                    textAlign: column.align,
                    style: style,
                  ),
                )
              else
                SizedBox(
                  width: dp(column.width!),
                  child: Text(
                    column.label,
                    textAlign: column.align,
                    style: style,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// Pastille chiffrée des colonnes Total / Restant.
class SwappCountPill extends StatelessWidget {
  final double Function(double) dp;
  final int value;
  final Color bg;
  final Color fg;

  const SwappCountPill({
    super.key,
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

/// Pied fixe « Quantité totale » — colonnes alignées sur [SwappTableLayout].
class SwappTotalBar extends StatelessWidget {
  final double Function(double) dp;

  /// Inset bas du système (barre de navigation Android).
  final double bottomInset;

  final String label;
  final int total;
  final int restant;

  /// Couleur du restant — orange tant qu'il reste des unités à traiter.
  final Color restantColor;

  const SwappTotalBar({
    super.key,
    required this.dp,
    required this.bottomInset,
    required this.total,
    required this.restant,
    this.label = 'Quantité totale',
    this.restantColor = SwappMenuColors.p5,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SwappMenuColors.ink,
        boxShadow: [
          BoxShadow(
            color: SwappMenuColors.ink.withValues(alpha: 0.28),
            blurRadius: dp(16),
            offset: Offset(0, dp(-4)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          dp(SwappTableLayout.gutter),
          dp(14),
          dp(SwappTableLayout.gutter),
          dp(14) + bottomInset,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: dp(13),
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
            SizedBox(
              width: dp(SwappTableLayout.total),
              child: Text(
                '$total',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: dp(15),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(
              width: dp(SwappTableLayout.restant),
              child: Text(
                '$restant',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: dp(15),
                  fontWeight: FontWeight.w900,
                  color: restantColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
