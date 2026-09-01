// =============================================================================
// CapMobile — Module Swapp — Détail Info Transfert
// -----------------------------------------------------------------------------
// Fonctionnalité : Types autorisés, réservations, OT, lignes transfert.
// Design         : Thème SWAPP — cartes ombre, chips, bannière C&C.
// UI             : Reproduction capture legacy (Types / Résa / OT) en UI moderne.
// Spécifications : infoTransfertProvider (démo) → fetchInfoTransfert() TODO.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/transfert/providers/info_transfert_provider.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/swapp/pages/produit/detail_produit_page.dart';
import 'package:cap_mobile/swapp/widgets/qr_camera_scanner_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_tool_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cap_mobile/core/apiswap/produit/providers/swapp_product_provider.dart';

/// Fiche Info Transfert — magasin destination choisi.
class InfoTransfertDetailPage extends ConsumerStatefulWidget {
  final int codeMagDest;
  final String? nomMagDest;

  const InfoTransfertDetailPage({
    super.key,
    required this.codeMagDest,
    this.nomMagDest,
  });

  static Route<void> fadeRoute({
    required int codeMagDest,
    String? nomMagDest,
  }) => swappMenuFadeRoute(
    InfoTransfertDetailPage(codeMagDest: codeMagDest, nomMagDest: nomMagDest),
  );

  @override
  ConsumerState<InfoTransfertDetailPage> createState() =>
      _InfoTransfertDetailPageState();
}

