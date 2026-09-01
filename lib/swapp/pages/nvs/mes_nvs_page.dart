import 'package:cap_mobile/core/apiswap/shared/config/swapp_api_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const _nvsPrimary = Color(0xFF3F46C8);
const _nvsAccent = Color(0xFF6269E8);
const _nvsInk = Color(0xFF182033);
const _nvsMuted = Color(0xFF7B8498);
const _nvsCanvas = Color(0xFFF5F6FC);

enum _NvsAudience { tous, femme, fille, homme, garcon }

extension on _NvsAudience {
  String get label => switch (this) {
    _NvsAudience.tous => 'Tous',
    _NvsAudience.femme => 'Femme',
    _NvsAudience.fille => 'Fille',
    _NvsAudience.homme => 'Homme',
    _NvsAudience.garcon => 'Garçon',
  };

  IconData get icon => switch (this) {
    _NvsAudience.tous => Icons.grid_view_rounded,
    _NvsAudience.femme => Icons.woman_rounded,
    _NvsAudience.fille => Icons.girl_rounded,
    _NvsAudience.homme => Icons.man_rounded,
    _NvsAudience.garcon => Icons.boy_rounded,
  };
}

class _NvsItem {
  const _NvsItem({
    required this.reference,
    required this.name,
    required this.price,
    required this.days,
    required this.lastSale,
    required this.audience,
    required this.color,
    required this.icon,
    this.checked = false,
  });

  final String reference;
  final String name;
  final double price;
  final int days;
  final String lastSale;
  final _NvsAudience audience;
  final Color color;
  final IconData icon;
  final bool checked;
}

class MesNvsPage extends StatefulWidget {
  const MesNvsPage({super.key});

  static Route<void> fadeRoute() => PageRouteBuilder(
    pageBuilder: (_, animation, _) => const MesNvsPage(),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 280),
  );

  @override
  State<MesNvsPage> createState() => _MesNvsPageState();
}

class _MesNvsPageState extends State<MesNvsPage> {
  _NvsAudience _audience = _NvsAudience.femme;
  String _query = '';
  bool _ascending = false;
  bool _showSearch = false;

  static const _items = [
    _NvsItem(
      reference: '56610171',
      name: 'Sneakers blanc cassé',
      price: 44.99,
      days: 10,
      lastSale: '04/08/2026',
      audience: _NvsAudience.femme,
      color: Color(0xFFE9E5DC),
      icon: Icons.directions_walk_rounded,
      checked: true,
    ),
    _NvsItem(
      reference: '56331005',
      name: 'Casual kaki',
      price: 24.99,
      days: 7,
      lastSale: '04/08/2026',
      audience: _NvsAudience.garcon,
      color: Color(0xFFC9B08A),
      icon: Icons.hiking_rounded,
    ),
    _NvsItem(
      reference: '56620356',
      name: 'Running gris',
      price: 49.99,
      days: 16,
      lastSale: '25/08/2026',
      audience: _NvsAudience.homme,
      color: Color(0xFFADB5C2),
      icon: Icons.directions_run_rounded,
      checked: true,
    ),
    _NvsItem(
      reference: '56610071',
      name: 'Sneakers marron rose',
      price: 44.99,
      days: 12,
      lastSale: '18/08/2026',
      audience: _NvsAudience.fille,
      color: Color(0xFFC69289),
      icon: Icons.roller_skating_rounded,
    ),
    _NvsItem(
      reference: '56542109',
      name: 'Basket urbaine marine',
      price: 39.99,
      days: 12,
      lastSale: '13/08/2026',
      audience: _NvsAudience.homme,
      color: Color(0xFF66738E),
      icon: Icons.directions_walk_rounded,
    ),
    _NvsItem(
      reference: '56488112',
      name: 'Tennis pastel',
      price: 34.99,
      days: 10,
      lastSale: '11/08/2026',
      audience: _NvsAudience.fille,
      color: Color(0xFFDCAFC4),
      icon: Icons.ice_skating_rounded,
      checked: true,
    ),
    _NvsItem(
      reference: '56114788',
      name: 'Derby cognac',
      price: 59.99,
      days: 18,
      lastSale: '09/08/2026',
      audience: _NvsAudience.homme,
      color: Color(0xFFA36F4D),
      icon: Icons.hiking_rounded,
    ),
    _NvsItem(
      reference: '56990127',
      name: 'Running lavande',
      price: 54.99,
      days: 8,
      lastSale: '20/08/2026',
      audience: _NvsAudience.femme,
      color: Color(0xFFAAA0D8),
      icon: Icons.directions_run_rounded,
    ),
  ];

