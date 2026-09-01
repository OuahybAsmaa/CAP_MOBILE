// =============================================================================
// CapMobile — Module Swapp — Réception Réassort
// -----------------------------------------------------------------------------
// Fonctionnalité : Bip des colis de réassort — compteurs bipés / acceptés /
//                  refusés, tableau BL · Qte · État, validation de la réception.
// Design         : Header navy (compteurs + scan) · carte résumé vert / rouge ·
//                  tableau blanc · pied de validation fixe.
// UI             : Ouverte par la tuile « Réception du Réassort » de
//                  ReceptionsMenuPage ; « Scanner » bipe le colis démo suivant,
//                  appui long sur une ligne = annuler le bip.
// Spécifications : File [ColisReassortDemoData] ; API TODO.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/reception/data/colis_reassort_test_data.dart';
import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/core/widgets/app_popup.dart';
import 'package:cap_mobile/swapp/models/colis_reassort_item.dart';
import 'package:cap_mobile/swapp/widgets/swapp_attente_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Écran « Réception Réassort » — contrôle des colis au bip.
class ReceptionReassortPage extends StatefulWidget {
  const ReceptionReassortPage({super.key});

  static Route<void> fadeRoute() =>
      swappMenuFadeRoute(const ReceptionReassortPage());

  @override
  State<ReceptionReassortPage> createState() => _ReceptionReassortPageState();
}

class _ReceptionReassortPageState extends State<ReceptionReassortPage> {
  static const _green = Color(0xFF22C55E);
  static const _greenBg = Color(0xFFDCFCE7);
  static const _greenInk = Color(0xFF15803D);
  static const _redBg = Color(0xFFFDE7EA);

  /// Colis déjà bipés — le plus récent en tête.
  final _bipes = <ColisReassortItem>[];

  /// File de démo consommée à chaque bip.
  // TODO(API) : remplacer par le flux DataWedge + contrôle serveur du colis.
  late final List<ColisReassortItem> _fileDemo = ColisReassortDemoData.file();
  int _prochainDemo = 0;

  int get _nbAcceptes => _bipes.where((colis) => colis.accepte).length;

  int get _nbRefuses => _bipes.length - _nbAcceptes;

  int get _nbBls => _bipes.map((colis) => colis.numBl).toSet().length;

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _biper() {
    if (_prochainDemo >= _fileDemo.length) {
      HapticFeedback.heavyImpact();
      _snack('Plus de colis à biper (file de démo terminée)');
      return;
    }

    final colis = _fileDemo[_prochainDemo];
    setState(() {
      _prochainDemo++;
      _bipes.insert(0, colis);
    });

    if (colis.accepte) {
      HapticFeedback.mediumImpact();
      _snack('Colis ${colis.numColis} accepté · BL ${colis.numBl}');
    } else {
      HapticFeedback.heavyImpact();
      _snack('Colis ${colis.numColis} refusé · ${colis.motif}');
    }
  }

  void _annulerBip(ColisReassortItem colis) {
    HapticFeedback.selectionClick();
    setState(() {
      _bipes.removeWhere((item) => item.id == colis.id);
      _prochainDemo = (_prochainDemo - 1).clamp(0, _fileDemo.length);
    });
    _snack('Bip du colis ${colis.numColis} annulé');
  }

