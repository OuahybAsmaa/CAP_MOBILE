// =============================================================================
// CapMobile — Module Swapp — Choix transporteur
// -----------------------------------------------------------------------------
// Fonctionnalité : Sélection du transporteur (Remise / Demande d'enlèvement).
// Design         : AppBar indigo · liste radio dans carte blanche (maquette).
// UI             : Ouvert depuis InfoTransfertMenuPage (2 tuiles).
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Transporteur sélectionnable (démo — brancher API plus tard).
class TransporteurOption {
  final String id;
  final String label;
  final String? subtitle;
  final bool isDefault;

  /// Asset logo (PNG ou SVG) sous `assets/transporteurs/`.
  final String logoAsset;

  const TransporteurOption({
    required this.id,
    required this.label,
    required this.logoAsset,
    this.subtitle,
    this.isDefault = false,
  });

  bool get isSvg => logoAsset.toLowerCase().endsWith('.svg');
}

const kTransporteursDemo = <TransporteurOption>[
  TransporteurOption(
    id: 'chaussea',
    label: 'Transport Chaussea',
    subtitle: 'Transporteur habituel',
    logoAsset: 'assets/transporteurs/chaussea.svg',
    isDefault: true,
  ),
  TransporteurOption(
    id: 'dr',
    label: 'Transporteur DR',
    logoAsset: 'assets/transporteurs/dr.png',
  ),
  TransporteurOption(
    id: 'geodis',
    label: 'Geodis',
    logoAsset: 'assets/transporteurs/geodis.svg',
  ),
  TransporteurOption(
    id: 'ups',
    label: 'UPS',
    logoAsset: 'assets/transporteurs/ups.svg',
  ),
];

/// Page « Remise au Transporteur » / « Demande d'enlèvement » — même UI.
class RemiseTransporteurPage extends StatefulWidget {
  /// Titre AppBar (ex. Remise au Transporteur).
  final String title;

  /// Liste des transporteurs (démo par défaut).
  final List<TransporteurOption> transporteurs;

  const RemiseTransporteurPage({
    super.key,
    required this.title,
    this.transporteurs = kTransporteursDemo,
  });

  static Route<void> fadeRoute({required String title}) =>
      swappMenuFadeRoute(RemiseTransporteurPage(title: title));

  @override
  State<RemiseTransporteurPage> createState() => _RemiseTransporteurPageState();
}

class _RemiseTransporteurPageState extends State<RemiseTransporteurPage> {
  static const _appBarIndigo = Color(0xFF5551E7);
  static const _checkGreen = Color(0xFF22C55E);
  static const _selectedBg = Color(0xFFEDEAFB);

  late String _selectedId;

  @override
  void initState() {
    super.initState();
    final preferred = widget.transporteurs.where((t) => t.isDefault);
    _selectedId = preferred.isNotEmpty
        ? preferred.first.id
        : widget.transporteurs.first.id;
  }

  TransporteurOption get _selected =>
      widget.transporteurs.firstWhere((t) => t.id == _selectedId);

