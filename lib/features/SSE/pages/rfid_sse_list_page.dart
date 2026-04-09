import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../rfid/pages/rfid_constants.dart';
import '../../rfid/pages/rfid_encoding_page.dart' show SseSessionEntry;

// ──────────────────────────────────────────────────────────────
//  RFID SSE LIST PAGE
// ──────────────────────────────────────────────────────────────
class RfidSseListPage extends StatefulWidget {
  final List<SseSessionEntry> entries;

  const RfidSseListPage({Key? key, required this.entries}) : super(key: key);

  @override
  State<RfidSseListPage> createState() => _RfidSseListPageState();
}

class _RfidSseListPageState extends State<RfidSseListPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _entranceCtrl;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  List<SseSessionEntry> get _filtered {
    if (_searchQuery.isEmpty) return widget.entries;
    final q = _searchQuery.toLowerCase();
    return widget.entries.where((e) =>
    e.libArticle.toLowerCase().contains(q) ||
        e.marque.toLowerCase().contains(q) ||
        e.epc.toLowerCase().contains(q) ||
        e.gencode.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Column(
          children: [
            _buildHeader(widget.entries.length),
            _buildSearchBar(),
            Expanded(
              child: widget.entries.isEmpty
                  ? _buildEmptyState()
                  : filtered.isEmpty
                  ? _buildNoResultState()
                  : _buildList(filtered),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  HEADER
  // ──────────────────────────────────────────────────────────────
  Widget _buildHeader(int total) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Retour
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(.3)),
                    ),
                    child: const Icon(Icons.list_alt_rounded,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Encodages de la session',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            )),
                        Text(
                          '$total puce${total > 1 ? 's' : ''} encodée${total > 1 ? 's' : ''} au total',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(.75)),
                        ),
                      ],
                    ),
                  ),
                  // Badge compteur
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.success.withOpacity(.5)),
                    ),
                    child: Text(
                      '$total',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
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

  // ──────────────────────────────────────────────────────────────
  //  BARRE DE RECHERCHE
  // ──────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(
            fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Rechercher par article, marque, EPC...',
          hintStyle: const TextStyle(
              color: AppColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: AppColors.textMuted, size: 20),
          filled: true,
          fillColor: AppColors.bg,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  LISTE
  // ──────────────────────────────────────────────────────────────
  Widget _buildList(List<SseSessionEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final delay = (i * 60).clamp(0, 400);
        return AnimatedBuilder(
          animation: _entranceCtrl,
          builder: (_, child) {
            final t = CurvedAnimation(
              parent: _entranceCtrl,
              curve: Interval(
                (delay / 600).clamp(0, 1),
                ((delay + 300) / 600).clamp(0, 1),
                curve: Curves.easeOutCubic,
              ),
            );
            return FadeTransition(
              opacity: t,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, .1),
                  end: Offset.zero,
                ).animate(t),
                child: child,
              ),
            );
          },
          child: _buildEntryCard(entries[i], i + 1),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  CARTE ENTRÉE
  // ──────────────────────────────────────────────────────────────
  Widget _buildEntryCard(SseSessionEntry entry, int num) {
    final photoUrl =
        'https://digitalapi.monchaussea.com/store-api/api/image/produit/${entry.codeMod}.jpg';
    final heure =
        '${entry.dateHeure.hour.toString().padLeft(2, '0')}:${entry.dateHeure.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header carte : numéro + heure ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '$num',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Puce encodée',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                            color: AppColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(heure,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),

          // ── Contenu ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // Article en haut
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo miniature
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        photoUrl,
                        width: 56, height: 62, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 56, height: 62,
                          decoration: BoxDecoration(
                              color: AppColors.bg,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.image_outlined,
                              size: 24, color: AppColors.textMuted),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: 56, height: 62,
                            decoration: BoxDecoration(
                                color: AppColors.bg,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: AppColors.primary)),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Infos article
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.libArticle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  height: 1.3)),
                          const SizedBox(height: 4),
                          Text(entry.marque,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Wrap(spacing: 5, runSpacing: 4, children: [
                            if (entry.libTaille.isNotEmpty)
                              _SmallChip(entry.libTaille, AppColors.primary),
                            if (entry.libColoris.isNotEmpty)
                              _SmallChip(entry.libColoris, const Color(0xFF7C3AED)),
                          ]),
                        ],
                      ),
                    ),
                    // Prix
                    Text(entry.prixFormate,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.success)),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // EPC encodé
                GestureDetector(
                  onLongPress: () {
                    Clipboard.setData(ClipboardData(text: entry.epc));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('EPC copié !'),
                        backgroundColor: AppColors.primary,
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.success.withOpacity(.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.memory_rounded,
                            color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('EPC encodé',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              Text(entry.epc,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.success,
                                      letterSpacing: .8)),
                            ],
                          ),
                        ),
                        const Icon(Icons.copy_rounded,
                            color: AppColors.success, size: 14),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Gencode
                Row(
                  children: [
                    const Icon(Icons.qr_code_rounded,
                        color: AppColors.textMuted, size: 14),
                    const SizedBox(width: 6),
                    Text('Gencode : ${entry.gencode}',
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                            fontFamily: 'monospace')),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── États vides ──
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle),
            child: const Icon(Icons.nfc_rounded,
                color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 18),
          const Text('Aucun encodage cette session',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('Retournez encoder des puces\npour les voir apparaître ici',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildNoResultState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 14),
          Text('Aucun résultat pour "$_searchQuery"',
              style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  COMPOSANT
// ──────────────────────────────────────────────────────────────
class _SmallChip extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallChip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(.2)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }
}