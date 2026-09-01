// =============================================================================
// CapMobile — Module Swapp — Colis dépôt (bouton + popup + chips)
// -----------------------------------------------------------------------------
// Fonctionnalité : Bouton colis clignotant, popup Wrap+Chip, confirmation libération.
// UI             : Bouton après le prix hero ; popup grande ; alertes confirmation.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/core/widgets/app_popup.dart';
import 'package:cap_mobile/swapp/models/product_stock_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bouton colis emballage — animation pulse + anneaux ; affiché après le prix hero.
class ColisDepotPackButton extends StatefulWidget {
  final int pendingCount;
  final double Function(double) dp;
  final double Function(double) sp;
  final VoidCallback onTap;
  final bool visible;

  const ColisDepotPackButton({
    super.key,
    required this.pendingCount,
    required this.dp,
    required this.sp,
    required this.onTap,
    this.visible = true,
  });

  @override
  State<ColisDepotPackButton> createState() => _ColisDepotPackButtonState();
}

/// État du bouton colis — gère les AnimationController (pulse, anneaux, reflet).
class _ColisDepotPackButtonState extends State<ColisDepotPackButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _loop;
  Animation<double>? _scale;
  Animation<double>? _ring;
  Animation<double>? _shine;

  static const _amber = Color(0xFFF59E0B);
  static const _amberDark = Color(0xFFD97706);
  static const _deepOrange = Color(0xFFEA580C);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _syncLoop();
  }

  @override
  void reassemble() {
    super.reassemble();
    _disposeAnimations();
    _initAnimations();
    _syncLoop();
  }

  void _initAnimations() {
    if (_loop != null) return;
    final loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _loop = loop;
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.07), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.07, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: loop, curve: Curves.easeInOut));
    _ring = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: loop, curve: Curves.easeOut),
    );
    _shine = Tween<double>(begin: -0.4, end: 1.4).animate(
      CurvedAnimation(parent: loop, curve: Curves.easeInOut),
    );
  }

  void _disposeAnimations() {
    _loop?.dispose();
    _loop = null;
    _scale = null;
    _ring = null;
    _shine = null;
  }

  @override
  void didUpdateWidget(ColisDepotPackButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _initAnimations();
    _syncLoop();
  }

  void _syncLoop() {
    final loop = _loop;
    if (loop == null) return;
    final active = widget.visible && widget.pendingCount > 0;
    if (active) {
      if (!loop.isAnimating) loop.repeat();
    } else {
      loop.stop();
      loop.reset();
    }
  }

  @override
  void dispose() {
    _disposeAnimations();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible || widget.pendingCount <= 0) {
      _syncLoop();
      return const SizedBox.shrink();
    }

    _initAnimations();
    final loop = _loop!;
    final scale = _scale!;
    final ring = _ring!;
    final shine = _shine!;

    final size = widget.dp(30);

    return SizedBox(
      width: widget.dp(36),
      height: size,
      child: OverflowBox(
        maxWidth: widget.dp(48),
        maxHeight: widget.dp(48),
        alignment: Alignment.center,
        child: AnimatedBuilder(
        animation: loop,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Anneau pulse extérieur
              Transform.scale(
                scale: 0.72 + ring.value * 0.55,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _deepOrange.withValues(
                        alpha: (1 - ring.value) * 0.55,
                      ),
                      width: 2,
                    ),
                  ),
                ),
              ),
              // Anneau pulse intérieur (décalé)
              Transform.scale(
                scale: 0.85 + ((ring.value + 0.35) % 1.0) * 0.35,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _amber.withValues(
                        alpha: (1 - ((ring.value + 0.35) % 1.0)) * 0.4,
                      ),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              Transform.scale(
                scale: scale.value,
                child: child,
              ),
            ],
          );
        },
        child: Material(
          color: Colors.transparent,
          elevation: 4,
          shadowColor: _deepOrange.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(widget.dp(12)),
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onTap();
            },
            borderRadius: BorderRadius.circular(widget.dp(12)),
            child: Ink(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.dp(12)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(_amber, _amberDark, scale.value - 1)!,
                    _deepOrange,
                  ],
                ),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _deepOrange.withValues(alpha: 0.35),
                    blurRadius: widget.dp(10),
                    offset: Offset(0, widget.dp(3)),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // Reflet animé
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(widget.dp(12)),
                      child: Transform.translate(
                        offset: Offset(
                          widget.dp(30) * shine.value,
                          0,
                        ),
                        child: Container(
                          width: widget.dp(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                AppColors.white.withValues(alpha: 0.28),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.move_to_inbox_rounded,
                    size: widget.dp(16),
                    color: AppColors.white,
                  ),
                  Positioned(
                    top: -widget.dp(3),
                    right: -widget.dp(3),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.dp(5),
                        vertical: widget.dp(2),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(widget.dp(10)),
                        border: Border.all(color: AppColors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.45),
                            blurRadius: widget.dp(4),
                          ),
                        ],
                      ),
                      child: Text(
                        '${widget.pendingCount}',
                        style: TextStyle(
                          fontSize: widget.sp(9),
                          fontWeight: FontWeight.w900,
                          color: AppColors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}

/// Ouvre la grande popup colis dépôt (fade + scale) avec liste de chips cliquables.
Future<void> showColisDepotPopup({
  required BuildContext context,
  required List<ColisDepotChip> chips,
  required double Function(double) dp,
  required double Function(double) sp,
  required ValueChanged<String> onReleased,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Colis dépôt',
    barrierColor: AppColors.primaryDark.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim1, anim2) {
      return _ColisDepotPopup(
        chips: chips,
        dp: dp,
        sp: sp,
        onReleased: onReleased,
      );
    },
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Popup colis dépôt — en-tête gradient + Wrap chips + dialogues confirmation
// UI     : Modal centrée 92 % largeur ; ferme auto quand tous les colis sont traités.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
/// Popup modale — affiche les chips colis restants et gère le flux confirmation/succès.
class _ColisDepotPopup extends StatefulWidget {
  final List<ColisDepotChip> chips;
  final double Function(double) dp;
  final double Function(double) sp;
  final ValueChanged<String> onReleased;

  const _ColisDepotPopup({
    required this.chips,
    required this.dp,
    required this.sp,
    required this.onReleased,
  });

  @override
  State<_ColisDepotPopup> createState() => _ColisDepotPopupState();
}

/// État popup — liste mutable des chips visibles ; retire un chip après libération réussie.
class _ColisDepotPopupState extends State<_ColisDepotPopup> {
  late List<ColisDepotChip> _visible;

  @override
  void initState() {
    super.initState();
    _visible = List<ColisDepotChip>.from(widget.chips);
  }

  Future<void> _onChipTap(ColisDepotChip chip) async {
    final confirmed = await _showConfirmDialog(chip);
    if (!confirmed || !mounted) return;

    widget.onReleased(chip.id);
    setState(() => _visible.removeWhere((c) => c.id == chip.id));

    if (!mounted) return;
    await _showSuccessDialog();

    if (!mounted) return;
    if (_visible.isEmpty) Navigator.of(context).pop();
  }

  Future<bool> _showConfirmDialog(ColisDepotChip chip) {
    return AppPopup.choice(
      context,
      tone: chip.isDepotResa ? AppPopupTone.warning : AppPopupTone.primary,
      icon: chip.isDepotResa
          ? Icons.lock_open_rounded
          : Icons.inventory_2_rounded,
      title: chip.isDepotResa
          ? 'Confirmer le déblocage ?'
          : 'Confirmer le pari colis ?',
      badge: chip.label,
    );
  }

  Future<void> _showSuccessDialog() {
    return AppPopup.success(
      context,
      title: 'Libération effectuée avec succès',
      message: 'Le colis a été traité.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.sizeOf(context).width * 0.92,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(widget.dp(20)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.18),
                blurRadius: widget.dp(24),
                offset: Offset(0, widget.dp(10)),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  widget.dp(16),
                  widget.dp(14),
                  widget.dp(10),
                  widget.dp(14),
                ),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.move_to_inbox_rounded,
                      color: AppColors.white,
                      size: widget.dp(22),
                    ),
                    SizedBox(width: widget.dp(10)),
                    Expanded(
                      child: Text(
                        'Colis dépôt',
                        style: TextStyle(
                          fontSize: widget.sp(16),
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close_rounded,
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(widget.dp(14)),
                  child: _visible.isEmpty
                      ? Padding(
                          padding: EdgeInsets.symmetric(vertical: widget.dp(24)),
                          child: Text(
                            'Tous les colis ont été traités.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: widget.sp(13),
                              fontStyle: FontStyle.italic,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: widget.dp(8),
                          runSpacing: widget.dp(8),
                          children: [
                            for (final chip in _visible)
                              _TappableColisChip(
                                dp: widget.dp,
                                sp: widget.sp,
                                chip: chip,
                                onTap: () => _onChipTap(chip),
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

// ---------------------------------------------------------------------------
// Chip colis tappable — style résa (orange) ou pari dépôt (violet)
// UI     : InkWell + Chip Material ; déclenche confirmation au tap.
// Auteur : H.AMIZIANI
// ---------------------------------------------------------------------------
/// Chip cliquable — libellé colis dépôt/résa ; ouvre le dialogue de confirmation.
class _TappableColisChip extends StatelessWidget {
  final double Function(double) dp;
  final double Function(double) sp;
  final ColisDepotChip chip;
  final VoidCallback onTap;

  const _TappableColisChip({
    required this.dp,
    required this.sp,
    required this.chip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = chip.isDepotResa
        ? AppColors.orange.withValues(alpha: 0.12)
        : const Color(0xFFEDE9FE);
    final border = chip.isDepotResa
        ? AppColors.orange.withValues(alpha: 0.45)
        : const Color(0xFF7C3AED).withValues(alpha: 0.35);
    final fg = chip.isDepotResa ? AppColors.orange : const Color(0xFF5B21B6);
    final icon =
        chip.isDepotResa ? Icons.lock_open_rounded : Icons.inventory_2_outlined;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(dp(18)),
        child: Chip(
          avatar: Icon(icon, size: dp(16), color: fg),
          label: Text(
            chip.label,
            style: TextStyle(
              fontSize: sp(11),
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.25,
            ),
          ),
          backgroundColor: bg,
          side: BorderSide(color: border),
          padding: EdgeInsets.symmetric(horizontal: dp(4), vertical: dp(2)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(dp(18)),
          ),
        ),
      ),
    );
  }
}
