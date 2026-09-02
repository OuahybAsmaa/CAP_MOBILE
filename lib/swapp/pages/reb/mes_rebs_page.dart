// =============================================================================
// CapMobile — Module Swapp — Mes REBs (remises en banque)
// -----------------------------------------------------------------------------
// Fonctionnalité : Remises en banque du magasin — total en attente, onglets
//                  En attente / Traitées, contrôle écart caisse vs bordereau,
//                  validation d'une remise, ajout du bordereau manquant.
// Design         : Header navy (total + onglets segmentés) · cartes blanches
//                  (date, chip conformité, bordereau, collaborateur, montants)
//                  avec pied d'action pleine largeur navy ou orange.
// UI             : Ouverte par la tuile « Mes REBs » de SwappMenuPage.
// Architecture    : État via [rebProvider] ; données démo encapsulées dans le
//                   service, remplaçables par les endpoints sans modifier l'UI.
// Auteur         : H.AMIZIANI
// =============================================================================

import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:cap_mobile/core/apiswap/reb/providers/reb_provider.dart';
import 'package:cap_mobile/core/apiswap/shared/config/swapp_api_constants.dart';
import 'package:cap_mobile/features/auth/providers/auth_provider.dart';
import 'package:cap_mobile/swapp/models/reb/reb.dart';
import 'package:cap_mobile/swapp/pages/reb/ajouter_reb_page.dart';
import 'package:cap_mobile/swapp/widgets/reb_bordereau_image.dart';
import 'package:cap_mobile/swapp/widgets/swapp_attente_kit.dart';
import 'package:cap_mobile/swapp/widgets/swapp_menu_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Onglets de la page — remises à traiter ou déjà remises en banque.
enum _RebTab { enAttente, traitees }

const _rebHeaderIndigo = Color(0xFF2B2F8F);
const _rebHeaderDeep = Color(0xFF14173F);

/// Écran « Mes remises » — remises en banque du magasin.
class MesRebsPage extends ConsumerStatefulWidget {
  const MesRebsPage({super.key});

  static Route<void> fadeRoute() => swappMenuFadeRoute(const MesRebsPage());

  @override
  ConsumerState<MesRebsPage> createState() => _MesRebsPageState();
}

class _MesRebsPageState extends ConsumerState<MesRebsPage> {
  static final _euro = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  static const _green = Color(0xFF22C55E);