  Future<void> _valider() async {
    if (_bipes.isEmpty) {
      HapticFeedback.heavyImpact();
      _snack('Bipez au moins un colis avant de valider.');
      return;
    }

    HapticFeedback.mediumImpact();
    final confirmed = await AppPopup.confirm(
      context,
      icon: Icons.move_to_inbox_rounded,
      title: 'Valider la réception ?',
      message:
          '${_bipes.length} colis bipé(s) sur $_nbBls BL.\n'
          '$_nbAcceptes accepté(s) · $_nbRefuses refusé(s).'
          '${_nbRefuses > 0 ? '\nLes colis refusés ne seront pas intégrés.' : ''}',
    );
    if (confirmed != true || !mounted) return;

    _snack('Réception réassort validée (mode démo)');
  }

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.35);
    double dp(double v) => v * scale;
    final insets = MediaQuery.paddingOf(context);

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
              nbBipes: _bipes.length,
              nbBls: _nbBls,
              onBack: () => Navigator.pop(context),
              onScan: _biper,
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(dp(14), dp(14), dp(14), dp(2)),
              child: _ResumeCard(
                dp: dp,
                nbAcceptes: _nbAcceptes,
                nbRefuses: _nbRefuses,
                green: _green,
                greenBg: _greenBg,
                greenInk: _greenInk,
                redBg: _redBg,
              ),
            ),
            SwappAttenteSectionBar(dp: dp, title: 'COLIS BIPÉS'),
            Expanded(
              child: _bipes.isEmpty
                  ? SwappAttenteEmptyState(
                      dp: dp,
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Aucun colis bipé',
                      hint: 'Scannez un colis pour démarrer la réception.',
                    )
                  : ListView(
                      padding: EdgeInsets.fromLTRB(dp(14), 0, dp(14), dp(16)),
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: SwappMenuColors.panel,
                            borderRadius: BorderRadius.circular(dp(16)),
                            boxShadow: [
                              BoxShadow(
                                color: SwappMenuColors.ink.withValues(
                                  alpha: 0.07,
                                ),
                                blurRadius: dp(14),
                                offset: Offset(0, dp(5)),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              SwappTableHeader(
                                dp: dp,
                                columns: const [
                                  SwappTableColumn(label: 'BL'),
                                  SwappTableColumn(
                                    label: 'QTE',
                                    width: SwappTableLayout.total,
                                    align: TextAlign.right,
                                  ),
                                  SwappTableColumn(
                                    label: 'ÉTAT',
                                    width: SwappTableLayout.etat,
                                    align: TextAlign.right,
                                  ),
                                ],
                              ),
                              for (var i = 0; i < _bipes.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: SwappMenuColors.ink.withValues(
                                      alpha: 0.06,
                                    ),
                                  ),
                                _ColisRow(
                                  dp: dp,
                                  colis: _bipes[i],
                                  green: _green,
                                  greenBg: _greenBg,
                                  greenInk: _greenInk,
                                  redBg: _redBg,
                                  onTap: () => _snack(
                                    _bipes[i].accepte
                                        ? 'Colis ${_bipes[i].numColis} · '
                                              '${_bipes[i].quantite} article(s)'
                                        : 'Refus : ${_bipes[i].motif}',
                                  ),
                                  onLongPress: () => _annulerBip(_bipes[i]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            _ValiderBar(
              dp: dp,
              bottomInset: insets.bottom,
              nbColis: _bipes.length,
              onTap: _valider,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header navy — titre, compteurs et bip
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final double Function(double) dp;
  final double top;
  final int nbBipes;
  final int nbBls;
  final VoidCallback onBack;
  final VoidCallback onScan;

  const _Header({
    required this.dp,
    required this.top,
    required this.nbBipes,
    required this.nbBls,
    required this.onBack,
    required this.onScan,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: SwappAttenteColors.headerNavy,
      child: Padding(
        padding: EdgeInsets.fromLTRB(dp(14), top + dp(8), dp(14), dp(16)),
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
                        'RÉCEPTION',
                        style: TextStyle(
                          fontSize: dp(9.5),
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.55),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: dp(2)),
                      Text(
                        'Réassort',
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
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(dp(12)),
                  elevation: 3,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    onTap: onScan,
                    borderRadius: BorderRadius.circular(dp(12)),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: dp(12),
                        vertical: dp(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            color: SwappAttenteColors.headerNavy,
                            size: dp(18),
                          ),
                          SizedBox(width: dp(6)),
                          Text(
                            'Biper',
                            style: TextStyle(
                              fontSize: dp(12),
                              fontWeight: FontWeight.w900,
                              color: SwappAttenteColors.headerNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: dp(14)),
            Row(
              children: [
                Expanded(
                  child: SwappAttenteStatCard(
                    dp: dp,
                    value: '$nbBipes',
                    label: 'COLIS BIPÉS',
                  ),
                ),
                SizedBox(width: dp(12)),
                Expanded(
                  child: SwappAttenteStatCard(
                    dp: dp,
                    value: '$nbBls',
                    label: 'BL CONCERNÉS',
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

// ---------------------------------------------------------------------------
// Résumé du contrôle — acceptés / refusés
// ---------------------------------------------------------------------------
class _ResumeCard extends StatelessWidget {
  final double Function(double) dp;
  final int nbAcceptes;
  final int nbRefuses;
  final Color green;
  final Color greenBg;
  final Color greenInk;
  final Color redBg;

  const _ResumeCard({
    required this.dp,
    required this.nbAcceptes,
    required this.nbRefuses,
    required this.green,
    required this.greenBg,
    required this.greenInk,
    required this.redBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(12)),
      decoration: BoxDecoration(
        color: SwappMenuColors.panel,
        borderRadius: BorderRadius.circular(dp(16)),
        boxShadow: [
          BoxShadow(
            color: SwappMenuColors.ink.withValues(alpha: 0.06),
            blurRadius: dp(12),
            offset: Offset(0, dp(4)),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ResumeCounter(
              dp: dp,
              icon: Icons.check_rounded,
              value: nbAcceptes,
              label: 'Acceptés',
              color: green,
              bg: greenBg,
              ink: greenInk,
            ),
          ),
          Container(
            width: 1,
            height: dp(38),
            color: SwappMenuColors.ink.withValues(alpha: 0.07),
          ),
          Expanded(
            child: _ResumeCounter(
              dp: dp,
              icon: Icons.block_rounded,
              value: nbRefuses,
              label: 'Refusés',
              color: AppColors.error,
              bg: redBg,
              ink: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumeCounter extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final int value;
  final String label;
  final Color color;
  final Color bg;
  final Color ink;

  const _ResumeCounter({
    required this.dp,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: dp(34),
          height: dp(34),
          decoration: BoxDecoration(
            color: value > 0 ? color : bg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: dp(19),
            color: value > 0 ? Colors.white : ink,
          ),
        ),
        SizedBox(width: dp(10)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: dp(19),
                fontWeight: FontWeight.w900,
                color: SwappMenuColors.ink,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: dp(10.5),
                fontWeight: FontWeight.w700,
                color: SwappMenuColors.inkDim,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Ligne du tableau
// ---------------------------------------------------------------------------
class _ColisRow extends StatelessWidget {
  final double Function(double) dp;
  final ColisReassortItem colis;
  final Color green;
  final Color greenBg;
  final Color greenInk;
  final Color redBg;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _ColisRow({
    required this.dp,
    required this.colis,
    required this.green,
    required this.greenBg,
    required this.greenInk,
    required this.redBg,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SwappMenuColors.panel,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(11)),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      colis.numBl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dp(13),
                        fontWeight: FontWeight.w900,
                        color: SwappMenuColors.ink,
                      ),
                    ),
                    SizedBox(height: dp(2)),
                    Text(
                      colis.numColis,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dp(11),
                        fontWeight: FontWeight.w600,
                        color: SwappMenuColors.inkDim,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: dp(SwappTableLayout.total),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SwappCountPill(
                    dp: dp,
                    value: colis.quantite,
                    bg: const Color(0xFFF1F5F9),
                    fg: SwappMenuColors.inkDim,
                  ),
                ),
              ),
              SizedBox(
                width: dp(SwappTableLayout.etat),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: dp(9),
                      vertical: dp(5),
                    ),
                    decoration: BoxDecoration(
                      color: colis.accepte ? greenBg : redBg,
                      borderRadius: BorderRadius.circular(dp(20)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          colis.accepte
                              ? Icons.check_circle_rounded
                              : Icons.block_rounded,
                          size: dp(13),
                          color: colis.accepte ? greenInk : AppColors.error,
                        ),
                        SizedBox(width: dp(4)),
                        Text(
                          colis.etat.label,
                          style: TextStyle(
                            fontSize: dp(10.5),
                            fontWeight: FontWeight.w800,
                            color: colis.accepte ? greenInk : AppColors.error,
                          ),
                        ),
                      ],
                    ),
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

/// Pied fixe — validation de la réception.
class _ValiderBar extends StatelessWidget {
  final double Function(double) dp;
  final double bottomInset;
  final int nbColis;
  final VoidCallback onTap;

  const _ValiderBar({
    required this.dp,
    required this.bottomInset,
    required this.nbColis,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final actif = nbColis > 0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: SwappMenuColors.panel,
        boxShadow: [
          BoxShadow(
            color: SwappMenuColors.ink.withValues(alpha: 0.10),
            blurRadius: dp(16),
            offset: Offset(0, dp(-4)),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          dp(14),
          dp(12),
          dp(14),
          dp(12) + bottomInset,
        ),
        child: Material(
          color: actif
              ? SwappAttenteColors.headerNavy
              : SwappMenuColors.ink.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(dp(14)),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(dp(14)),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: dp(14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: dp(19),
                    color: Colors.white,
                  ),
                  SizedBox(width: dp(8)),
                  Text(
                    actif
                        ? 'Valider la réception ($nbColis)'
                        : 'Valider la réception',
                    style: TextStyle(
                      fontSize: dp(14.5),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
