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
import 'package:cap_mobile/core/apiswap/shared/config/swapp_api_constants.dart';
import 'package:cap_mobile/core/widgets/app_popup.dart';
import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';
import 'package:cap_mobile/core/apiswap/produit/providers/swapp_product_provider.dart';
import 'package:cap_mobile/features/auth/providers/auth_provider.dart';
import 'package:cap_mobile/swapp/models/info_tarif_item.dart';
import 'package:cap_mobile/swapp/pages/tarif/info_tarif_articles_page.dart';
import 'package:cap_mobile/swapp/pages/tarif/info_tarif_product_page.dart';
import 'package:cap_mobile/swapp/pages/produit/detail_produit_page.dart';
import 'package:cap_mobile/swapp/widgets/qr_camera_scanner_page.dart';
import 'package:cap_mobile/swapp/widgets/swapp_tool_buttons.dart';
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
        .fetchOperations(
          codeMag: SwappApiConstants.resolveCodeMagFromCollab(collab),
        );
  }

  Future<void> _syncFds() async {
    HapticFeedback.mediumImpact();
    final collab = ref.read(authProvider).collaborateur;
    final codeCollab = collab?.codeCollab ?? 0;
    if (codeCollab <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur connecté invalide')),
      );
      return;
    }
    final confirmed = await AppPopup.confirm(
      context,
      icon: Icons.sync_rounded,
      title: 'Mettre à jour les FDS ?',
      message: 'Vous allez recalculer votre opération FDS, continuez ?',
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(infoTarifProvider.notifier)
        .syncFds(
          codeMag: SwappApiConstants.resolveCodeMagFromCollab(collab),
          codeCollab: codeCollab,
        );
    if (!mounted) return;
    final error = ref.read(infoTarifProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'FDS mis à jour'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openAgendaCalendar() async {
    final state = ref.read(infoTarifProvider);
    final selection = await showModalBottomSheet<_TarifDateSelection>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (context) => _InfoTarifDateFilterSheet(
        initialDate: state.filterDate,
      ),
    );
    if (!mounted || selection == null) return;
    ref.read(infoTarifProvider.notifier).setFilterDate(selection.date);
  }

  void _toggleSelectAll() {
    HapticFeedback.selectionClick();
    ref.read(infoTarifProvider.notifier).toggleSelectAllVisible();
  }

  Future<void> _openProductCode(String code) async {
    final value = code.trim();
    if (value.isEmpty) return;
    await ref
        .read(swappProductProvider.notifier)
        .fetchModele(codeModele: value);
    if (!mounted) return;
    await Navigator.push(
      context,
      DetailProduitPage.fadeRoute(loadDefaultProduct: false),
    );
  }

  Future<void> _scanQr() async {
    final code = await openQrCameraScanner(context, context.l10n);
    if (!mounted || code == null) return;
    await _openProductCode(code);
  }

  Future<void> _enterBarcode() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Saisir un code-barres'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.keyboard_alt_rounded),
            hintText: 'Code article ou code-barres',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || code == null) return;
    await _openProductCode(code);
  }

  void _openArticles(List<InfoTarifItem> operations) {
    if (operations.isEmpty) return;
    HapticFeedback.lightImpact();
    Navigator.push(context, InfoTarifArticlesPage.fadeRoute(operations));
  }

  void _openTarifProduct(List<InfoTarifItem> operations) {
    if (operations.isEmpty) return;
    HapticFeedback.lightImpact();
    Navigator.push(context, InfoTarifProductPage.fadeRoute(operations));
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
            dateFilterActive: state.filterDate != null,
            onNext: selected.isNotEmpty
                ? () => _openTarifProduct(selected)
                : null,
          ),
          _LegacyToolbar(
            dp: dp,
            isSyncing: state.isSyncingFds,
            onSyncFds: _syncFds,
            onEnterBarcode: _enterBarcode,
            onScanQr: _scanQr,
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
  final bool dateFilterActive;
  final VoidCallback? onNext;

  const _LegacyAppBar({
    required this.dp,
    required this.onBack,
    required this.onCalendar,
    required this.onToggleSelectAll,
    required this.allSelected,
    required this.hasOperations,
    required this.dateFilterActive,
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
          _TarifCalendarButton(
            dp: dp,
            active: dateFilterActive,
            onTap: onCalendar,
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

/// Même bouton agenda que celui utilisé dans « Remises en banque ».
class _TarifCalendarButton extends StatelessWidget {
  const _TarifCalendarButton({
    required this.dp,
    required this.active,
    required this.onTap,
  });

  final double Function(double) dp;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: active ? 'Modifier la date' : 'Filtrer par date',
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(dp(12)),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(dp(12)),
        child: Container(
          width: dp(38),
          height: dp(38),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFC857), Color(0xFFF59E0B)],
            ),
            borderRadius: BorderRadius.circular(dp(12)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55F59E0B),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: Colors.white,
                size: dp(20),
              ),
              if (active)
                Positioned(
                  top: dp(4),
                  right: dp(4),
                  child: Container(
                    width: dp(8),
                    height: dp(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TarifDateSelection {
  const _TarifDateSelection(this.date);

  final DateTime? date;
}

class _InfoTarifDateFilterSheet extends StatefulWidget {
  const _InfoTarifDateFilterSheet({required this.initialDate});

  final DateTime? initialDate;

  @override
  State<_InfoTarifDateFilterSheet> createState() =>
      _InfoTarifDateFilterSheetState();
}

class _InfoTarifDateFilterSheetState
    extends State<_InfoTarifDateFilterSheet> {
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _firstDate = DateTime(2020);
  static final _lastDate = DateTime(2035, 12, 31);
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final candidate = widget.initialDate ?? DateTime.now();
    if (candidate.isBefore(_firstDate)) {
      _selectedDate = _firstDate;
    } else if (candidate.isAfter(_lastDate)) {
      _selectedDate = _lastDate;
    } else {
      _selectedDate = DateTime(candidate.year, candidate.month, candidate.day);
    }
  }

  void _selectQuickDate(DateTime date) {
    HapticFeedback.selectionClick();
    setState(() => _selectedDate = DateTime(date.year, date.month, date.day));
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(18, 10, 18, 18 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFC857), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x44F59E0B),
                          blurRadius: 12,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtrer par date',
                          style: TextStyle(
                            color: Color(0xFF172033),
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sélectionnez la date des opérations',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.event_available_rounded,
                      color: Color(0xFF1D4ED8),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _dateFormat.format(_selectedDate),
                      style: const TextStyle(
                        color: Color(0xFF1E3A8A),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF24318F),
                    brightness: Brightness.light,
                  ),
                  datePickerTheme: const DatePickerThemeData(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: CalendarDatePicker(
                    key: ValueKey(_selectedDate),
                    initialDate: _selectedDate,
                    firstDate: _firstDate,
                    lastDate: _lastDate,
                    onDateChanged: (date) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedDate = date);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TarifQuickDateButton(
                      label: 'Hier',
                      onTap: () => _selectQuickDate(
                        now.subtract(const Duration(days: 1)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TarifQuickDateButton(
                      label: "Aujourd’hui",
                      emphasized: true,
                      onTap: () => _selectQuickDate(now),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _TarifQuickDateButton(
                      label: 'Demain',
                      onTap: () => _selectQuickDate(
                        now.add(const Duration(days: 1)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(
                        context,
                        const _TarifDateSelection(null),
                      ),
                      icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                      label: const Text('Tout afficher'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        minimumSize: const Size(0, 48),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x4424318F),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(
                          context,
                          _TarifDateSelection(_selectedDate),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 19),
                        label: const Text('Appliquer'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarifQuickDateButton extends StatelessWidget {
  const _TarifQuickDateButton({
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Material(
    color: emphasized ? const Color(0xFFE0E7FF) : Colors.white,
    borderRadius: BorderRadius.circular(12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: emphasized
                ? const Color(0xFFA5B4FC)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: emphasized
                ? const Color(0xFF3730A3)
                : const Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

class _LegacyToolbar extends StatelessWidget {
  final double Function(double) dp;
  final bool isSyncing;
  final VoidCallback onSyncFds;
  final VoidCallback onEnterBarcode;
  final VoidCallback onScanQr;

  const _LegacyToolbar({
    required this.dp,
    required this.isSyncing,
    required this.onSyncFds,
    required this.onEnterBarcode,
    required this.onScanQr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: SwappMenuColors.panel,
      padding: EdgeInsets.fromLTRB(dp(14), dp(10), dp(14), dp(10)),
      child: Row(
        children: [
          SwappCompactToolbar(
            buttonSize: dp(48),
            gap: dp(8),
            showRanger: false,
            showNfc: false,
            onArticleSearch: onEnterBarcode,
            onQrScan: onScanQr,
          ),
          SizedBox(width: dp(10)),
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(dp(18)),
              elevation: 7,
              shadowColor: const Color(0xFF00695C).withValues(alpha: 0.45),
              child: InkWell(
                onTap: isSyncing ? null : onSyncFds,
                borderRadius: BorderRadius.circular(dp(18)),
                child: Ink(
                  height: dp(48),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(dp(18)),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0C9B87), Color(0xFF006A61)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSyncing)
                        SizedBox(
                          width: dp(18),
                          height: dp(18),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else
                        Icon(Icons.sync_rounded, color: Colors.white, size: dp(20)),
                      SizedBox(width: dp(7)),
                      Flexible(
                        child: Text(
                          'Mettre à jour FDS',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: dp(11.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
