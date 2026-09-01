// =============================================================================
// CapMobile — Module Swapp — Retours dépôt en attente
// -----------------------------------------------------------------------------
// Fonctionnalité : Liste des retours saison non clôturés — suppression à la
//                  ligne, mode sélection multiple, reprise d'un retour.
// Design         : Kit SwappAttente — header navy, 2 cartes statistiques,
//                  cartes blanches (pastille colis, chip articles, date) avec
//                  corbeille rouge en fin de ligne.
// UI             : Ouverte après « Oui » sur showRepriseEnCoursDialog (tuile
//                  « Retour Dépôt ») ; carte → InfoTransfertDetailPage ;
//                  double tap → ArticlesSaisiePage ; + → CompteurSelectionPage.
// Spécifications : Données [RetourDepotDemoData] triées par
//                  RetourDepotItem.compareOrdreRetour ; API TODO.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/transfert/data/retour_depot_test_data.dart';
import 'package:cap_mobile/core/widgets/app_popup.dart';
import 'package:cap_mobile/swapp/models/retour_depot_item.dart';
import 'package:cap_mobile/swapp/pages/transfert/articles_saisie_page.dart';
import 'package:cap_mobile/swapp/pages/transfert/compteur_selection_page.dart';
import 'package:cap_mobile/swapp/pages/transfert/info_transfert_detail_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_attente_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Écran « Retour Dépôt » — retours saison en attente du magasin.
class RetourDepotPage extends StatefulWidget {
  const RetourDepotPage({super.key});

  static Route<void> fadeRoute() => swappMenuFadeRoute(const RetourDepotPage());

  @override
  State<RetourDepotPage> createState() => _RetourDepotPageState();
}

class _RetourDepotPageState extends State<RetourDepotPage> {
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  /// Retours affichés du plus ancien au plus récent.
  late List<RetourDepotItem> _items;
  final _selectedIds = <String>{};