  void _goNext() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selected.label} — bientôt'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.35);
    double dp(double v) => v * scale;
    final top = MediaQuery.paddingOf(context).top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: _appBarIndigo),
      child: Scaffold(
        backgroundColor: SwappMenuColors.bg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AppBar(
              top: top,
              dp: dp,
              title: widget.title,
              onBack: () => Navigator.pop(context),
              onForward: _goNext,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(dp(16), dp(18), dp(16), dp(24)),
                children: [
                  Text(
                    'CHOISISSEZ VOTRE TRANSPORTEUR',
                    style: TextStyle(
                      fontSize: dp(11),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: SwappMenuColors.inkDim,
                    ),
                  ),
                  SizedBox(height: dp(12)),
                  Container(
                    decoration: BoxDecoration(
                      color: SwappMenuColors.panel,
                      borderRadius: BorderRadius.circular(dp(18)),
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
                        for (
                          var i = 0;
                          i < widget.transporteurs.length;
                          i++
                        ) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: SwappMenuColors.ink.withValues(
                                alpha: 0.06,
                              ),
                            ),
                          _CarrierRow(
                            dp: dp,
                            option: widget.transporteurs[i],
                            selected: widget.transporteurs[i].id == _selectedId,
                            selectedBg: _selectedBg,
                            checkGreen: _checkGreen,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedId = widget.transporteurs[i].id;
                              });
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
// AppBar indigo
// ---------------------------------------------------------------------------
class _AppBar extends StatelessWidget {
  final double top;
  final double Function(double) dp;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onForward;

  const _AppBar({
    required this.top,
    required this.dp,
    required this.title,
    required this.onBack,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _RemiseTransporteurPageState._appBarIndigo,
      child: Padding(
        padding: EdgeInsets.fromLTRB(dp(12), top + dp(8), dp(12), dp(12)),
        child: Row(
          children: [
            _SquareNav(dp: dp, icon: Icons.arrow_back_rounded, onTap: onBack),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: dp(16),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.15,
                ),
              ),
            ),
            _SquareNav(
              dp: dp,
              icon: Icons.arrow_forward_rounded,
              onTap: onForward,
            ),
          ],
        ),
      ),
    );
  }
}

class _SquareNav extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final VoidCallback onTap;

  const _SquareNav({required this.dp, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(dp(10)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(10)),
        child: SizedBox(
          width: dp(40),
          height: dp(40),
          child: Icon(icon, color: Colors.white, size: dp(22)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logo transporteur (PNG / SVG)
// ---------------------------------------------------------------------------
class _CarrierLogo extends StatelessWidget {
  final double Function(double) dp;
  final TransporteurOption option;

  const _CarrierLogo({required this.dp, required this.option});

  @override
  Widget build(BuildContext context) {
    final size = dp(42);
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(dp(5)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(dp(12)),
        border: Border.all(color: SwappMenuColors.ink.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: SwappMenuColors.ink.withValues(alpha: 0.05),
            blurRadius: dp(6),
            offset: Offset(0, dp(2)),
          ),
        ],
      ),
      child: option.isSvg
          ? SvgPicture.asset(
              option.logoAsset,
              fit: BoxFit.contain,
              placeholderBuilder: (_) => Icon(
                Icons.local_shipping_outlined,
                color: SwappMenuColors.indigo,
                size: dp(20),
              ),
            )
          : Image.asset(
              option.logoAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => Icon(
                Icons.local_shipping_outlined,
                color: SwappMenuColors.indigo,
                size: dp(20),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Ligne transporteur
// ---------------------------------------------------------------------------
class _CarrierRow extends StatelessWidget {
  final double Function(double) dp;
  final TransporteurOption option;
  final bool selected;
  final Color selectedBg;
  final Color checkGreen;
  final VoidCallback onTap;

  const _CarrierRow({
    required this.dp,
    required this.option,
    required this.selected,
    required this.selectedBg,
    required this.checkGreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? selectedBg : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dp(14), vertical: dp(14)),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: dp(26),
                height: dp(26),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? checkGreen : Colors.transparent,
                  border: selected
                      ? null
                      : Border.all(
                          color: SwappMenuColors.ink.withValues(alpha: 0.28),
                          width: 1.6,
                        ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: dp(16),
                      )
                    : null,
              ),
              SizedBox(width: dp(12)),
              _CarrierLogo(dp: dp, option: option),
              SizedBox(width: dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: dp(15),
                        fontWeight: FontWeight.w800,
                        color: SwappMenuColors.ink,
                      ),
                    ),
                    if (option.subtitle != null) ...[
                      SizedBox(height: dp(2)),
                      Text(
                        option.subtitle!,
                        style: TextStyle(
                          fontSize: dp(12),
                          fontWeight: FontWeight.w500,
                          color: SwappMenuColors.inkDim,
                        ),
                      ),
                    ],
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
