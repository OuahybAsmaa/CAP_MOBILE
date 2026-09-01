// =============================================================================
// CapMobile — Module Swapp — Page Info Tarif 2 (design moderne)
// -----------------------------------------------------------------------------
// Fonctionnalité : Liste opérations / promos — sélection multi (UI SWAPP indigo).
// Design         : Header blanc, cartes premium, stats, barre bas « Continuer ».
// UI             : Accès menu « Info Tarif 2 » — bouton Articles → liste tarifs.
// Spécifications : infoTarifProvider (démo) → API via SwappApiService TODO.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/apiswap/tarif/providers/info_tarif_provider.dart';
import 'package:cap_mobile/features/auth/providers/auth_provider.dart';
import 'package:cap_mobile/swapp/models/info_tarif_item.dart';
import 'package:cap_mobile/swapp/pages/tarif/info_tarif_articles_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Accents visuels cycliques pour différencier les cartes opération.
const _cardAccents = [
  (SwappMenuColors.p1, SwappMenuColors.p1Bg),
  (SwappMenuColors.p5, SwappMenuColors.p5Bg),
  (SwappMenuColors.p3, SwappMenuColors.p3Bg),
  (SwappMenuColors.p6, SwappMenuColors.p6Bg),
  (SwappMenuColors.p4, SwappMenuColors.p4Bg),
  (SwappMenuColors.p2, SwappMenuColors.p2Bg),
];

/// Écran « Info Tarif 2 » — design moderne SWAPP.
class InfoTarifPage2 extends ConsumerStatefulWidget {
  const InfoTarifPage2({super.key});

  static Route<void> fadeRoute() => swappMenuFadeRoute(const InfoTarifPage2());

  @override
  ConsumerState<InfoTarifPage2> createState() => _InfoTarifPage2State();
}

