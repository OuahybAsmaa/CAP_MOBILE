// =============================================================================
// CapMobile — Module Swapp — Page Info Tarif (legacy)
// -----------------------------------------------------------------------------
// Fonctionnalité : Liste opérations tarifaires — sélection multi (design legacy).
// Design         : AppBar gradient · toolbar FDS · bandeau sombre · cartes blanches.
// UI             : Accès menu « Infos Tarifs » — œil → liste articles corail.
// Spécifications : infoTarifProvider (démo) → API via SwappApiService TODO.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/tarif/providers/info_tarif_provider.dart';
import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/features/auth/providers/auth_provider.dart';
import 'package:cap_mobile/swapp/models/info_tarif_item.dart';
import 'package:cap_mobile/swapp/pages/tarif/info_tarif_articles_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Écran « Info Tarif » legacy — choix opérations (menu Infos Tarifs).
class InfoTarifPage extends ConsumerStatefulWidget {
  const InfoTarifPage({super.key});

  static Route<void> fadeRoute() => swappMenuFadeRoute(const InfoTarifPage());

  @override
  ConsumerState<InfoTarifPage> createState() => _InfoTarifPageState();
}

class _InfoTarifPageState extends ConsumerState<InfoTarifPage> {
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final collab = ref.read(authProvider).collaborateur;
    await ref
        .read(infoTarifProvider.notifier)
        .fetchOperations(codeMag: collab?.codeMag);
  }

  Future<void> _syncFds() async {
    HapticFeedback.mediumImpact();
    final collab = ref.read(authProvider).collaborateur;
    await ref
        .read(infoTarifProvider.notifier)
        .syncFds(codeMag: collab?.codeMag);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('FDS mis à jour (mode démo)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openAgendaCalendar() async {
    HapticFeedback.selectionClick();
    final state = ref.read(infoTarifProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.filterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('fr', 'FR'),
      helpText: 'Choisir une date',
      cancelText: 'Annuler',
      confirmText: 'OK',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: SwappMenuColors.indigo,
            brightness: Brightness.light,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted || picked == null) return;
    ref.read(infoTarifProvider.notifier).setFilterDate(picked);
  }

  void _toggleSelectAll() {
    HapticFeedback.selectionClick();
    ref.read(infoTarifProvider.notifier).toggleSelectAllVisible();
  }

  void _openArticles(List<InfoTarifItem> operations) {
    if (operations.isEmpty) return;
    HapticFeedback.lightImpact();
    Navigator.push(context, InfoTarifArticlesPage.fadeRoute(operations));
  }

  List<InfoTarifItem> _selectedOperations(InfoTarifState state) {
    return state.visibleOperations
        .where((op) => state.selectedIds.contains(op.id))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(infoTarifProvider);
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.35);
    double dp(double v) => v * scale;
    final selected = _selectedOperations(state);

    return Scaffold(
      backgroundColor: SwappMenuColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LegacyAppBar(
            dp: dp,
            onBack: () => Navigator.pop(context),
            onCalendar: _openAgendaCalendar,
            onToggleSelectAll: _toggleSelectAll,
            allSelected: state.allVisibleSelected,
            hasOperations: state.visibleOperations.isNotEmpty,
            onNext: selected.isNotEmpty ? () => _openArticles(selected) : null,
          ),
          _LegacyToolbar(
            dp: dp,
            isSyncing: state.isSyncingFds,
            onSyncFds: _syncFds,
          ),
          _LegacySectionBanner(
            dp: dp,
            filterDate: state.filterDate,
            dateFormat: _dateFormat,
            onClearFilter: () {
              ref.read(infoTarifProvider.notifier).setFilterDate(null);
            },
          ),
          Expanded(child: _buildBody(state, dp)),
        ],
      ),
    );
  }

  Widget _buildBody(InfoTarifState state, double Function(double) dp) {
    if (state.isLoading && state.allOperations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.allOperations.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(dp(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: dp(40),
                color: AppColors.error,
              ),
              SizedBox(height: dp(12)),
              Text(state.error!, textAlign: TextAlign.center),
              SizedBox(height: dp(16)),
              FilledButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final visible = state.visibleOperations;

    if (visible.isEmpty) {
      return Center(
        child: Text(
          state.filterDate != null
              ? 'Aucune opération active à cette date'
              : 'Aucune opération disponible',
          style: TextStyle(color: SwappMenuColors.inkDim, fontSize: dp(14)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(dp(14), dp(12), dp(14), dp(20)),
        itemCount: visible.length,
        separatorBuilder: (_, _) => SizedBox(height: dp(10)),
        itemBuilder: (context, index) {
          final item = visible[index];
          final isSelected = state.selectedIds.contains(item.id);
          return _LegacyOperationCard(
            dp: dp,
            item: item,
            selected: isSelected,
            dateFormat: _dateFormat,
            onSelect: () {
              HapticFeedback.selectionClick();
              ref.read(infoTarifProvider.notifier).toggleSelection(item.id);
            },
            onView: () => _openArticles([item]),
          );
        },
      ),
    );
  }
}

class _LegacyAppBar extends StatelessWidget {
  final double Function(double) dp;
  final VoidCallback onBack;
  final VoidCallback onCalendar;
  final VoidCallback onToggleSelectAll;
  final bool allSelected;
  final bool hasOperations;
  final VoidCallback? onNext;

  const _LegacyAppBar({
    required this.dp,
    required this.onBack,
    required this.onCalendar,
    required this.onToggleSelectAll,
    required this.allSelected,
    required this.hasOperations,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      padding: EdgeInsets.fromLTRB(dp(4), top + dp(4), dp(8), dp(12)),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              'Info Tarif',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: dp(18),
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: onCalendar,
            icon: Icon(
              Icons.calendar_today_outlined,
              color: Colors.white.withValues(alpha: 0.9),
              size: dp(20),
            ),
            tooltip: 'Agenda',
          ),
          IconButton(
            onPressed: hasOperations ? onToggleSelectAll : null,
            icon: Icon(
              allSelected
                  ? Icons.deselect_outlined
                  : Icons.checklist_rtl_rounded,
              color: Colors.white.withValues(alpha: hasOperations ? 0.9 : 0.4),
              size: dp(22),
            ),
            tooltip: allSelected ? 'Tout désélectionner' : 'Tout sélectionner',
          ),
          IconButton(
            onPressed: onNext,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: onNext != null ? 0.9 : 0.4),
              size: dp(26),
            ),
            tooltip: 'Suivant',
          ),
        ],
      ),
    );
  }
}