  _RebTab _tab = _RebTab.enAttente;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadBothRebs(reset: true),
    );
  }

  Future<void> _loadBothRebs({
    DateTimeRange? range,
    bool reset = false,
  }) async {
    await _loadRebs(
      range: range,
      enAttente: true,
      reset: reset,
    );
    if (!mounted) return;
    await _loadRebs(
      range: range,
      enAttente: false,
    );
  }

  Future<void> _loadRebs({
    DateTimeRange? range,
    required bool enAttente,
    bool reset = false,
  }) {
    final collab = ref.read(authProvider).collaborateur;
    final codeMag = SwappApiConstants.resolveCodeMagFromCollab(collab);
    return ref
        .read(rebProvider.notifier)
        .fetchRebs(
          codeMag: codeMag,
          du: range?.start,
          au: range?.end,
          enAttente: enAttente,
          reset: reset,
        );
  }

  List<RebItem> _filterByDate(List<RebItem> items) {
    final range = _dateRange;
    if (range == null) return items;
    final endExclusive = DateTime(
      range.end.year,
      range.end.month,
      range.end.day + 1,
    );
    return items
        .where(
          (reb) =>
              !reb.date.isBefore(range.start) &&
              reb.date.isBefore(endExclusive),
        )
        .toList(growable: false);
  }

  List<RebItem> _visibleItems(List<RebItem> items) {
    final attendu = _tab == _RebTab.enAttente
        ? RebStatut.enAttente
        : RebStatut.traitee;
    return items.where((reb) => reb.statut == attendu).toList();
  }

  int _nbEnAttente(List<RebItem> items) =>
      items.where((reb) => reb.statut == RebStatut.enAttente).length;

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _selectTab(_RebTab tab) {
    if (tab == _tab) return;
    HapticFeedback.selectionClick();
    setState(() => _tab = tab);
    final expected = tab == _RebTab.enAttente
        ? RebStatut.enAttente
        : RebStatut.traitee;
    final alreadyLoaded = ref
        .read(rebProvider)
        .items
        .any((item) => item.statut == expected);
    if (!alreadyLoaded) {
      _loadRebs(
        range: _dateRange,
        enAttente: tab == _RebTab.enAttente,
      );
    }
  }

  /// Ouvre l'agenda de période : premier jour, dernier jour, puis « Valider ».
  Future<void> _selectDateRange() async {
    HapticFeedback.selectionClick();
    final selected = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: _rebHeaderDeep.withValues(alpha: 0.55),
      builder: (_) => _RebDateFilterSheet(initialRange: _dateRange),
    );
    if (selected == null || !mounted) return;
    setState(() => _dateRange = selected);
    await _loadBothRebs(
      range: selected,
      reset: true,
    );
  }

  /// Ouvre l'écran vert avec la remise et son montant déjà sélectionnés.
  Future<void> _validerRemise(RebItem reb) async {
    HapticFeedback.mediumImpact();
    final created = await Navigator.push<RebItem?>(
      context,
      AjouterRebPage.fadeRoute(initialReb: reb),
    );
    if (!mounted || created == null) return;
    setState(() => _tab = _RebTab.traitees);
    _snack('Remise du ${_dateFormat.format(reb.date)} validée.');
  }

  /// Ouvre le formulaire. La création est effectuée par rebProvider ; au
  /// retour, la liste est déjà mise à jour et reste prête pour la future API.
  Future<void> _openCreate() async {
    HapticFeedback.lightImpact();
    final created = await Navigator.push<RebItem?>(
      context,
      AjouterRebPage.fadeRoute(),
    );
    if (!mounted || created == null) return;
    setState(() => _tab = _RebTab.traitees);
    _snack('Remise en banque validée avec succès.');
  }

  void _ajouterBordereau(RebItem reb) {
    HapticFeedback.selectionClick();
    // TODO(API) : capture image_picker puis upload du bordereau.
    _snack('Bordereau du ${_dateFormat.format(reb.date)} — photo bientôt');
  }

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 360).clamp(0.9, 1.35);
    double dp(double v) => v * scale;
    final insets = MediaQuery.paddingOf(context);
    final rebState = ref.watch(rebProvider);
    final items = rebState.items;
    final dateFilteredItems = _filterByDate(items);
    final visible = _visibleItems(dateFilteredItems);
    final nbEnAttente = _nbEnAttente(dateFilteredItems);
    final totalVisible = visible.fold<double>(
      0,
      (total, reb) => total + reb.encaissement,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: SwappMenuColors.bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: SwappMenuColors.bg,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              dp: dp,
              top: insets.top,
              total: _euro.format(totalVisible),
              subtitle: _tab == _RebTab.enAttente
                  ? '${visible.length} REMISE${visible.length > 1 ? 'S' : ''} EN ATTENTE'
                  : '${visible.length} REMISE${visible.length > 1 ? 'S' : ''} TRAITÉE${visible.length > 1 ? 'S' : ''}',
              nbEnAttente: nbEnAttente,
              nbTraitees: dateFilteredItems.length - nbEnAttente,
              tab: _tab,
              green: _green,
              onBack: () => Navigator.pop(context),
              dateRangeLabel: _dateRange == null
                  ? null
                  : '${DateFormat('dd/MM').format(_dateRange!.start)} – '
                        '${DateFormat('dd/MM').format(_dateRange!.end)}',
              onFilterDate: _selectDateRange,
              onClearDateRange: () {
                setState(() => _dateRange = null);
                _loadBothRebs(reset: true);
              },
              onCreate: _openCreate,
              onBanque: () => _snack('Coordonnées bancaires — bientôt'),
              onSelectTab: _selectTab,
            ),
            Expanded(
              child: rebState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : rebState.error != null && items.isEmpty
                  ? SwappAttenteEmptyState(
                      dp: dp,
                      icon: Icons.cloud_off_rounded,
                      title: 'Remises indisponibles',
                      hint: rebState.error!,
                    )
                  : visible.isEmpty
                  ? SwappAttenteEmptyState(
                      dp: dp,
                      icon: Icons.account_balance_wallet_outlined,
                      title: _tab == _RebTab.enAttente
                          ? 'Aucune remise en attente'
                          : 'Aucune remise traitée',
                      hint: _tab == _RebTab.enAttente
                          ? 'Utilisez + pour déclarer une remise.'
                          : 'Les remises validées apparaîtront ici.',
                    )
                  : ListView.separated(
                      // Marge basse = barre de navigation Android incluse.
                      padding: EdgeInsets.fromLTRB(
                        dp(12),
                        dp(12),
                        dp(12),
                        dp(24) + insets.bottom,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => SizedBox(height: dp(12)),
                      itemBuilder: (context, index) {
                        final reb = visible[index];
                        return _RebCard(
                          dp: dp,
                          reb: reb,
                          dateLabel: _dateFormat.format(reb.date),
                          encaissementLabel: _euro.format(reb.encaissement),
                          declareLabel: _euro.format(reb.declareReb),
                          venteDateLabel: reb.dateVente == null
                              ? _dateFormat.format(reb.date)
                              : _dateFormat.format(reb.dateVente!),
                          onValider: () => _validerRemise(reb),
                          onAjouterBordereau: () => _ajouterBordereau(reb),
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

class _RebDateFilterSheet extends StatefulWidget {
  const _RebDateFilterSheet({this.initialRange});

  final DateTimeRange? initialRange;

  @override
  State<_RebDateFilterSheet> createState() => _RebDateFilterSheetState();
}

class _RebDateFilterSheetState extends State<_RebDateFilterSheet> {
  static final _format = DateFormat('dd/MM/yyyy');
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _startController;
  late final TextEditingController _endController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final range = widget.initialRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 8)),
          end: now,
        );
    _startController = TextEditingController(text: _format.format(range.start));
    _endController = TextEditingController(text: _format.format(range.end));
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  DateTime? _parse(String value) {
    try {
      return _format.parseStrict(value.trim());
    } catch (_) {
      return null;
    }
  }

  Future<void> _pick(TextEditingController controller) async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('fr', 'FR'),
      initialDate: _parse(controller.text) ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: _rebHeaderIndigo,
            secondary: const Color(0xFFF59E0B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) controller.text = _format.format(picked);
  }

  void _preset(int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    setState(() {
      _startController.text = _format.format(start);
      _endController.text = _format.format(end);
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final start = _parse(_startController.text)!;
    final end = _parse(_endController.text)!;
    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date de fin précède la date de début.')),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    Navigator.pop(context, DateTimeRange(start: start, end: end));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7DAE8),
                        borderRadius: BorderRadius.circular(99),
                      ),
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
                            colors: [_rebHeaderIndigo, Color(0xFF6269E8)],
                          ),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.date_range_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filtrer par période',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: _rebHeaderDeep,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Saisissez une date ou utilisez le calendrier',
                              style: TextStyle(
                                fontSize: 12,
                                color: SwappMenuColors.inkDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      for (final days in const [7, 15, 30]) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _preset(days),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _rebHeaderIndigo,
                              side: const BorderSide(color: Color(0xFFD9DCF5)),
                              shape: const StadiumBorder(),
                            ),
                            child: Text('$days jours'),
                          ),
                        ),
                        if (days != 30) const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _RebDateField(
                          label: 'Du',
                          controller: _startController,
                          onCalendar: () => _pick(_startController),
                          parser: _parse,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(8, 42, 8, 0),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: SwappMenuColors.inkDim,
                        ),
                      ),
                      Expanded(
                        child: _RebDateField(
                          label: 'Au',
                          controller: _endController,
                          onCalendar: () => _pick(_endController),
                          parser: _parse,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: _rebHeaderIndigo,
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          icon: const Icon(Icons.sync_rounded),
                          label: const Text('Appliquer et synchroniser'),
                        ),
                      ),
                    ],
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