class _InfoTransfertDetailPageState
    extends ConsumerState<InfoTransfertDetailPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(infoTransfertProvider.notifier)
          .fetchFiche(
            codeMagDest: widget.codeMagDest,
            nomMagDest: widget.nomMagDest,
          );
    });
  }

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
    await _openProduct(code.trim());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(infoTransfertProvider);
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.35);
    double dp(double v) => v * scale;
    final top = MediaQuery.paddingOf(context).top;
    final fiche = state.fiche;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: SwappMenuColors.panel,
      ),
      child: Scaffold(
        backgroundColor: SwappMenuColors.bg,
        body: Column(
          children: [
            DecoratedBox(
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
                padding: EdgeInsets.fromLTRB(
                  dp(4),
                  top + dp(4),
                  dp(16),
                  dp(12),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: SwappMenuColors.ink,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transfert',
                            style: TextStyle(
                              fontSize: dp(20),
                              fontWeight: FontWeight.w900,
                              color: SwappMenuColors.ink,
                            ),
                          ),
                          Text(
                            'Vers mag. ${widget.codeMagDest}'
                            '${widget.nomMagDest != null ? ' · ${widget.nomMagDest}' : ''}',
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
                  ],
                ),
              ),
            ),
            Expanded(
              child: state.isLoading && fiche == null
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null && fiche == null
                  ? Center(child: Text(state.error!))
                  : ListView(
                      padding: EdgeInsets.fromLTRB(
                        dp(16),
                        dp(12),
                        dp(16),
                        dp(24),
                      ),
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: dp(14),
                            vertical: dp(12),
                          ),
                          decoration: BoxDecoration(
                            color: SwappMenuColors.panel,
                            borderRadius: BorderRadius.circular(dp(16)),
                            boxShadow: [
                              BoxShadow(
                                color: SwappMenuColors.ink.withValues(
                                  alpha: 0.08,
                                ),
                                blurRadius: dp(12),
                                offset: Offset(0, dp(4)),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Actions',
                                  style: TextStyle(
                                    fontSize: dp(12),
                                    fontWeight: FontWeight.w800,
                                    color: SwappMenuColors.ink,
                                  ),
                                ),
                              ),
                              SwappCompactToolbar(
                                buttonSize: dp(36),
                                gap: dp(8),
                                onQrScan: _openQrScanner,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: dp(14)),
                        _OutlinedInfoCard(
                          dp: dp,
                          title: 'Types autorisé(s)',
                          accent: const Color(0xFFE53935),
                          child: Wrap(
                            spacing: dp(8),
                            runSpacing: dp(8),
                            children: [
                              for (final type
                                  in fiche?.typesAutorises ?? const <String>[])
                                _TypeChip(dp: dp, label: type),
                            ],
                          ),
                        ),
                        SizedBox(height: dp(12)),
                        _OutlinedInfoCard(
                          dp: dp,
                          title: 'Info Réservation',
                          accent: SwappMenuColors.p3,
                          child: Column(
                            children: [
                              for (final r in fiche?.reservations ?? const [])
                                _InfoLine(
                                  dp: dp,
                                  left: r.codeArticle,
                                  right: '${r.quantite} · ${r.statut}',
                                  onTap: () => _openProduct(r.codeArticle),
                                ),
                              if (fiche?.reservations.isEmpty ?? true)
                                _EmptyHint(dp: dp, text: 'Aucune réservation'),
                            ],
                          ),
                        ),
                        SizedBox(height: dp(12)),
                        _OutlinedInfoCard(
                          dp: dp,
                          title: 'Info OT',
                          accent: SwappMenuColors.p3,
                          child: Column(
                            children: [
                              for (final ot in fiche?.ots ?? const [])
                                _InfoLine(
                                  dp: dp,
                                  left: ot.otId,
                                  right: '${ot.codeArticle} · x${ot.quantite}',
                                  onTap: () => _openProduct(ot.codeArticle),
                                ),
                              if (fiche?.ots.isEmpty ?? true)
                                _EmptyHint(dp: dp, text: 'Aucun OT'),
                            ],
                          ),
                        ),
                        SizedBox(height: dp(12)),
                        _OutlinedInfoCard(
                          dp: dp,
                          title: 'Info Transfert',
                          accent: SwappMenuColors.indigo,
                          child: Column(
                            children: [
                              for (final line in fiche?.lignes ?? const [])
                                _InfoLine(
                                  dp: dp,
                                  left: line.codeArticle,
                                  right: 'x${line.quantite} · ${line.statut}',
                                  subtitle: line.libelle,
                                  onTap: () => _openProduct(line.codeArticle),
                                ),
                              if (fiche?.lignes.isEmpty ?? true)
                                _EmptyHint(
                                  dp: dp,
                                  text: 'Aucun transfert en cours',
                                ),
                            ],
                          ),
                        ),
                        if ((fiche?.clickAndCollectAEmballer ?? 0) > 0) ...[
                          SizedBox(height: dp(16)),
                          _OmniBanner(
                            dp: dp,
                            count: fiche!.clickAndCollectAEmballer,
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlinedInfoCard extends StatelessWidget {
  final double Function(double) dp;
  final String title;
  final Color accent;
  final Widget child;

  const _OutlinedInfoCard({
    required this.dp,
    required this.title,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(dp(14), dp(12), dp(14), dp(12)),
      decoration: BoxDecoration(
        color: SwappMenuColors.panel,
        borderRadius: BorderRadius.circular(dp(16)),
        boxShadow: [
          BoxShadow(
            color: SwappMenuColors.ink.withValues(alpha: 0.08),
            blurRadius: dp(14),
            offset: Offset(0, dp(5)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: dp(10), vertical: dp(4)),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(dp(8)),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: dp(12),
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
          SizedBox(height: dp(10)),
          child,
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final double Function(double) dp;
  final String label;

  const _TypeChip({required this.dp, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(6)),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(dp(20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: dp(12),
          fontWeight: FontWeight.w800,
          color: const Color(0xFFE53935),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final double Function(double) dp;
  final String left;
  final String right;
  final String? subtitle;
  final VoidCallback onTap;

  const _InfoLine({
    required this.dp,
    required this.left,
    required this.right,
    required this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(dp(10)),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: dp(8)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    left,
                    style: TextStyle(
                      fontSize: dp(13),
                      fontWeight: FontWeight.w800,
                      color: SwappMenuColors.ink,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: dp(2)),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dp(10),
                        color: SwappMenuColors.inkDim,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              right,
              style: TextStyle(
                fontSize: dp(11),
                fontWeight: FontWeight.w700,
                color: SwappMenuColors.inkDim,
              ),
            ),
            SizedBox(width: dp(4)),
            Icon(
              Icons.arrow_forward_rounded,
              size: dp(16),
              color: SwappMenuColors.indigo,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final double Function(double) dp;
  final String text;

  const _EmptyHint({required this.dp, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: dp(8)),
      child: Text(
        text,
        style: TextStyle(fontSize: dp(12), color: SwappMenuColors.inkDim),
      ),
    );
  }
}

class _OmniBanner extends StatelessWidget {
  final double Function(double) dp;
  final int count;

  const _OmniBanner({required this.dp, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dp(14), vertical: dp(12)),
      decoration: BoxDecoration(
        color: SwappMenuColors.ink,
        borderRadius: BorderRadius.circular(dp(28)),
        boxShadow: [
          BoxShadow(
            color: SwappMenuColors.ink.withValues(alpha: 0.25),
            blurRadius: dp(12),
            offset: Offset(0, dp(4)),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.swap_horiz_rounded,
            color: SwappMenuColors.p6,
            size: dp(20),
          ),
          SizedBox(width: dp(10)),
          Expanded(
            child: Text(
              'Notifications omnicanales : $count C&C(s) à emballer.',
              style: TextStyle(
                fontSize: dp(12),
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
