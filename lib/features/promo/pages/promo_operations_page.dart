import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../rfid/providers/rfid_provider.dart';
import '../providers/promo_provider.dart';
import '../models/promo_model.dart';
import 'operation_products_page.dart';
import 'promo_scan_page.dart';
import '../../auth/providers/auth_provider.dart';

class PromoOperationsPage extends ConsumerStatefulWidget {
  const PromoOperationsPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PromoOperationsPage> createState() => _PromoOperationsPageState();
}

class _PromoOperationsPageState extends ConsumerState<PromoOperationsPage> {

  static const _indigo     = Color(0xFF3949AB);
  static const _indigoDark = Color(0xFF1A237E);
  static const _green      = Color(0xFF2E7D32);
  static const _amber      = Color(0xFFF59E0B);

  final _fmt = DateFormat('dd/MM/yyyy');
  bool _isUpdatingFds = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(promoProvider.notifier).loadOperations();
      _connectRfidIfNeeded();
    });
  }

  void _connectRfidIfNeeded() {
    final rfid = ref.read(rfidProvider);
    if (rfid.connectedReader != null) return;

    ref.read(rfidProvider.notifier).loadAvailableReaders().then((_) {
      final updated = ref.read(rfidProvider);
      if (updated.availableReaders.isNotEmpty &&
          updated.connectedReader == null) {
        ref
            .read(rfidProvider.notifier)
            .connectToReader(updated.availableReaders.first);
      }
    });
  }

  // APRÈS
  Future<void> _handleMajFds() async {
    final collab = ref.read(authProvider).collaborateur;
    if (collab == null) return;

    setState(() => _isUpdatingFds = true);

    final message = await ref.read(promoProvider.notifier).majFds(collab.codeCollab);

    if (!mounted) return;
    setState(() => _isUpdatingFds = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Échec de la mise à jour des FDS'),
        backgroundColor: message != null ? _green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(promoProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2FF),
        body: Column(
          children: [
            _buildHeader(state),
            _buildFdsUpdateBar(),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }
//button fds
  Widget _buildFdsUpdateBar() {
    return GestureDetector(
      onTap: _isUpdatingFds ? null : _handleMajFds,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _green.withOpacity(.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _green.withOpacity(.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Mettre à jour mes FDS :)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _indigoDark,
              ),
            ),
            const SizedBox(width: 8),
            _isUpdatingFds
                ? const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: _green),
            )
                : const Icon(Icons.sync_rounded, size: 18, color: _green),
          ],
        ),
      ),
    );
  }
  // ── Header ────────────────────────────────────────────────

  Widget _buildHeader(PromoState state) {
    final selectedCount = state.selectedOps.length;
    final allSelected = selectedCount == state.operations.length && state.operations.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_indigoDark, _indigo],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Retour
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 15),
                ),
              ),
              const SizedBox(width: 12),
              // Titre
              const Expanded(
                child: Text('Opérations Commerciales',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
              // Calendrier (filtre par date )
              GestureDetector(
                onTap: _openDateFilter,
                onLongPress: () => ref.read(promoProvider.notifier).clearDateFilter(),
                child: _headerIconButton(
                  icon: Icons.calendar_today_rounded,
                  onTap: _openDateFilter,
                  background: state.dateFilter != null ? _amber : null, // indique visuellement qu'un filtre est actif
                ),
              ),
              const SizedBox(width: 8),
              // Toggle tout sélectionner / tout désélectionner
              _headerIconButton(
                icon: Icons.library_add_check_rounded,
                onTap: () => allSelected
                    ? ref.read(promoProvider.notifier).deselectAll()
                    : ref.read(promoProvider.notifier).selectAll(),
                background: allSelected ? _green : null,
              ),
              const SizedBox(width: 8),
              // Flèche vers page suivante
              _headerIconButton(
                icon: Icons.arrow_forward_rounded,
                onTap: selectedCount > 0 ? _navigateToScanPage : null,
                background: selectedCount > 0 ? _green : Colors.white.withOpacity(.08),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    Color? background,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: background ?? Colors.white.withOpacity(.15),
          borderRadius: BorderRadius.circular(8),
          border: background == null
              ? Border.all(color: Colors.white.withOpacity(.3))
              : null,
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  void _navigateToScanPage() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const PromoScanPage(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<void> _openDateFilter() async {
    final current = ref.read(promoProvider).dateFilter;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      initialDateRange: current,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _indigo),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      ref.read(promoProvider.notifier).setDateFilter(picked);
    }
  }

  // ── Body ──────────────────────────────────────────────────

  Widget _buildBody(PromoState state) {
    if (state.isLoadingOps) {
      return const Center(
        child: CircularProgressIndicator(color: _indigo),
      );
    }

    if (state.error != null && state.operations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Color(0xFFD32F2F)),
              const SizedBox(height: 16),
              Text(state.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFD32F2F))),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(promoProvider.notifier).loadOperations(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _indigo,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    if (state.operations.isEmpty) {
      return const Center(
        child: Text('Aucune opération commerciale disponible',
            style: TextStyle(color: Colors.grey)),
      );
    }
    if (state.filteredOperations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Aucune opération sur cette période',
                  style: TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: () => ref.read(promoProvider.notifier).clearDateFilter(),
                child: const Text('Réinitialiser le filtre'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Text(
            'Sélectionnez une ou plusieurs opérations à vérifier',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.filteredOperations.length,              // <-- change
            itemBuilder: (context, i) =>
                _buildOperationCard(state.filteredOperations[i], state), // <-- change
          ),
        ),
      ],
    );
  }

  Widget _buildOperationCard(OperationCommerciale op, PromoState state) {
    final isSelected = state.selectedOps.contains(op.codePromo);
    final now = DateTime.now();
    final isActive = now.isAfter(op.dateDebut) && now.isBefore(op.dateFin);

    return GestureDetector(
      onTap: () =>
          ref.read(promoProvider.notifier).toggleOperation(op.codePromo),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _indigo : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _indigo.withOpacity(.08)
                  : Colors.black.withOpacity(.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? _indigo : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? _indigo : Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded,
                    color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 12),

              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            op.libPromo,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? _indigo
                                  : const Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                        // Badge FDS
                        if (op.fds)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _amber.withOpacity(.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: _amber.withOpacity(.4)),
                            ),
                            child: const Text('FDS',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: _amber)),
                          ),
                        const SizedBox(width: 4),
                        // Badge actif/inactif
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive
                                ? _green.withOpacity(.1)
                                : Colors.grey.withOpacity(.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isActive ? _green : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OperationProductsPage(
                                codePromo: op.codePromo,
                                libPromo: op.libPromo,
                              ),
                            ),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: _indigo.withOpacity(.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.visibility_rounded, size: 20, color: _indigo),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.tag_rounded,
                            size: 11, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Text('${op.codePromo}',
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[500])),
                        const SizedBox(width: 10),
                        Icon(Icons.calendar_today_rounded,
                            size: 11, color: Colors.grey[500]),
                        const SizedBox(width: 3),
                        Text(
                          '${_fmt.format(op.dateDebut)} → ${_fmt.format(op.dateFin)}',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: op.typeApplication == 'E'
                            ? const Color(0xFF7B1FA2).withOpacity(.1)
                            : _indigo.withOpacity(.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        op.typeApplication == 'E'
                            ? 'Application Enseigne'
                            : 'Application Produit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: op.typeApplication == 'E'
                              ? const Color(0xFF7B1FA2)
                              : _indigo,
                        ),
                      ),
                    ),
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