  List<_NvsItem> get _visibleItems {
    final normalized = _query.trim().toLowerCase();
    final values = _items.where((item) {
      final audienceMatches =
          _audience == _NvsAudience.tous || item.audience == _audience;
      final queryMatches =
          normalized.isEmpty ||
          item.name.toLowerCase().contains(normalized) ||
          item.reference.contains(normalized);
      return audienceMatches && queryMatches;
    }).toList();
    values.sort(
      (a, b) => _ascending
          ? a.reference.compareTo(b.reference)
          : b.reference.compareTo(a.reference),
    );
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final items = _visibleItems;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _nvsCanvas,
        body: Column(
          children: [
            _buildTopSection(context),
            _buildTools(items.length),
            Expanded(
              child: items.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 28),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: .72,
                          ),
                      itemCount: items.length,
                      itemBuilder: (_, index) => _NvsCard(
                        item: items[index],
                        onTap: () => _showItem(items[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return SizedBox(
      height: top + 154,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: top + 126,
            padding: EdgeInsets.fromLTRB(12, top + 12, 14, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF202783), _nvsPrimary, _nvsAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                _NvsHeaderButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Non ventes suspectes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.3,
                    ),
                  ),
                ),
                _NvsHeaderButton(
                  icon: _showSearch ? Icons.close_rounded : Icons.search_rounded,
                  onTap: () => setState(() => _showSearch = !_showSearch),
                ),
              ],
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 0,
            child: _buildAudienceSelector(),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceSelector() {
    const audiences = [
      _NvsAudience.femme,
      _NvsAudience.fille,
      _NvsAudience.homme,
      _NvsAudience.garcon,
    ];
    return Container(
      height: 76,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x20182055),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: audiences.map((value) {
        final selected = value == _audience;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _audience = value);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  gradient: selected
                      ? const LinearGradient(
                          colors: [_nvsPrimary, _nvsAccent],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x454640D6),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      value.icon,
                      color: selected ? Colors.white : _nvsInk,
                      size: 23,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value.label,
                      maxLines: 1,
                      style: TextStyle(
                        color: selected ? Colors.white : _nvsInk,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        }).toList(),
      ),
    );
  }

  Widget _buildTools(int count) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
    child: Column(
      children: [
        if (_showSearch) ...[
          TextField(
            autofocus: true,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Rechercher une référence…',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: _NvsToolCard(
                icon: Icons.swap_vert_rounded,
                label: 'Par réf',
                onTap: () => setState(() => _ascending = !_ascending),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NvsToolCard(
                icon: Icons.calendar_month_rounded,
                label: 'réf(s) NVS',
                emphasizedValue: '$count',
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _buildEmptyState() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.search_off_rounded, size: 64, color: _nvsMuted),
        SizedBox(height: 12),
        Text(
          'Aucune référence trouvée',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        SizedBox(height: 4),
        Text(
          'Modifiez votre recherche ou vos filtres.',
          style: TextStyle(color: _nvsMuted),
        ),
      ],
    ),
  );

  void _showItem(_NvsItem item) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: .25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(item.icon, color: item.color, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Réf. ${item.reference}',
                        style: const TextStyle(color: _nvsMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailLine(label: 'Univers', value: item.audience.label),
            _DetailLine(label: 'Dernière vente', value: item.lastSale),
            _DetailLine(
              label: 'Sans vente depuis',
              value: '${item.days} jours',
            ),
            _DetailLine(
              label: 'Prix',
              value: '${item.price.toStringAsFixed(2).replaceAll('.', ',')} €',
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _nvsPrimary,
                padding: const EdgeInsets.all(15),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text('Référence marquée comme vérifiée.'),
                  ),
                );
              },
              icon: const Icon(Icons.task_alt_rounded),
              label: const Text('Marquer comme vérifiée'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _NvsHeaderButton extends StatelessWidget {
  const _NvsHeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .14),
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: Colors.white, size: 25),
      ),
    ),
  );
}

class _NvsToolCard extends StatelessWidget {
  const _NvsToolCard({
    required this.icon,
    required this.label,
    this.emphasizedValue,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? emphasizedValue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 62,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12182055),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            if (emphasizedValue != null) ...[
              Text(
                emphasizedValue!,
                style: const TextStyle(
                  color: _nvsPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 7),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _nvsInk,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(icon, color: _nvsPrimary, size: 23),
          ],
        ),
      ),
    ),
  );
}

class _NvsCard extends StatelessWidget {
  const _NvsCard({required this.item, required this.onTap});
  final _NvsItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE6E9F1)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F1F2A55),
              blurRadius: 15,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          item.color.withValues(alpha: .10),
                          item.color.withValues(alpha: .28),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(19),
                      ),
                    ),
                    child: Image.network(
                      SwappApiConstants.productPhotoUrl(item.reference),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        item.icon,
                        size: 76,
                        color: item.color.withValues(alpha: .9),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 9,
                    right: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item.days} j',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  if (item.checked)
                    Positioned(
                      top: 9,
                      left: 9,
                      child: Container(
                        width: 31,
                        height: 31,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x22182055),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.thumb_up_alt_rounded,
                          size: 19,
                          color: _nvsPrimary,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 9,
                    bottom: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8E9FF),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            size: 13,
                            color: _nvsPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.lastSale,
                            style: const TextStyle(
                              color: _nvsPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _nvsInk,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Réf. ${item.reference}',
                    style: const TextStyle(color: _nvsMuted, fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item.price.toStringAsFixed(2).replaceAll('.', ',')} €',
                          style: const TextStyle(
                            color: _nvsPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: _nvsPrimary,
                        size: 20,
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
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: _nvsMuted)),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}
