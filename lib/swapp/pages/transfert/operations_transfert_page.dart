// =============================================================================
// CapMobile — Module Swapp — Opérations de transfert en attente
// -----------------------------------------------------------------------------
// Fonctionnalité : Liste des OT non clôturés — sélection multiple, suppression,
//                  reprise d'un OT, création d'un nouvel OT.
// Design         : Kit SwappAttente — header navy, 2 cartes statistiques,
//                  cartes blanches (pastille magasin, chip articles, date).
// UI             : Ouverte après « Oui » sur showRepriseEnCoursDialog (tuile
//                  « Ordre de Transfert ») ; carte → InfoTransfertDetailPage ;
//                  double tap → ArticlesSaisiePage ; + → CompteurSelectionPage.
// Spécifications : Données [OperationTransfertDemoData] triées par
//                  OperationTransfertItem.compareOrdreTransfert ; API TODO.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/transfert/data/operation_transfert_test_data.dart';
import 'package:cap_mobile/core/widgets/app_popup.dart';
import 'package:cap_mobile/swapp/models/operation_transfert_item.dart';
import 'package:cap_mobile/swapp/pages/transfert/articles_saisie_page.dart';
import 'package:cap_mobile/swapp/pages/transfert/compteur_selection_page.dart';
import 'package:cap_mobile/swapp/pages/transfert/info_transfert_detail_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_attente_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Écran « Opérations de transfert » — OT en attente du magasin.
class OperationsTransfertPage extends StatefulWidget {
  const OperationsTransfertPage({super.key});

  static Route<void> fadeRoute() =>
      swappMenuFadeRoute(const OperationsTransfertPage());

  @override
  State<OperationsTransfertPage> createState() =>
      _OperationsTransfertPageState();
}

class _OperationsTransfertPageState extends State<OperationsTransfertPage> {
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  /// OT affichés dans l'ordre de transfert (chronologique).
  late List<OperationTransfertItem> _items;
  final _selectedIds = <String>{};

  /// Mode sélection multiple — activé par la pilule « Sélectionner ».
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    // TODO(API) : remplacer par SwappApiService.fetchOperationsTransfert()
    _items = OperationTransfertDemoData.items()
      ..sort(OperationTransfertItem.compareOrdreTransfert);
  }

  int get _nbArticles =>
      _items.fold<int>(0, (total, item) => total + item.nbArticles);

  bool get _allSelected =>
      _items.isNotEmpty && _selectedIds.length == _items.length;

  List<OperationTransfertItem> get _selectedItems =>
      _items.where((item) => _selectedIds.contains(item.id)).toList();

  void _toggleSelectionMode() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectionMode = !_selectionMode;
      if (!_selectionMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(OperationTransfertItem item) {
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

  /// Reprend un OT — saisie articles vers le magasin destination.
  Future<void> _openOt(OperationTransfertItem item) async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      InfoTransfertDetailPage.fadeRoute(
        codeMagDest: item.codeMagasin,
        nomMagDest: item.libelleMagasin,
      ),
    );
  }

  /// Double tap sur une carte — détail des articles déjà saisis sur l'OT.
  Future<void> _openArticles(OperationTransfertItem item) async {
    HapticFeedback.selectionClick();
    await Navigator.push(
      context,
      ArticlesSaisiePage.fadeRoute(
        flux: ArticlesFlux.transfert,
        destination: item.displayTitle,
      ),
    );
  }

  /// + du header — choix du compteur avant de créer un nouvel OT.
  Future<void> _createOt() async {
    HapticFeedback.lightImpact();
    await Navigator.push(
      context,
      CompteurSelectionPage.fadeRoute(
        instruction: CompteurSelectionTextes.transfert,
      ),
    );
  }

  /// Flèche header — poursuit l'OT coché (un seul à la fois).
  Future<void> _continueSelected() async {
    final selection = _selectedItems;
    if (selection.length != 1) {
      HapticFeedback.heavyImpact();
      _snack(
        selection.isEmpty
            ? 'Cochez l\u2019OT que vous souhaitez poursuivre.'
            : 'Un seul OT à la fois pour la reprise.',
      );
      return;
    }
    await _openOt(selection.first);
  }

  Future<void> _deleteSelected() async {
    final selection = _selectedItems;
    if (selection.isEmpty) {
      HapticFeedback.heavyImpact();
      _snack('Cochez au moins un OT à supprimer.');
      return;
    }
    await _delete(selection);
  }

  Future<void> _delete(List<OperationTransfertItem> selection) async {
    HapticFeedback.mediumImpact();
    final confirmed = await AppPopup.danger(
      context,
      title: selection.length > 1
          ? 'Supprimer les OT ?'
          : 'Supprimer l\u2019OT ?',
      message: selection.length > 1
          ? '${selection.length} ordres de transfert seront supprimés.'
          : 'L\u2019ordre de transfert ${selection.first.displayTitle} '
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
          ? '${selection.length} OT supprimés (mode démo)'
          : 'OT supprimé (mode démo)',
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
              title: 'Opérations de transfert',
              nbEnAttente: _items.length,
              labelEnAttente: 'OTS EN ATTENTE',
              nbArticles: _nbArticles,
              onBack: () => Navigator.pop(context),
              onCreate: _createOt,
              onForward: _continueSelected,
              forwardEnabled: _selectedIds.length == 1,
            ),
            SwappAttenteSectionBar(
              dp: dp,
              title: 'VOS OTS EN ATTENTE',
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
                      icon: Icons.assignment_turned_in_outlined,
                      title: 'Aucun OT en attente',
                      hint: 'Utilisez + pour créer un ordre de transfert.',
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
                          icon: Icons.storefront_rounded,
                          title: item.displayTitle,
                          nbArticles: item.nbArticles,
                          dateLabel: _dateFormat.format(item.dateCreation),
                          selected: selected,
                          onTap: _selectionMode
                              ? () => _toggleSelection(item)
                              : () => _openOt(item),
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