class _LegacyToolbar extends StatelessWidget {
  final double Function(double) dp;
  final bool isSyncing;
  final VoidCallback onSyncFds;

  const _LegacyToolbar({
    required this.dp,
    required this.isSyncing,
    required this.onSyncFds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SwappMenuColors.panel,
      padding: EdgeInsets.fromLTRB(dp(14), dp(10), dp(14), dp(10)),
      child: Row(
        children: [
          Container(
            width: dp(44),
            height: dp(44),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(dp(12)),
            ),
            child: Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.error,
              size: dp(24),
            ),
          ),
          SizedBox(width: dp(10)),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: isSyncing ? null : onSyncFds,
              style: FilledButton.styleFrom(
                backgroundColor: SwappMenuColors.p2Bg,
                foregroundColor: SwappMenuColors.p2,
                padding: EdgeInsets.symmetric(
                  horizontal: dp(12),
                  vertical: dp(12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(dp(24)),
                ),
              ),
              icon: isSyncing
                  ? SizedBox(
                      width: dp(18),
                      height: dp(18),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SwappMenuColors.p2,
                      ),
                    )
                  : Icon(Icons.sync_rounded, size: dp(20)),
              label: Text(
                'Mettre à jour mes FDS :)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: dp(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegacySectionBanner extends StatelessWidget {
  final double Function(double) dp;
  final DateTime? filterDate;
  final DateFormat dateFormat;
  final VoidCallback onClearFilter;

  const _LegacySectionBanner({
    required this.dp,
    required this.filterDate,
    required this.dateFormat,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: SwappMenuColors.ink,
      padding: EdgeInsets.symmetric(horizontal: dp(16), vertical: dp(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choisissez votre ou vos opérations',
            style: TextStyle(
              fontSize: dp(13),
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          if (filterDate != null) ...[
            SizedBox(height: dp(6)),
            InkWell(
              onTap: onClearFilter,
              borderRadius: BorderRadius.circular(dp(12)),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: dp(8),
                  vertical: dp(4),
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(dp(12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_rounded,
                      size: dp(14),
                      color: Colors.white,
                    ),
                    SizedBox(width: dp(6)),
                    Text(
                      'Agenda : ${dateFormat.format(filterDate!)}',
                      style: TextStyle(
                        fontSize: dp(11),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: dp(4)),
                    const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LegacyOperationCard extends StatelessWidget {
  final double Function(double) dp;
  final InfoTarifItem item;
  final bool selected;
  final DateFormat dateFormat;
  final VoidCallback onSelect;
  final VoidCallback onView;

  const _LegacyOperationCard({
    required this.dp,
    required this.item,
    required this.selected,
    required this.dateFormat,
    required this.onSelect,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final dateLine =
        '${dateFormat.format(item.dateDebut)}  ${dateFormat.format(item.dateFin)}  ${item.statut}';

    return Material(
      color: SwappMenuColors.panel,
      elevation: selected ? 2 : 0,
      shadowColor: SwappMenuColors.indigo.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(dp(14)),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(dp(14)),
          border: Border.all(
            color: selected
                ? SwappMenuColors.indigo
                : SwappMenuColors.line.withValues(alpha: 0.35),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: InkWell(
                onTap: onSelect,
                borderRadius: BorderRadius.circular(dp(14)),
                child: Padding(
                  padding: EdgeInsets.all(dp(12)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: dp(40),
                        height: dp(40),
                        decoration: BoxDecoration(
                          color: selected
                              ? SwappMenuColors.p1Bg
                              : SwappMenuColors.bg,
                          borderRadius: BorderRadius.circular(dp(10)),
                        ),
                        child: Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: selected
                              ? SwappMenuColors.indigo
                              : SwappMenuColors.inkDim,
                          size: dp(22),
                        ),
                      ),
                      SizedBox(width: dp(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.displayTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: dp(13),
                                fontWeight: FontWeight.w800,
                                color: SwappMenuColors.ink,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: dp(6)),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: dp(12),
                                  color: SwappMenuColors.inkDim,
                                ),
                                SizedBox(width: dp(6)),
                                Expanded(
                                  child: Text(
                                    dateLine,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: dp(11),
                                      color: SwappMenuColors.inkDim,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: dp(8), right: dp(4)),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onView,
                  borderRadius: BorderRadius.circular(dp(20)),
                  child: Padding(
                    padding: EdgeInsets.all(dp(8)),
                    child: Icon(
                      Icons.visibility_outlined,
                      color: SwappMenuColors.indigo,
                      size: dp(26),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
