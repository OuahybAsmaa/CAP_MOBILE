// =============================================================================
// CapMobile — Module Swapp — Panneau « Ranger à l’adresse »
// -----------------------------------------------------------------------------
// Fonctionnalité : Corps alternatif (bouton vert toolbar) — jetons + adresse.
// Design         : Icône ranger, Wrap + Chips jetons, champ micro, bouton vert.
// UI             : Remplace _buildTabBody quand mode ranger actif.
// Spécifications : Données mock [RangerMockData] en attente API.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/core/apiswap/ranger/data/ranger_test_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Layout minimal passé depuis DetailProduitPage (_ProduitLayout helpers).
typedef RangerLayoutScale = double Function(double value);
typedef RangerLayoutFont = double Function(double value);

/// Panneau ranger — système de jeton + saisie adresse + action.
class RangerPanel extends StatefulWidget {
  final RangerLayoutScale dp;
  final RangerLayoutFont sp;

  const RangerPanel({super.key, required this.dp, required this.sp});

  @override
  State<RangerPanel> createState() => _RangerPanelState();
}

class _RangerPanelState extends State<RangerPanel>
    with TickerProviderStateMixin {
  late final TextEditingController _addressController;
  late final AnimationController _tokenPulseController;
  late final Animation<double> _tokenPulse;

  int _tokenCount = RangerMockData.initialTokenCount;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(
      text: RangerMockData.defaultSuggestedAddress(),
    );
    _tokenPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _tokenPulse = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _tokenPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _tokenPulseController.dispose();
    super.dispose();
  }

  Future<void> _onMicTap() async {
    HapticFeedback.lightImpact();
    final address = RangerMockData.mockVoiceAddress();
    setState(() => _addressController.text = address);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Micro (test) : $address'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onRangerTap() async {
    if (_isSubmitting) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    final result = await RangerMockData.submitMock(
      address: _addressController.text,
      tokensBefore: _tokenCount,
    );
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      if (result.success && result.remainingTokens != null) {
        _tokenCount = result.remainingTokens!;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dp = widget.dp;
    final sp = widget.sp;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RangerGlyph(size: dp(52), arrowSize: dp(28)),
              SizedBox(width: dp(10)),
              Expanded(
                child: _TokenSystemCard(
                  dp: dp,
                  sp: sp,
                  tokenCount: _tokenCount,
                  tokenPulse: _tokenPulse,
                ),
              ),
            ],
          ),
          SizedBox(height: dp(16)),
          Text(
            'Ranger à l\'adresse',
            style: TextStyle(
              fontSize: sp(13),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: dp(8)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: _addressController,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(
                    fontSize: sp(13),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Adresse magasin…',
                    hintStyle: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: dp(12),
                      vertical: dp(12),
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: dp(6), right: dp(4)),
                      child: _MicBadge(onTap: _onMicTap, dp: dp),
                    ),
                    prefixIconConstraints: BoxConstraints(
                      minWidth: dp(44),
                      minHeight: dp(44),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(dp(10)),
                      borderSide: const BorderSide(
                        color: AppColors.primaryDark,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(dp(10)),
                      borderSide: BorderSide(
                        color: AppColors.primary,
                        width: dp(2),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: dp(8)),
              Material(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(dp(14)),
                elevation: 3,
                shadowColor: AppColors.success.withValues(alpha: 0.45),
                child: InkWell(
                  borderRadius: BorderRadius.circular(dp(14)),
                  onTap: _isSubmitting ? null : _onRangerTap,
                  child: SizedBox(
                    width: dp(56),
                    height: dp(52),
                    child: _isSubmitting
                        ? Center(
                            child: SizedBox(
                              width: dp(22),
                              height: dp(22),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.white,
                              ),
                            ),
                          )
                        : Center(
                            child: _RangerGlyph(
                              size: dp(40),
                              arrowSize: dp(22),
                              inverted: true,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: dp(10)),
          Text(
            'Mode test · API ranger à brancher',
            style: TextStyle(
              fontSize: sp(10),
              fontStyle: FontStyle.italic,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte « système de jeton » — Wrap + Chips stylisés.
class _TokenSystemCard extends StatelessWidget {
  final RangerLayoutScale dp;
  final RangerLayoutFont sp;
  final int tokenCount;
  final Animation<double> tokenPulse;

  const _TokenSystemCard({
    required this.dp,
    required this.sp,
    required this.tokenCount,
    required this.tokenPulse,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dp(10)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(dp(12)),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: dp(10),
            offset: Offset(0, dp(3)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: dp(4),
                height: dp(28),
                decoration: BoxDecoration(
                  color: AppColors.primaryDark,
                  borderRadius: BorderRadius.circular(dp(2)),
                ),
              ),
              SizedBox(width: dp(8)),
              Expanded(
                child: Text(
                  RangerMockData.tokenSystemLabel,
                  style: TextStyle(
                    fontSize: sp(13),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.2,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: dp(10)),
          Wrap(
            spacing: dp(6),
            runSpacing: dp(6),
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _StatusChip(
                dp: dp,
                sp: sp,
                icon: Icons.verified_rounded,
                label: tokenCount > 0
                    ? '$tokenCount jeton${tokenCount > 1 ? 's' : ''} actif${tokenCount > 1 ? 's' : ''}'
                    : 'Aucun jeton',
                backgroundColor: tokenCount > 0
                    ? AppColors.primarySoft
                    : AppColors.error.withValues(alpha: 0.1),
                foregroundColor: tokenCount > 0
                    ? AppColors.primaryDark
                    : AppColors.error,
                borderColor: tokenCount > 0
                    ? AppColors.primary.withValues(alpha: 0.25)
                    : AppColors.error.withValues(alpha: 0.35),
              ),
              for (var i = 0; i < tokenCount; i++)
                ScaleTransition(
                  scale: tokenPulse,
                  child: _JetonChip(
                    dp: dp,
                    sp: sp,
                    index: i,
                    label: RangerMockData.tokenLabelAt(i),
                  ),
                ),
              if (tokenCount == 0)
                _StatusChip(
                  dp: dp,
                  sp: sp,
                  icon: Icons.info_outline_rounded,
                  label: 'Rechargez via l’API',
                  backgroundColor: AppColors.background,
                  foregroundColor: AppColors.textSecondary,
                  borderColor: AppColors.border,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chip jeton doré — style pill avec icône et libellé.
class _JetonChip extends StatelessWidget {
  final RangerLayoutScale dp;
  final RangerLayoutFont sp;
  final int index;
  final String label;

  const _JetonChip({
    required this.dp,
    required this.sp,
    required this.index,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final goldLight = Color.lerp(
      AppColors.warning,
      Colors.amber.shade100,
      0.35,
    )!;
    final goldDark = Color.lerp(
      AppColors.warning,
      Colors.orange,
      index * 0.12,
    )!;

    return Material(
      elevation: 2,
      shadowColor: AppColors.warning.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(dp(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(dp(20)),
        onTap: () {},
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [goldLight, goldDark],
            ),
            borderRadius: BorderRadius.circular(dp(20)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 1,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: dp(10), vertical: dp(6)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.toll_rounded, size: dp(16), color: AppColors.white),
                SizedBox(width: dp(5)),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: sp(11),
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: 0.15,
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

/// Chip statut — compteur ou info (Material Chip style).
class _StatusChip extends StatelessWidget {
  final RangerLayoutScale dp;
  final RangerLayoutFont sp;
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;

  const _StatusChip({
    required this.dp,
    required this.sp,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: dp(16), color: foregroundColor),
      label: Text(
        label,
        style: TextStyle(
          fontSize: sp(11),
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        ),
      ),
      backgroundColor: backgroundColor,
      side: BorderSide(color: borderColor),
      padding: EdgeInsets.symmetric(horizontal: dp(4)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(dp(20)),
      ),
    );
  }
}

/// Badge micro doré (mock vocal).
class _MicBadge extends StatelessWidget {
  final VoidCallback onTap;
  final RangerLayoutScale dp;

  const _MicBadge({required this.onTap, required this.dp});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warning,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppColors.warning.withValues(alpha: 0.4),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: dp(34),
          height: dp(34),
          child: Icon(Icons.mic_rounded, color: AppColors.white, size: dp(18)),
        ),
      ),
    );
  }
}

/// Icône « flèche vers emplacement » — comme la maquette.
class _RangerGlyph extends StatelessWidget {
  final double size;
  final double arrowSize;
  final bool inverted;

  const _RangerGlyph({
    required this.size,
    required this.arrowSize,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RangerGlyphPainter(
          arrowColor: inverted ? AppColors.white : AppColors.tertiary,
          baseColor: inverted
              ? AppColors.white.withValues(alpha: 0.35)
              : AppColors.textMuted.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}

class _RangerGlyphPainter extends CustomPainter {
  final Color arrowColor;
  final Color baseColor;

  _RangerGlyphPainter({required this.arrowColor, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseRect = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.78),
      width: w * 0.72,
      height: h * 0.22,
    );
    final basePaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;
    canvas.drawOval(baseRect, basePaint);

    final shaftWidth = w * 0.14;
    final arrowTop = h * 0.08;
    final arrowBottom = h * 0.62;
    final centerX = w * 0.5;

    final arrowPath = Path()
      ..moveTo(centerX - shaftWidth, arrowBottom)
      ..lineTo(centerX - shaftWidth, arrowTop + w * 0.18)
      ..lineTo(centerX - w * 0.22, arrowTop + w * 0.18)
      ..lineTo(centerX, arrowTop)
      ..lineTo(centerX + w * 0.22, arrowTop + w * 0.18)
      ..lineTo(centerX + shaftWidth, arrowTop + w * 0.18)
      ..lineTo(centerX + shaftWidth, arrowBottom)
      ..close();

    final arrowPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, arrowPaint);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, h * 0.78),
        width: w * 0.28,
        height: h * 0.1,
      ),
      Paint()..color = arrowColor.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(covariant _RangerGlyphPainter oldDelegate) {
    return oldDelegate.arrowColor != arrowColor ||
        oldDelegate.baseColor != baseColor;
  }
}