class _InfoTarifPage2State extends ConsumerState<InfoTarifPage2> {
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
      SnackBar(
        content: const Text('FDS mis à jour'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      helpText: 'Agenda tarifs',
      cancelText: 'Annuler',
      confirmText: 'Appliquer',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: SwappMenuColors.indigo),
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

    final visible = state.visibleOperations;
    final selectedCount = state.selectedIds.length;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: SwappMenuColors.panel,
      ),
      child: Scaffold(
        backgroundColor: SwappMenuColors.bg,
        bottomNavigationBar: selectedCount > 0
            ? _InfoTarifBottomBar(
                dp: dp,
                selectedCount: selectedCount,
                onContinue: () => _openArticles(_selectedOperations(state)),
              )
            : null,
        body: Column(
          children: [
            _InfoTarifHeader(
              dp: dp,
              onBack: () => Navigator.pop(context),
              onCalendar: _openAgendaCalendar,
              onToggleSelectAll: _toggleSelectAll,
              allSelected: state.allVisibleSelected,
              hasOperations: visible.isNotEmpty,
              filterDate: state.filterDate,
              dateFormat: _dateFormat,
              onClearFilter: () {
                ref.read(infoTarifProvider.notifier).setFilterDate(null);
              },
            ),
            Expanded(
              child: RefreshIndicator(
                color: SwappMenuColors.indigo,
                onRefresh: _load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(dp(16), dp(14), dp(16), 0),
                        child: _InfoTarifStatsRow(
                          dp: dp,
                          total: visible.length,
                          selected: selectedCount,
                          isSyncing: state.isSyncingFds,
                          onSyncFds: _syncFds,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          dp(16),
                          dp(16),
                          dp(16),
                          dp(8),
                        ),
                        child: _InfoTarifSectionLabel(
                          dp: dp,
                          count: visible.length,
                          subtitle:
                              'Cochez puis Continuer, ou ouvrez une opération',
                        ),
                      ),
                    ),
                    _buildListSliver(state, dp),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListSliver(InfoTarifState state, double Function(double) dp) {
    if (state.isLoading && state.allOperations.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: CircularProgressIndicator(color: SwappMenuColors.indigo),
        ),
      );
    }

    if (state.error != null && state.allOperations.isEmpty) {
      return SliverFillRemaining(
        child: _InfoTarifEmptyState(
          dp: dp,
          icon: Icons.cloud_off_rounded,
          message: state.error!,
          actionLabel: 'Réessayer',
          onAction: _load,
        ),
      );
    }

    final visible = state.visibleOperations;

    if (state.allOperations.isEmpty || visible.isEmpty) {
      return SliverFillRemaining(
        child: _InfoTarifEmptyState(
          dp: dp,
          icon: Icons.local_offer_outlined,
          message: state.filterDate != null
              ? 'Aucune opération à cette date'
              : 'Aucune opération disponible',
          actionLabel: state.filterDate != null ? 'Voir tout' : null,
          onAction: state.filterDate != null
              ? () => ref.read(infoTarifProvider.notifier).setFilterDate(null)
              : null,
        ),
      );
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(dp(16), 0, dp(16), dp(24)),
      sliver: SliverList.separated(
        itemCount: visible.length,
        separatorBuilder: (_, _) => SizedBox(height: dp(10)),
        itemBuilder: (context, index) {
          final item = visible[index];
          final accent = _cardAccents[index % _cardAccents.length];
          return _InfoTarifOperationCard(
            dp: dp,
            item: item,
            selected: state.selectedIds.contains(item.id),
            accent: accent.$1,
            accentBg: accent.$2,
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

// ---------------------------------------------------------------------------
// En-tête blanc — aligné menu SWAPP
// ---------------------------------------------------------------------------
class _InfoTarifHeader extends StatelessWidget {
  final double Function(double) dp;
  final VoidCallback onBack;
  final VoidCallback onCalendar;
  final VoidCallback onToggleSelectAll;
  final bool allSelected;
  final bool hasOperations;
  final DateTime? filterDate;
  final DateFormat dateFormat;
  final VoidCallback onClearFilter;

  const _InfoTarifHeader({
    required this.dp,
    required this.onBack,
    required this.onCalendar,
    required this.onToggleSelectAll,
    required this.allSelected,
    required this.hasOperations,
    required this.filterDate,
    required this.dateFormat,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return DecoratedBox(
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
        padding: EdgeInsets.fromLTRB(dp(4), top + dp(4), dp(12), dp(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: SwappMenuColors.ink,
                  tooltip: 'Retour',
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Info Tarif 2',
                        style: TextStyle(
                          fontSize: dp(20),
                          fontWeight: FontWeight.w900,
                          color: SwappMenuColors.ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Promotions & opérations magasin',
                        style: TextStyle(
                          fontSize: dp(11),
                          color: SwappMenuColors.inkDim,
                        ),
                      ),
                    ],
                  ),
                ),
                _HeaderIconBtn(
                  dp: dp,
                  icon: Icons.calendar_month_rounded,
                  tooltip: 'Agenda',
                  onTap: onCalendar,
                  highlighted: filterDate != null,
                ),
                SizedBox(width: dp(6)),
                _HeaderIconBtn(
                  dp: dp,
                  icon: allSelected
                      ? Icons.indeterminate_check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  tooltip: allSelected
                      ? 'Tout désélectionner'
                      : 'Tout sélectionner',
                  onTap: hasOperations ? onToggleSelectAll : null,
                  highlighted: allSelected,
                  enabled: hasOperations,
                ),
              ],
            ),
            if (filterDate != null) ...[
              SizedBox(height: dp(8)),
              Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: Icon(
                    Icons.event_rounded,
                    size: dp(16),
                    color: SwappMenuColors.indigo,
                  ),
                  label: Text(
                    dateFormat.format(filterDate!),
                    style: TextStyle(
                      fontSize: dp(11),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: onClearFilter,
                  backgroundColor: SwappMenuColors.p1Bg,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(dp(20)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeaderIconBtn extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool highlighted;
  final bool enabled;

  const _HeaderIconBtn({
    required this.dp,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.highlighted = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? SwappMenuColors.p1Bg : SwappMenuColors.bg,
      borderRadius: BorderRadius.circular(dp(12)),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(dp(12)),
        child: SizedBox(
          width: dp(42),
          height: dp(42),
          child: Icon(
            icon,
            size: dp(22),
            color: enabled
                ? (highlighted ? SwappMenuColors.indigo : SwappMenuColors.ink)
                : SwappMenuColors.inkDim.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats + sync FDS
// ---------------------------------------------------------------------------
class _InfoTarifStatsRow extends StatelessWidget {
  final double Function(double) dp;
  final int total;
  final int selected;
  final bool isSyncing;
  final VoidCallback onSyncFds;

  const _InfoTarifStatsRow({
    required this.dp,
    required this.total,
    required this.selected,
    required this.isSyncing,
    required this.onSyncFds,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dp(14)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            SwappMenuColors.panel,
            SwappMenuColors.p1Bg.withValues(alpha: 0.35),
          ],
        ),
        borderRadius: BorderRadius.circular(dp(18)),
        border: Border.all(color: SwappMenuColors.p1Bg),
        boxShadow: [
          BoxShadow(
            color: SwappMenuColors.indigo.withValues(alpha: 0.06),
            blurRadius: dp(16),
            offset: Offset(0, dp(6)),
          ),
        ],
      ),
      child: Row(
        children: [
          _StatChip(
            dp: dp,
            value: '$total',
            label: 'Opérations',
            color: SwappMenuColors.indigo,
            bg: SwappMenuColors.p1Bg,
          ),
          SizedBox(width: dp(8)),
          _StatChip(
            dp: dp,
            value: '$selected',
            label: 'Sélection',
            color: SwappMenuColors.p2,
            bg: SwappMenuColors.p2Bg,
          ),
          SizedBox(width: dp(10)),
          Expanded(
            child: FilledButton.icon(
              onPressed: isSyncing ? null : onSyncFds,
              style: FilledButton.styleFrom(
                backgroundColor: SwappMenuColors.indigo,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: dp(12)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(dp(14)),
                ),
                elevation: 0,
              ),
              icon: isSyncing
                  ? SizedBox(
                      width: dp(16),
                      height: dp(16),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.sync_rounded, size: dp(18)),
              label: Text(
                'Sync FDS',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: dp(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final double Function(double) dp;
  final String value;
  final String label;
  final Color color;
  final Color bg;

  const _StatChip({
    required this.dp,
    required this.value,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dp(62),
      padding: EdgeInsets.symmetric(vertical: dp(8)),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(dp(12)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: dp(18),
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
          SizedBox(height: dp(2)),
          Text(
            label,
            style: TextStyle(
              fontSize: dp(8),
              fontWeight: FontWeight.w600,
              color: SwappMenuColors.inkDim,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTarifSectionLabel extends StatelessWidget {
  final double Function(double) dp;
  final int count;
  final String? subtitle;

  const _InfoTarifSectionLabel({
    required this.dp,
    required this.count,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: dp(4),
              height: dp(18),
              decoration: BoxDecoration(
                color: SwappMenuColors.indigo,
                borderRadius: BorderRadius.circular(dp(2)),
              ),
            ),
            SizedBox(width: dp(10)),
            Text(
              'Opérations',
              style: TextStyle(
                fontSize: dp(16),
                fontWeight: FontWeight.w800,
                color: SwappMenuColors.ink,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: dp(8), vertical: dp(3)),
              decoration: BoxDecoration(
                color: SwappMenuColors.bg,
                borderRadius: BorderRadius.circular(dp(8)),
              ),
              child: Text(
                count.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: dp(10),
                  fontWeight: FontWeight.w700,
                  color: SwappMenuColors.inkDim,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: dp(4)),
          Padding(
            padding: EdgeInsets.only(left: dp(14)),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: dp(10),
                color: SwappMenuColors.inkDim,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Carte opération — sélection + action « Articles »
// ---------------------------------------------------------------------------
class _InfoTarifOperationCard extends StatelessWidget {
  final double Function(double) dp;
  final InfoTarifItem item;
  final bool selected;
  final Color accent;
  final Color accentBg;
  final DateFormat dateFormat;
  final VoidCallback onSelect;
  final VoidCallback onView;

  const _InfoTarifOperationCard({
    required this.dp,
    required this.item,
    required this.selected,
    required this.accent,
    required this.accentBg,
    required this.dateFormat,
    required this.onSelect,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(dp(18)),
        border: Border.all(
          color: selected
              ? accent.withValues(alpha: 0.55)
              : SwappMenuColors.line.withValues(alpha: 0.25),
          width: selected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? accent.withValues(alpha: 0.12)
                : SwappMenuColors.ink.withValues(alpha: 0.04),
            blurRadius: dp(12),
            offset: Offset(0, dp(3)),
          ),
        ],
      ),
      child: Material(
        color: selected
            ? accentBg.withValues(alpha: 0.35)
            : SwappMenuColors.panel,
        borderRadius: BorderRadius.circular(dp(18)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onSelect,
              child: Padding(
                padding: EdgeInsets.fromLTRB(dp(14), dp(14), dp(14), dp(10)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SelectionMark(dp: dp, selected: selected, accent: accent),
                    SizedBox(width: dp(12)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: dp(6),
                            runSpacing: dp(4),
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: dp(8),
                                  vertical: dp(3),
                                ),
                                decoration: BoxDecoration(
                                  color: accentBg,
                                  borderRadius: BorderRadius.circular(dp(8)),
                                ),
                                child: Text(
                                  item.code,
                                  style: TextStyle(
                                    fontSize: dp(11),
                                    fontWeight: FontWeight.w900,
                                    color: accent,
                                  ),
                                ),
                              ),
                              if (item.statut.isNotEmpty)
                                _StatusPill(dp: dp, label: item.statut),
                            ],
                          ),
                          SizedBox(height: dp(8)),
                          Text(
                            item.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: dp(15),
                              fontWeight: FontWeight.w800,
                              color: SwappMenuColors.ink,
                              height: 1.2,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(dp(14), 0, dp(10), dp(12)),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_rounded,
                    size: dp(14),
                    color: SwappMenuColors.inkDim,
                  ),
                  SizedBox(width: dp(6)),
                  Expanded(
                    child: Text(
                      '${dateFormat.format(item.dateDebut)} → ${dateFormat.format(item.dateFin)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dp(11),
                        fontWeight: FontWeight.w600,
                        color: SwappMenuColors.inkDim,
                      ),
                    ),
                  ),
                  _ArticlesActionBtn(dp: dp, accent: accent, onTap: onView),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectionMark extends StatelessWidget {
  final double Function(double) dp;
  final bool selected;
  final Color accent;

  const _SelectionMark({
    required this.dp,
    required this.selected,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: dp(24),
      height: dp(24),
      decoration: BoxDecoration(
        color: selected ? accent : SwappMenuColors.panel,
        borderRadius: BorderRadius.circular(dp(8)),
        border: Border.all(
          color: selected
              ? accent
              : SwappMenuColors.inkDim.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: dp(16), color: Colors.white)
          : null,
    );
  }
}

class _StatusPill extends StatelessWidget {
  final double Function(double) dp;
  final String label;

  const _StatusPill({required this.dp, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dp(6), vertical: dp(2)),
      decoration: BoxDecoration(
        color: SwappMenuColors.bg,
        borderRadius: BorderRadius.circular(dp(6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: dp(9),
          fontWeight: FontWeight.w800,
          color: SwappMenuColors.inkDim,
        ),
      ),
    );
  }
}

class _ArticlesActionBtn extends StatelessWidget {
  final double Function(double) dp;
  final Color accent;
  final VoidCallback onTap;

  const _ArticlesActionBtn({
    required this.dp,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(dp(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(20)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dp(10), vertical: dp(6)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Articles',
                style: TextStyle(
                  fontSize: dp(11),
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              SizedBox(width: dp(2)),
              Icon(Icons.arrow_forward_rounded, size: dp(14), color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTarifEmptyState extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InfoTarifEmptyState({
    required this.dp,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(dp(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: dp(72),
              height: dp(72),
              decoration: BoxDecoration(
                color: SwappMenuColors.p1Bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: dp(32), color: SwappMenuColors.indigo),
            ),
            SizedBox(height: dp(16)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: dp(14),
                fontWeight: FontWeight.w600,
                color: SwappMenuColors.inkDim,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: dp(16)),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoTarifBottomBar extends StatelessWidget {
  final double Function(double) dp;
  final int selectedCount;
  final VoidCallback onContinue;

  const _InfoTarifBottomBar({
    required this.dp,
    required this.selectedCount,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(dp(16), dp(12), dp(16), bottom + dp(12)),
      decoration: BoxDecoration(
        color: SwappMenuColors.panel,
        boxShadow: [
          BoxShadow(
            color: SwappMenuColors.ink.withValues(alpha: 0.08),
            blurRadius: dp(16),
            offset: Offset(0, -dp(4)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(8)),
            decoration: BoxDecoration(
              color: SwappMenuColors.p1Bg,
              borderRadius: BorderRadius.circular(dp(12)),
            ),
            child: Text(
              '$selectedCount sélectionnée${selectedCount > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: dp(12),
                fontWeight: FontWeight.w800,
                color: SwappMenuColors.indigo,
              ),
            ),
          ),
          SizedBox(width: dp(12)),
          Expanded(
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: SwappMenuColors.indigo,
                padding: EdgeInsets.symmetric(vertical: dp(14)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(dp(14)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Voir les articles',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: dp(14),
                    ),
                  ),
                  SizedBox(width: dp(6)),
                  Icon(Icons.arrow_forward_rounded, size: dp(18)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
