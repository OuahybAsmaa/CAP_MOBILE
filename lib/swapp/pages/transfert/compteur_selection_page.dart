// =============================================================================
// CapMobile — Module Swapp — Choix du compteur (transfert / retour)
// -----------------------------------------------------------------------------
// Fonctionnalité : Choisir le compteur (dépôt) vers lequel créer une saisie ;
//                  seule la consigne du bandeau change selon le flux appelant.
// Design         : Header navy · bandeau teal · champ de recherche · liste des
//                  compteurs disponibles (pastille colis + N° + chevron).
// UI             : Ouverte par le + de OperationsTransfertPage et de
//                  RetourDepotPage ; compteur choisi → InfoTransfertDetailPage.
// Spécifications : Données [CompteurDemoData] ; filtrage via CompteurItem.matches ;
//                  consignes prêtes à l'emploi dans [CompteurSelectionTextes].
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/transfert/data/compteur_test_data.dart';
import 'package:cap_mobile/swapp/models/compteur_item.dart';
import 'package:cap_mobile/swapp/pages/transfert/info_transfert_detail_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_attente_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Consignes du bandeau selon le flux d'appel.
abstract final class CompteurSelectionTextes {
  static const transfert =
      'Choisissez le compteur vers lequel vous souhaitez faire votre transfert.';

  static const retour =
      'Choisissez le compteur vers lequel vous souhaitez faire votre retour.';
}

/// Écran « Transfert » — sélection du compteur de destination.
class CompteurSelectionPage extends StatefulWidget {
  /// Consigne affichée dans le bandeau teal.
  final String instruction;

  const CompteurSelectionPage({super.key, required this.instruction});

  static Route<void> fadeRoute({required String instruction}) =>
      swappMenuFadeRoute(CompteurSelectionPage(instruction: instruction));

  @override
  State<CompteurSelectionPage> createState() => _CompteurSelectionPageState();
}

class _CompteurSelectionPageState extends State<CompteurSelectionPage> {
  final _searchController = TextEditingController();

  // TODO(API) : remplacer par SwappApiService.fetchCompteurs()
  final _compteurs = CompteurDemoData.items();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CompteurItem> get _visibles =>
      _compteurs.where((c) => c.matches(_searchController.text)).toList();

  /// Ouvre la saisie des articles vers [compteur].
  Future<void> _openCompteur(CompteurItem compteur) async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      InfoTransfertDetailPage.fadeRoute(
        codeMagDest: compteur.numero,
        nomMagDest: compteur.displayTitle,
      ),
    );
  }

  /// Flèche header — valide s'il ne reste qu'un compteur après filtrage.
  Future<void> _goNext() async {
    final visibles = _visibles;
    if (visibles.length != 1) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            visibles.isEmpty
                ? 'Aucun compteur ne correspond à votre recherche.'
                : 'Choisissez votre compteur.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    await _openCompteur(visibles.first);
  }

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.35);
    double dp(double v) => v * scale;
    final top = MediaQuery.paddingOf(context).top;
    final visibles = _visibles;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: SwappAttenteColors.headerNavy,
      ),
      child: Scaffold(
        backgroundColor: SwappMenuColors.bg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: SwappAttenteColors.headerNavy,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  dp(14),
                  top + dp(8),
                  dp(14),
                  dp(14),
                ),
                child: Row(
                  children: [
                    SwappAttenteNavSquare(
                      dp: dp,
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    SizedBox(width: dp(12)),
                    Expanded(
                      child: Text(
                        'Transfert',
                        style: TextStyle(
                          fontSize: dp(19),
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    SwappAttenteNavSquare(
                      dp: dp,
                      icon: Icons.arrow_forward_rounded,
                      onTap: _goNext,
                      muted: visibles.length != 1,
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(dp(16), dp(16), dp(16), dp(24)),
                children: [
                  SwappInstructionBanner(
                    dp: dp,
                    icon: Icons.schedule_rounded,
                    text: widget.instruction,
                  ),
                  SizedBox(height: dp(16)),
                  _SearchField(
                    dp: dp,
                    controller: _searchController,
                    onChanged: () => setState(() {}),
                  ),
                  SwappAttenteSectionBar(
                    dp: dp,
                    title: 'COMPTEURS DISPONIBLES',
                  ),
                  if (visibles.isEmpty)
                    SwappAttenteEmptyState(
                      dp: dp,
                      icon: Icons.search_off_rounded,
                      title: 'Aucun compteur trouvé',
                      hint:
                          'Modifiez votre recherche pour voir les compteurs '
                          'disponibles.',
                    )
                  else
                    for (final compteur in visibles) ...[
                      _CompteurCard(
                        dp: dp,
                        compteur: compteur,
                        onTap: () => _openCompteur(compteur),
                      ),
                      SizedBox(height: dp(12)),
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

// ---------------------------------------------------------------------------
// Champ de recherche compteur
// ---------------------------------------------------------------------------
class _SearchField extends StatelessWidget {
  final double Function(double) dp;
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _SearchField({
    required this.dp,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SwappMenuColors.panel,
        borderRadius: BorderRadius.circular(dp(14)),
        boxShadow: [
          BoxShadow(
            color: SwappMenuColors.ink.withValues(alpha: 0.06),
            blurRadius: dp(12),
            offset: Offset(0, dp(4)),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged(),
        textInputAction: TextInputAction.search,
        style: TextStyle(
          fontSize: dp(14),
          fontWeight: FontWeight.w600,
          color: SwappMenuColors.ink,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: dp(15)),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: SwappMenuColors.inkDim,
            size: dp(20),
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    controller.clear();
                    onChanged();
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: SwappMenuColors.inkDim,
                    size: dp(18),
                  ),
                ),
          hintText: 'Rechercher un compteur...',
          hintStyle: TextStyle(
            fontSize: dp(14),
            fontWeight: FontWeight.w500,
            color: SwappMenuColors.inkDim,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Carte compteur — dépôt, numéro, chevron
// ---------------------------------------------------------------------------
class _CompteurCard extends StatelessWidget {
  final double Function(double) dp;
  final CompteurItem compteur;
  final VoidCallback onTap;

  const _CompteurCard({
    required this.dp,
    required this.compteur,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SwappMenuColors.panel,
      borderRadius: BorderRadius.circular(dp(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(16)),
        child: Ink(
          decoration: BoxDecoration(
            color: SwappMenuColors.panel,
            borderRadius: BorderRadius.circular(dp(16)),
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
              Container(
                width: dp(42),
                height: dp(42),
                decoration: BoxDecoration(
                  color: SwappMenuColors.p1Bg,
                  borderRadius: BorderRadius.circular(dp(12)),
                ),
                child: Icon(
                  Icons.view_in_ar_rounded,
                  color: SwappMenuColors.p1,
                  size: dp(22),
                ),
              ),
              SizedBox(width: dp(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      compteur.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dp(13.5),
                        fontWeight: FontWeight.w900,
                        color: SwappMenuColors.ink,
                      ),
                    ),
                    SizedBox(height: dp(3)),
                    Text(
                      compteur.displaySubtitle,
                      style: TextStyle(
                        fontSize: dp(11.5),
                        fontWeight: FontWeight.w600,
                        color: SwappMenuColors.inkDim,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: SwappMenuColors.inkDim,
                size: dp(24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