class _RebDateField extends StatelessWidget {
  const _RebDateField({
    required this.label,
    required this.controller,
    required this.onCalendar,
    required this.parser,
  });

  final String label;
  final TextEditingController controller;
  final VoidCallback onCalendar;
  final DateTime? Function(String) parser;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.datetime,
    textInputAction: TextInputAction.next,
    validator: (value) => parser(value ?? '') == null ? 'Date invalide' : null,
    decoration: InputDecoration(
      labelText: label,
      hintText: 'jj/mm/aaaa',
      filled: true,
      fillColor: const Color(0xFFF5F6FC),
      suffixIcon: IconButton(
        onPressed: onCalendar,
        icon: const Icon(Icons.calendar_month_rounded),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE1E4F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _rebHeaderIndigo, width: 2),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Header navy — total, actions et onglets
// ---------------------------------------------------------------------------
class _Header extends StatelessWidget {
  final double Function(double) dp;
  final double top;
  final String total;
  final String subtitle;
  final int nbEnAttente;
  final int nbTraitees;
  final _RebTab tab;
  final Color green;
  final VoidCallback onBack;
  final VoidCallback onFilterDate;
  final VoidCallback onClearDateRange;
  final VoidCallback onCreate;
  final VoidCallback onBanque;
  final ValueChanged<_RebTab> onSelectTab;
  final String? dateRangeLabel;

  const _Header({
    required this.dp,
    required this.top,
    required this.total,
    required this.subtitle,
    required this.nbEnAttente,
    required this.nbTraitees,
    required this.tab,
    required this.green,
    required this.onBack,
    required this.onFilterDate,
    required this.onClearDateRange,
    required this.onCreate,
    required this.onBanque,
    required this.onSelectTab,
    this.dateRangeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.85, -0.9),
          radius: 1.35,
          colors: [Color(0xFF363BA8), _rebHeaderIndigo, _rebHeaderDeep],
          stops: [0, 0.38, 1],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(dp(14), top + dp(7), dp(14), dp(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _RebHeaderGlassButton(
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
                        'BANQUE',
                        style: TextStyle(
                          fontSize: dp(9.5),
                          fontWeight: FontWeight.w800,
                          color: Colors.white.withValues(alpha: 0.55),
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: dp(2)),
                      Text(
                        'Mes remises',
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
                _RebCalendarButton(
                  dp: dp,
                  active: dateRangeLabel != null,
                  onTap: onFilterDate,
                ),
                SizedBox(width: dp(8)),
                _RebHeaderGlassButton(
                  dp: dp,
                  icon: Icons.account_balance_outlined,
                  onTap: onBanque,
                ),
                SizedBox(width: dp(8)),
                Material(
                  color: green,
                  borderRadius: BorderRadius.circular(dp(11)),
                  elevation: 4,
                  shadowColor: green.withValues(alpha: 0.5),
                  child: InkWell(
                    onTap: onCreate,
                    borderRadius: BorderRadius.circular(dp(11)),
                    child: SizedBox(
                      width: dp(36),
                      height: dp(36),
                      child: Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: dp(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: dp(10)),
            Row(
              children: [
                Expanded(
                  child: _RebHeaderStat(
                    dp: dp,
                    icon: Icons.payments_outlined,
                    label: subtitle,
                    value: total,
                  ),
                ),
                SizedBox(width: dp(10)),
                Expanded(
                  child: _RebHeaderStat(
                    dp: dp,
                    icon: Icons.calendar_today_rounded,
                    label: 'PÉRIODE',
                    value: dateRangeLabel ?? 'Toutes les dates',
                    onTap: onFilterDate,
                    onClear: dateRangeLabel == null ? null : onClearDateRange,
                  ),
                ),
              ],
            ),
            SizedBox(height: dp(10)),
            _RebStatusTabs(
              dp: dp,
              selected: tab,
              pendingCount: nbEnAttente,
              processedCount: nbTraitees,
              onSelect: onSelectTab,
            ),
          ],
        ),
      ),
    );
  }
}

class _RebHeaderGlassButton extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final VoidCallback onTap;

  const _RebHeaderGlassButton({
    required this.dp,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(dp(11)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(11)),
        child: SizedBox(
          width: dp(36),
          height: dp(36),
          child: Icon(icon, color: Colors.white, size: dp(17)),
        ),
      ),
    );
  }
}

class _RebCalendarButton extends StatelessWidget {
  const _RebCalendarButton({
    required this.dp,
    required this.active,
    required this.onTap,
  });

  final double Function(double) dp;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: active ? 'Modifier la période' : 'Filtrer par date',
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

class _RebHeaderStat extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _RebHeaderStat({
    required this.dp,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(dp(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(14)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: dp(11), vertical: dp(9)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(dp(14)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: dp(11),
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                  SizedBox(width: dp(5)),
                  Expanded(
                    child: Text(
                      label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dp(8),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.45,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  if (onClear != null)
                    GestureDetector(
                      onTap: onClear,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.only(left: dp(5)),
                        child: Icon(
                          Icons.close_rounded,
                          size: dp(13),
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: dp(4)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: dp(15),
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
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

/// Sélecteur REB inspiré de la maquette : grande pilule blanche active,
/// couleurs métier distinctes et compteurs très lisibles.
class _RebStatusTabs extends StatelessWidget {
  final double Function(double) dp;
  final _RebTab selected;
  final int pendingCount;
  final int processedCount;
  final ValueChanged<_RebTab> onSelect;

  const _RebStatusTabs({
    required this.dp,
    required this.selected,
    required this.pendingCount,
    required this.processedCount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dp(4)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(dp(15)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RebStatusTab(
              dp: dp,
              label: 'En attente',
              icon: Icons.schedule_rounded,
              count: pendingCount,
              active: selected == _RebTab.enAttente,
              accent: const Color(0xFFF59E0B),
              onTap: () => onSelect(_RebTab.enAttente),
            ),
          ),
          SizedBox(width: dp(4)),
          Expanded(
            child: _RebStatusTab(
              dp: dp,
              label: 'Traitées',
              icon: Icons.check_circle_outline_rounded,
              count: processedCount,
              active: selected == _RebTab.traitees,
              accent: const Color(0xFF3B82F6),
              onTap: () => onSelect(_RebTab.traitees),
            ),
          ),
        ],
      ),
    );
  }
}

class _RebStatusTab extends StatelessWidget {
  final double Function(double) dp;
  final String label;
  final IconData icon;
  final int count;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const _RebStatusTab({
    required this.dp,
    required this.label,
    required this.icon,
    required this.count,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = active ? SwappAttenteColors.headerNavy : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(dp(11)),
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: dp(10),
                  offset: Offset(0, dp(3)),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(dp(11)),
          child: SizedBox(
            height: dp(42),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: active ? accent : foreground, size: dp(18)),
                SizedBox(width: dp(7)),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: dp(11.5),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(width: dp(7)),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  padding: EdgeInsets.symmetric(
                    horizontal: dp(7),
                    vertical: dp(3),
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? accent.withValues(alpha: 0.14)
                        : accent.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(dp(12)),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: active ? accent : Colors.white,
                      fontSize: dp(10),
                      fontWeight: FontWeight.w900,
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
}

// ---------------------------------------------------------------------------
// Carte d'une remise — 3 colonnes comme la maquette
// Collaborateur | Photo bordereau | Montants + Valider
// ---------------------------------------------------------------------------
const _orangeAmount = Color(0xFFE8912B);

class _RebCard extends StatelessWidget {
  final double Function(double) dp;
  final RebItem reb;
  final String dateLabel;
  final String encaissementLabel;
  final String declareLabel;
  final String venteDateLabel;
  final VoidCallback onValider;
  final VoidCallback onAjouterBordereau;

  const _RebCard({
    required this.dp,
    required this.reb,
    required this.dateLabel,
    required this.encaissementLabel,
    required this.declareLabel,
    required this.venteDateLabel,
    required this.onValider,
    required this.onAjouterBordereau,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(dp(8), dp(9), dp(8), dp(9)),
      decoration: BoxDecoration(
        color: SwappMenuColors.panel,
        borderRadius: BorderRadius.circular(dp(18)),
        boxShadow: [
          BoxShadow(
            color: SwappMenuColors.ink.withValues(alpha: 0.07),
            blurRadius: dp(14),
            offset: Offset(0, dp(5)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: dp(
              reb.statut == RebStatut.enAttente ? 200 : 190,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            // Colonne 1 — avatar, date, puis signature
            Expanded(
              flex: 27,
              child: _IdentitySignatureColumn(
                dp: dp,
                reb: reb,
                dateLabel: dateLabel,
                signatureUrl: reb.signatureUrl,
                showSignature: reb.statut == RebStatut.traitee,
                onMissingTap: onAjouterBordereau,
              ),
            ),
            _VDivider(dp: dp),
            // Colonne 2 — justificatif agrandi au milieu
            Expanded(
              flex: 35,
              child: _DocumentColumn(
                dp: dp,
                justificatifUrl: reb.bordereauUrl,
                onMissingTap: onAjouterBordereau,
              ),
            ),
            _VDivider(dp: dp),
            // Colonne 3 — montants + action (sans badge Conforme)
            Expanded(
              flex: 38,
              child: _AmountsColumn(
                dp: dp,
                bordereauLabel: encaissementLabel,
                declareLabel: declareLabel,
                venteDateLabel: venteDateLabel,
                caissiereLabel: reb.prenomCaissiereEnc,
                banqueLabel: reb.codeBanque,
                traite: reb.statut == RebStatut.traitee,
                onValider: onValider,
              ),
            ),
              ],
            ),
          ),
          if (reb.observations?.trim().isNotEmpty == true) ...[
            SizedBox(height: dp(9)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: dp(10),
                vertical: dp(7),
              ),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(dp(10)),
              ),
              child: Text(
                reb.observations!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: dp(10.5),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VDivider extends StatelessWidget {
  final double Function(double) dp;
  const _VDivider({required this.dp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: EdgeInsets.symmetric(horizontal: dp(3)),
      color: SwappMenuColors.ink.withValues(alpha: 0.08),
    );
  }
}

class _ProfileColumn extends StatelessWidget {
  final double Function(double) dp;
  final RebItem reb;
  final String dateLabel;

  const _ProfileColumn({
    required this.dp,
    required this.reb,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    final size = dp(48);

    return Column(
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: SwappMenuColors.p1Bg,
            shape: BoxShape.circle,
            border: Border.all(
              color: SwappAttenteColors.headerNavy.withValues(alpha: 0.15),
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: reb.photoUrl != null && reb.photoUrl!.trim().isNotEmpty
              ? Image.network(
                  reb.photoUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _initiales(),
                )
              : _initiales(),
        ),
        SizedBox(height: dp(4)),
        Text(
          reb.prenom.isEmpty ? 'Collaborateur' : reb.prenom,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: dp(11.5),
            fontWeight: FontWeight.w900,
            color: SwappAttenteColors.headerNavy,
          ),
        ),
        SizedBox(height: dp(5)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: dp(3),
            vertical: dp(4),
          ),
          decoration: BoxDecoration(
            color: SwappMenuColors.p1Bg,
            borderRadius: BorderRadius.circular(dp(8)),
          ),
          child: Text(
            dateLabel,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: dp(9),
              fontWeight: FontWeight.w900,
              color: SwappAttenteColors.headerNavy,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _initiales() => Text(
    reb.initiales,
    style: TextStyle(
      fontSize: dp(16),
      fontWeight: FontWeight.w900,
      color: SwappMenuColors.p1,
    ),
  );
}

class _DocumentColumn extends StatelessWidget {
  final double Function(double) dp;
  final String? justificatifUrl;
  final VoidCallback onMissingTap;

  const _DocumentColumn({
    required this.dp,
    required this.justificatifUrl,
    required this.onMissingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _MediaPreview(
            dp: dp,
            label: 'JUSTIFICATIF',
            source: justificatifUrl,
            missingIcon: Icons.add_a_photo_rounded,
            onMissingTap: onMissingTap,
            onOpen: () => _openFullscreen(context, justificatifUrl),
          ),
        ),
      ],
    );
  }

  void _openFullscreen(BuildContext context, String? source) {
    if (source == null || source.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 5,
              child: RebBordereauImage(source: source, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(ctx).top + 8,
            right: 12,
            child: IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({
    required this.dp,
    required this.label,
    required this.source,
    required this.missingIcon,
    required this.onMissingTap,
    required this.onOpen,
  });

  final double Function(double) dp;
  final String label;
  final String? source;
  final IconData missingIcon;
  final VoidCallback onMissingTap;
  final VoidCallback onOpen;

  bool get _missing => source == null || source!.trim().isEmpty;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: dp(8),
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: SwappMenuColors.inkDim,
        ),
      ),
      SizedBox(height: dp(3)),
      Expanded(
        child: Material(
          color: _missing ? SwappMenuColors.p5Bg : SwappMenuColors.bg,
          borderRadius: BorderRadius.circular(dp(8)),
          child: InkWell(
            onTap: _missing ? onMissingTap : onOpen,
            borderRadius: BorderRadius.circular(dp(8)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(dp(8)),
              child: _missing
                  ? Center(
                      child: Icon(
                        missingIcon,
                        size: dp(18),
                        color: SwappMenuColors.p5,
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        RebBordereauImage(source: source),
                        Positioned(
                          right: dp(4),
                          bottom: dp(4),
                          child: Container(
                            padding: EdgeInsets.all(dp(3)),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.open_in_full_rounded,
                              size: dp(10),
                              color: Colors.white,
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
  );
}

class _IdentitySignatureColumn extends StatelessWidget {
  const _IdentitySignatureColumn({
    required this.dp,
    required this.reb,
    required this.dateLabel,
    required this.signatureUrl,
    required this.showSignature,
    required this.onMissingTap,
  });

  final double Function(double) dp;
  final RebItem reb;
  final String dateLabel;
  final String? signatureUrl;
  final bool showSignature;
  final VoidCallback onMissingTap;

  @override
  Widget build(BuildContext context) {
    final profile = _ProfileColumn(dp: dp, reb: reb, dateLabel: dateLabel);
    if (!showSignature) return Center(child: profile);

    return Column(
      children: [
        profile,
        SizedBox(height: dp(5)),
        Expanded(
          child: _MediaPreview(
            dp: dp,
            label: 'SIGNATURE',
            source: signatureUrl,
            missingIcon: Icons.draw_rounded,
            onMissingTap: onMissingTap,
            onOpen: () => _openFullscreen(context, signatureUrl),
          ),
        ),
      ],
    );
  }

  void _openFullscreen(BuildContext context, String? source) {
    if (source == null || source.trim().isEmpty) return;
    HapticFeedback.selectionClick();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              maxScale: 5,
              child: RebBordereauImage(source: source, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: MediaQuery.paddingOf(ctx).top + 8,
            right: 12,
            child: IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountsColumn extends StatelessWidget {
  final double Function(double) dp;
  final String bordereauLabel;
  final String declareLabel;
  final String venteDateLabel;
  final String caissiereLabel;
  final String? banqueLabel;
  final bool traite;
  final VoidCallback onValider;

  const _AmountsColumn({
    required this.dp,
    required this.bordereauLabel,
    required this.declareLabel,
    required this.venteDateLabel,
    required this.caissiereLabel,
    required this.banqueLabel,
    required this.traite,
    required this.onValider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: dp(14)),
        Container(
          padding: EdgeInsets.all(dp(7)),
          decoration: BoxDecoration(
            color: SwappMenuColors.p1Bg,
            borderRadius: BorderRadius.circular(dp(9)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.event_rounded,
                size: dp(13),
                color: SwappMenuColors.indigo,
              ),
              SizedBox(width: dp(5)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venteDateLabel,
                      style: TextStyle(
                        fontSize: dp(9.5),
                        fontWeight: FontWeight.w900,
                        color: SwappAttenteColors.headerNavy,
                      ),
                    ),
                    if (caissiereLabel.trim().isNotEmpty)
                      Text(
                        caissiereLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: dp(9),
                          fontWeight: FontWeight.w700,
                          color: SwappMenuColors.inkDim,
                        ),
                      ),
                  ],
                ),
              ),
              if (banqueLabel?.trim().isNotEmpty == true)
                Text(
                  banqueLabel!,
                  style: TextStyle(
                    fontSize: dp(9),
                    fontWeight: FontWeight.w900,
                    color: SwappMenuColors.indigo,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: dp(8)),
        _AmountLine(
          dp: dp,
          label: 'ENCAISSEMENT',
          value: bordereauLabel,
          color: _orangeAmount,
        ),
        SizedBox(height: dp(8)),
        Divider(height: 1, color: SwappMenuColors.ink.withValues(alpha: 0.08)),
        SizedBox(height: dp(8)),
        _AmountLine(
          dp: dp,
          label: 'DÉCLARÉ REB',
          value: declareLabel,
          color: SwappAttenteColors.headerNavy,
        ),
        if (traite) const Spacer(),
        if (!traite) ...[
          SizedBox(height: dp(7)),
          _ActionButton(
            dp: dp,
            color: AppColors.success,
            icon: Icons.check_rounded,
            label: 'Valider',
            onTap: onValider,
          ),
        ],
      ],
    );
  }
}

class _AmountLine extends StatelessWidget {
  final double Function(double) dp;
  final String label;
  final String value;
  final Color color;

  const _AmountLine({
    required this.dp,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: dp(9),
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: SwappMenuColors.inkDim,
          ),
        ),
        SizedBox(height: dp(3)),
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: dp(13),
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final double Function(double) dp;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.dp,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(dp(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(12)),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: dp(6), vertical: dp(10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: dp(15), color: Colors.white),
              SizedBox(width: dp(5)),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: dp(10.5),
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
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
