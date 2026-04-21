import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_provider.dart';
import '../models/tag_model.dart';

// ──────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ──────────────────────────────────────────────────────────────
class _C {
  static const bg            = Color(0xFFDCF4F8);
  static const surface       = Color(0xFFFFFFFF);
  static const primary       = Color(0xFF0070F3);
  static const primaryDark   = Color(0xFF1E40AF);
  static const primarySoft   = Color(0xFFEBF5FF);
  static const success       = Color(0xFF10B981);
  static const warning       = Color(0xFFF59E0B);
  static const error         = Color(0xFFEF4444);
  static const textPrimary   = Color(0xFF111827);
  static const textMuted     = Color(0xFF9CA3AF);
  static const border        = Color(0xFFD1D5DB);
}

// ──────────────────────────────────────────────────────────────
//  ENUM BANQUE MÉMOIRE
// ──────────────────────────────────────────────────────────────
enum MemoryBank { none, epc, tid, user, reserved, tamper }

extension MemoryBankExtension on MemoryBank {
  String get label {
    switch (this) {
      case MemoryBank.none:     return 'None';
      case MemoryBank.epc:      return 'EPC';
      case MemoryBank.tid:      return 'TID';
      case MemoryBank.user:     return 'User';
      case MemoryBank.reserved: return 'Reserved';
      case MemoryBank.tamper:   return 'Tamper';
    }
  }

  Color get color {
    switch (this) {
      case MemoryBank.none:     return _C.textMuted;
      case MemoryBank.epc:      return _C.primary;
      case MemoryBank.tid:      return const Color(0xFF7C3AED);
      case MemoryBank.user:     return const Color(0xFF059669);
      case MemoryBank.reserved: return _C.warning;
      case MemoryBank.tamper:   return _C.error;
    }
  }
}

// ──────────────────────────────────────────────────────────────
//  PAGE DÉTAIL TAGS
// ──────────────────────────────────────────────────────────────
class TagsDetailPage extends ConsumerStatefulWidget {
  const TagsDetailPage({Key? key}) : super(key: key);

  @override
  ConsumerState<TagsDetailPage> createState() => _TagsDetailPageState();
}

class _TagsDetailPageState extends ConsumerState<TagsDetailPage> {
  MemoryBank _selectedBank = MemoryBank.none;

  void _onMemoryBankChanged(MemoryBank bank) {
    setState(() => _selectedBank = bank);
    ref
        .read(inventoryProvider.notifier)
        .configureMemoryBank(bank.label.toUpperCase());
  }

  @override
  Widget build(BuildContext context) {
    final state        = ref.watch(inventoryProvider);
    final filteredTags = state.tags; // filtre extensible ici

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Column(
          children: [
            _buildTopBar(context, state, filteredTags),
            Expanded(child: _buildContent(filteredTags)),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  TOP BAR
  // ────────────────────────────────────────────────────────────
  Widget _buildTopBar(
      BuildContext context,
      InventoryState state,
      List<TagModel> filteredTags,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: _C.surface,
        boxShadow: [
          BoxShadow(
            color: _C.primary.withOpacity(.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _C.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: _C.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DÉTAIL DES TAGS',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: _C.primaryDark,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          '${filteredTags.length} tag(s) · '
                              '${filteredTags.fold(0, (s, t) => s + t.count)} lecture(s)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _C.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Compteurs U / T
                  _buildCounter(
                    label: 'U',
                    value: filteredTags.length,
                    color: _C.primary,
                    tooltip: 'Tags uniques',
                  ),
                  const SizedBox(width: 8),
                  _buildCounter(
                    label: 'T',
                    value: filteredTags.fold(0, (s, t) => s + t.count),
                    color: const Color(0xFF059669),
                    tooltip: 'Total lectures',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Sélecteur de banque mémoire ──
              _buildBankSelector(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounter({
    required String label,
    required int value,
    required Color color,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _C.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.primary.withOpacity(.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<MemoryBank>(
          value: _selectedBank,
          isExpanded: true,
          dropdownColor: _C.surface,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _C.primary),
          items: MemoryBank.values.map((bank) {
            return DropdownMenuItem(
              value: bank,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: bank.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    bank.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _C.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (bank) {
            if (bank != null) _onMemoryBankChanged(bank);
          },
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  CONTENU — liste ou état vide
  // ────────────────────────────────────────────────────────────
  Widget _buildContent(List<TagModel> tags) {
    if (tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _C.primarySoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: _C.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun tag trouvé',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: _C.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lancez un inventaire pour lire des tags',
              style: TextStyle(fontSize: 13, color: _C.textMuted),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildTableHeader(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: tags.length,
            itemBuilder: (_, i) => _buildTagRow(tags[i], i),
          ),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────────
  //  EN-TÊTE TABLEAU
  // ────────────────────────────────────────────────────────────
  Widget _buildTableHeader() {
    final showExtra = _selectedBank != MemoryBank.none;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_C.primaryDark, _C.primary],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: showExtra ? 3 : 5,
            child: const Text(
              'EPC',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
                letterSpacing: .5,
              ),
            ),
          ),
          if (showExtra)
            Expanded(
              flex: 3,
              child: Text(
                _selectedBank.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: .5,
                ),
              ),
            ),
          const SizedBox(
            width: 56,
            child: Text(
              'Count',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(
            width: 68,
            child: Text(
              'RSSI',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────────
  //  LIGNE TAG
  // ────────────────────────────────────────────────────────────
  Widget _buildTagRow(TagModel tag, int index) {
    final isEven    = index % 2 == 0;
    final showExtra = _selectedBank != MemoryBank.none;

    Color rssiColor;
    if (tag.rssi >= -60)      rssiColor = _C.success;
    else if (tag.rssi >= -80) rssiColor = _C.warning;
    else                      rssiColor = _C.error;

    String extraData = '';
    switch (_selectedBank) {
      case MemoryBank.tid:
        extraData = tag.tidData.isNotEmpty ? tag.tidData : '—';
        break;
      case MemoryBank.epc:
      case MemoryBank.user:
      case MemoryBank.reserved:
      case MemoryBank.tamper:
        extraData =
        tag.memoryBankData.isNotEmpty ? tag.memoryBankData : '—';
        break;
      case MemoryBank.none:
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: isEven ? _C.surface : const Color(0xFFF9FAFB),
        border: Border(
          bottom: BorderSide(color: _C.border.withOpacity(.5), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: showExtra ? 3 : 5,
            child: Text(
              tag.epc,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: _C.textPrimary,
                letterSpacing: .4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showExtra)
            Expanded(
              flex: 3,
              child: Text(
                extraData,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: _selectedBank.color,
                  letterSpacing: .4,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          SizedBox(
            width: 56,
            child: Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _C.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${tag.count}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _C.primary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 68,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: rssiColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  tag.rssiDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: rssiColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}