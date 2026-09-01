// =============================================================================
// CapMobile — Module Swapp — Saisie magasin destination Transfert
// -----------------------------------------------------------------------------
// Fonctionnalité : Saisir le n° magasin + quantité prévue (transfert inter-magasin).
// Design         : AppBar indigo · bandeau teal · carte Vers / Qté · Continuer.
// UI             : Chevron / Continuer → InfoTransfertDetailPage si saisie valide.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/swapp/data/test_magasins.dart';
import 'package:cap_mobile/swapp/pages/transfert/info_transfert_detail_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_attente_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Écran « Vers quel magasin ? » — étape 1 du transfert inter-magasin.
class InfoTransfertDestinationPage extends StatefulWidget {
  const InfoTransfertDestinationPage({super.key});

  static Route<void> fadeRoute() =>
      swappMenuFadeRoute(const InfoTransfertDestinationPage());

  @override
  State<InfoTransfertDestinationPage> createState() =>
      _InfoTransfertDestinationPageState();
}

class _InfoTransfertDestinationPageState
    extends State<InfoTransfertDestinationPage> {
  final _magController = TextEditingController();
  final _qtyController = TextEditingController(text: '0');
  final _magFocus = FocusNode();
  final _qtyFocus = FocusNode();

  static const _accentPink = Color(0xFFE85A9B);
  static const _appBarIndigo = Color(0xFF5551E7);

  @override
  void dispose() {
    _magController.dispose();
    _qtyController.dispose();
    _magFocus.dispose();
    _qtyFocus.dispose();
    super.dispose();
  }

  int? get _codeMag {
    final raw = _magController.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  String? get _nomMag {
    final code = _codeMag;
    if (code == null) return null;
    return storeLabelFor(code, testMagasins);
  }

  int? get _qty {
    final raw = _qtyController.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  bool get _canContinue =>
      _codeMag != null && _codeMag! > 0 && _qty != null && _qty! > 0;

  void _goNext() {
    if (!_canContinue) {
      HapticFeedback.heavyImpact();
      final msg = _codeMag == null || _codeMag! <= 0
          ? 'Indiquez le numéro de magasin.'
          : 'La quantité prévue est obligatoire.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      InfoTransfertDetailPage.fadeRoute(
        codeMagDest: _codeMag!,
        nomMagDest: _nomMag,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.35);
    double dp(double v) => v * scale;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: _appBarIndigo),
      child: Scaffold(
        backgroundColor: SwappMenuColors.bg,
        body: Column(
          children: [
            _IndigoAppBar(
              top: top,
              dp: dp,
              canContinue: _canContinue,
              onBack: () => Navigator.pop(context),
              onForward: _goNext,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(dp(16), dp(16), dp(16), dp(12)),
                children: [
                  SwappInstructionBanner(
                    dp: dp,
                    icon: Icons.grid_view_rounded,
                    text:
                        'Saisissez le numéro de magasin vers lequel vous '
                        'souhaitez effectuer votre transfert.',
                  ),
                  SizedBox(height: dp(16)),
                  _FormCard(
                    dp: dp,
                    magController: _magController,
                    qtyController: _qtyController,
                    magFocus: _magFocus,
                    qtyFocus: _qtyFocus,
                    nomMag: _canContinue || (_codeMag != null && _codeMag! > 0)
                        ? (_nomMag ?? 'Mag. $_codeMag')
                        : null,
                    onChanged: () => setState(() {}),
                    onSubmit: _goNext,
                    accentPink: _accentPink,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                dp(16),
                dp(4),
                dp(16),
                bottom + dp(16),
              ),
              child: _ContinueButton(
                dp: dp,
                enabled: _canContinue,
                onTap: _goNext,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AppBar indigo — retour / titre / suivant
// ---------------------------------------------------------------------------
class _IndigoAppBar extends StatelessWidget {
  final double top;
  final double Function(double) dp;
  final bool canContinue;
  final VoidCallback onBack;
  final VoidCallback onForward;

  const _IndigoAppBar({
    required this.top,
    required this.dp,
    required this.canContinue,
    required this.onBack,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _InfoTransfertDestinationPageState._appBarIndigo,
      child: Padding(
        padding: EdgeInsets.fromLTRB(dp(12), top + dp(8), dp(12), dp(12)),
        child: Row(
          children: [
            _SquareNavButton(
              dp: dp,
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            ),
            Expanded(
              child: Text(
                'Transfert',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: dp(20),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            _SquareNavButton(
              dp: dp,
              icon: Icons.arrow_forward_rounded,
              onTap: onForward,
              muted: !canContinue,
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareNavButton extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final VoidCallback onTap;
  final bool muted;

  const _SquareNavButton({
    required this.dp,
    required this.icon,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: muted ? 0.18 : 0.28),
      borderRadius: BorderRadius.circular(dp(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(10)),
        child: SizedBox(
          width: dp(40),
          height: dp(40),
          child: Icon(
            icon,
            color: Colors.white.withValues(alpha: muted ? 0.55 : 1),
            size: dp(22),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte formulaire Vers + Quantité
// ---------------------------------------------------------------------------
class _FormCard extends StatelessWidget {
  final double Function(double) dp;
  final TextEditingController magController;
  final TextEditingController qtyController;
  final FocusNode magFocus;
  final FocusNode qtyFocus;
  final String? nomMag;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;
  final Color accentPink;

  const _FormCard({
    required this.dp,
    required this.magController,
    required this.qtyController,
    required this.magFocus,
    required this.qtyFocus,
    required this.nomMag,
    required this.onChanged,
    required this.onSubmit,
    required this.accentPink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(dp(16), dp(18), dp(14), dp(18)),
      decoration: BoxDecoration(
        color: SwappMenuColors.panel,
        borderRadius: BorderRadius.circular(dp(20)),
        boxShadow: [
          BoxShadow(
            color: SwappMenuColors.ink.withValues(alpha: 0.08),
            blurRadius: dp(18),
            offset: Offset(0, dp(6)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldRow(
            dp: dp,
            label: 'Vers',
            labelSuffix: null,
            controller: magController,
            focusNode: magFocus,
            hint: 'Quel magasin ?',
            icon: Icons.storefront_rounded,
            accentPink: accentPink,
            onChanged: onChanged,
            onSubmit: () => qtyFocus.requestFocus(),
          ),
          if (nomMag != null) ...[
            SizedBox(height: dp(6)),
            Padding(
              padding: EdgeInsets.only(left: dp(2)),
              child: Text(
                nomMag!,
                style: TextStyle(
                  fontSize: dp(12),
                  fontWeight: FontWeight.w700,
                  color: SwappMenuColors.indigo,
                ),
              ),
            ),
          ],
          SizedBox(height: dp(14)),
          Divider(height: 1, thickness: 1, color: SwappMenuColors.line),
          SizedBox(height: dp(14)),
          _FieldRow(
            dp: dp,
            label: 'Quantité Prévue',
            labelSuffix: '(*Obligatoire*)',
            controller: qtyController,
            focusNode: qtyFocus,
            hint: '0',
            icon: Icons.inventory_2_outlined,
            accentPink: accentPink,
            onChanged: onChanged,
            onSubmit: onSubmit,
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final double Function(double) dp;
  final String label;
  final String? labelSuffix;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final Color accentPink;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  const _FieldRow({
    required this.dp,
    required this.label,
    required this.labelSuffix,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    required this.accentPink,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: label,
                      style: TextStyle(
                        fontSize: dp(15),
                        fontWeight: FontWeight.w800,
                        color: SwappMenuColors.ink,
                      ),
                    ),
                    if (labelSuffix != null)
                      TextSpan(
                        text: '  $labelSuffix',
                        style: TextStyle(
                          fontSize: dp(12),
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                          color: SwappMenuColors.inkDim,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: dp(6)),
              TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => onChanged(),
                onSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: SwappMenuColors.inkDim,
                    fontWeight: FontWeight.w600,
                    fontSize: dp(14),
                  ),
                  contentPadding: EdgeInsets.only(bottom: dp(8)),
                  border: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: SwappMenuColors.ink.withValues(alpha: 0.18),
                    ),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: SwappMenuColors.ink.withValues(alpha: 0.18),
                    ),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: SwappMenuColors.indigo,
                      width: 1.6,
                    ),
                  ),
                ),
                style: TextStyle(
                  fontSize: dp(15),
                  fontWeight: FontWeight.w800,
                  color: SwappMenuColors.ink,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: dp(12)),
        Material(
          color: accentPink,
          borderRadius: BorderRadius.circular(dp(12)),
          elevation: 2,
          shadowColor: accentPink.withValues(alpha: 0.45),
          child: InkWell(
            onTap: () {
              focusNode.requestFocus();
              SystemChannels.textInput.invokeMethod('TextInput.show');
            },
            borderRadius: BorderRadius.circular(dp(12)),
            child: SizedBox(
              width: dp(48),
              height: dp(48),
              child: Icon(icon, color: Colors.white, size: dp(24)),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Bouton Continuer
// ---------------------------------------------------------------------------
class _ContinueButton extends StatelessWidget {
  final double Function(double) dp;
  final bool enabled;
  final VoidCallback onTap;

  const _ContinueButton({
    required this.dp,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? SwappMenuColors.indigo
          : SwappMenuColors.indigo.withValues(alpha: 0.40),
      borderRadius: BorderRadius.circular(dp(28)),
      elevation: enabled ? 6 : 0,
      shadowColor: SwappMenuColors.indigo.withValues(alpha: 0.45),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(28)),
        child: SizedBox(
          width: double.infinity,
          height: dp(52),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continuer',
                style: TextStyle(
                  fontSize: dp(16),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: dp(8)),
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: dp(22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