  /// Mode sélection multiple — activé par la pilule « Sélectionner ».
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    // TODO(API) : remplacer par SwappApiService.fetchRetoursDepot()
    _items = RetourDepotDemoData.items()
      ..sort(RetourDepotItem.compareOrdreRetour);
  }

  int get _nbArticles =>
      _items.fold<int>(0, (total, item) => total + item.nbArticles);

  bool get _allSelected =>
      _items.isNotEmpty && _selectedIds.length == _items.length;

  List<RetourDepotItem> get _selectedItems =>
      _items.where((item) => _selectedIds.contains(item.id)).toList();

  void _toggleSelectionMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(RetourDepotItem item) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedIds.remove(item.id)) _selectedIds.add(item.id);
    });
  }

  void _toggleSelectAll() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_allSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_items.map((item) => item.id));
      }
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Reprend un retour — saisie articles vers le dépôt.
  Future<void> _openRetour(RetourDepotItem item) async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      InfoTransfertDetailPage.fadeRoute(
        codeMagDest: item.codeDepot,
        nomMagDest: item.displayTitle,
      ),
    );
  }

  /// Double tap sur une carte — détail des articles déjà saisis sur le retour.
  Future<void> _openArticles(RetourDepotItem item) async {
    HapticFeedback.selectionClick();
    await Navigator.push(
      context,
      ArticlesSaisiePage.fadeRoute(
        flux: ArticlesFlux.retour,
        destination: item.displayTitle,
      ),
    );
  }

  /// + du header — choix du compteur avant de créer un nouveau retour.
  Future<void> _createRetour() async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      CompteurSelectionPage.fadeRoute(
        instruction: CompteurSelectionTextes.retour,
      ),
    );
  }

  /// Flèche header — poursuit le retour coché (un seul à la fois).
  Future<void> _continueSelected() async {
    final selection = _selectedItems;
    if (selection.length != 1) {
      HapticFeedback.heavyImpact();
      _snack(
        selection.isEmpty
            ? 'Cochez le retour que vous souhaitez poursuivre.'
            : 'Un seul retour à la fois pour la reprise.',
      );
      return;
    }
    await _openRetour(selection.first);
  }

  Future<void> _deleteSelected() async {
    final selection = _selectedItems;
    if (selection.isEmpty) {
      HapticFeedback.heavyImpact();
      _snack('Cochez au moins un retour à supprimer.');
      return;
    }
    await _delete(selection);
  }

  Future<void> _delete(List<RetourDepotItem> selection) async {
    HapticFeedback.mediumImpact();
    final confirmed = await AppPopup.danger(
      context,
      title: selection.length > 1
          ? 'Supprimer les retours ?'
          : 'Supprimer le retour ?',
      message: selection.length > 1
          ? '${selection.length} retours dépôt seront supprimés.'
          : 'Le retour ${selection.first.displayTitle} '
                '(${selection.first.nbArticles} art.) sera supprimé.',
    );
    if (confirmed != true || !mounted) return;

    final ids = selection.map((item) => item.id).toSet();
    setState(() {
      _items.removeWhere((item) => ids.contains(item.id));
      _selectedIds.removeAll(ids);
      if (_items.isEmpty) _selectionMode = false;
    });
    _snack(
      selection.length > 1
          ? '${selection.length} retours supprimés (mode démo)'
          : 'Retour supprimé (mode démo)',
    );
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
            SwappAttenteHeader(
              dp: dp,
              top: insets.top,
              title: 'Retour Dépôt',
              nbEnAttente: _items.length,
              labelEnAttente: 'RETOURS EN ATTENTE',
              nbArticles: _nbArticles,
              onBack: () => Navigator.pop(context),
              onCreate: _createRetour,
              onForward: _continueSelected,
              forwardEnabled: _selectedIds.length == 1,
            ),
            SwappAttenteSectionBar(
              dp: dp,
              title: 'VOS RETOURS SAISON EN ATTENTE',
              actions: [
                SwappAttenteSelectionActions(
                  dp: dp,
                  selectionMode: _selectionMode,
                  hasItems: _items.isNotEmpty,
                  allSelected: _allSelected,
                  hasSelection: _selectedIds.isNotEmpty,
                  onToggleMode: _toggleSelectionMode,
                  onToggleAll: _toggleSelectAll,
                  onDeleteSelected: _deleteSelected,
                ),
              ],
            ),
            Expanded(
              child: _items.isEmpty
                  ? SwappAttenteEmptyState(
                      dp: dp,
                      icon: Icons.inventory_2_outlined,
                      title: 'Aucun retour en attente',
                      hint: 'Utilisez + pour créer un retour dépôt.',
                    )
                  : ListView.separated(
                      // Marge basse = barre de navigation Android incluse.
                      padding: EdgeInsets.fromLTRB(
                        dp(14),
                        dp(4),
                        dp(14),
                        dp(24) + insets.bottom,
                      ),
                      itemCount: _items.length,
                      separatorBuilder: (_, _) => SizedBox(height: dp(12)),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final selected = _selectedIds.contains(item.id);
                        return SwappAttenteCard(
                          dp: dp,
                          icon: Icons.view_in_ar_rounded,
                          title: item.displayTitle,
                          nbArticles: item.nbArticles,
                          dateLabel: _dateFormat.format(item.dateCreation),
                          selected: selected,
                          onTap: _selectionMode
                              ? () => _toggleSelection(item)
                              : () => _openRetour(item),
                          onDoubleTap: _selectionMode
                              ? null
                              : () => _openArticles(item),
                          leading: _selectionMode
                              ? SwappAttenteSelectDot(
                                  dp: dp,
                                  selected: selected,
                                )
                              : null,
                          trailing: _selectionMode
                              ? null
                              : SwappAttenteDeleteButton(
                                  dp: dp,
                                  onTap: () => _delete([item]),
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
