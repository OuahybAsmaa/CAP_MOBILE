import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/inventory_service.dart';
import 'rfid_constants.dart';

class RfidTagFinderSheet extends ConsumerStatefulWidget {
  final String epc;
  final InventoryService service;

  const RfidTagFinderSheet({
    super.key,
    required this.epc,
    required this.service,
  });

  @override
  ConsumerState<RfidTagFinderSheet> createState() => _RfidTagFinderSheetState();
}

class _RfidTagFinderSheetState extends ConsumerState<RfidTagFinderSheet>
    with TickerProviderStateMixin {

  // ── RSSI → proximité ──
  // RSSI typique Zebra : -90 (très loin) à -30 (collé)
  static const double _rssiMin = -90.0;
  static const double _rssiMax = -30.0;

  double _rssi        = _rssiMin;
  double _proximity   = 0.0;
  bool   _isSearching = false;
  bool   _found       = false;

  StreamSubscription? _sub;

  late final AnimationController _pulseCtrl;
  late final AnimationController _radarCtrl;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _radarCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _startFinding();
  }

  @override
  void dispose() {
    _stopFinding();
    _pulseCtrl.dispose();
    _radarCtrl.dispose();
    super.dispose();
  }

  // ── Démarrer ──
  Future<void> _startFinding() async {
    setState(() => _isSearching = true);

    // Écoute du stream
    _sub = widget.service.tagStream.listen((event) {
      if (event is Map && event['event'] == 'tagFinding') {
        final rssi = (event['rssi'] as num).toDouble();
        _onRssiReceived(rssi);
      }
    });

    try {
      await widget.service.startTagFinding(widget.epc);
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  // ── Arrêter ──
  Future<void> _stopFinding() async {
    _sub?.cancel();
    _sub = null;
    try { await widget.service.stopTagFinding(); } catch (_) {}
  }

  // ── Traitement RSSI ──
  void _onRssiReceived(double rssi) {
    if (!mounted) return;

    final proximity = ((rssi - _rssiMin) / (_rssiMax - _rssiMin)).clamp(0.0, 1.0);
    final found     = rssi > -50.0;

    setState(() {
      _rssi      = rssi;
      _proximity = proximity;
      _found     = found;
    });

    // Vitesse du pulse selon proximité
    final pulseDuration = Duration(
      milliseconds: (800 - (proximity * 600)).round().clamp(200, 800),
    );
    if (_pulseCtrl.duration != pulseDuration) {
      _pulseCtrl.duration = pulseDuration;
    }
    if (!_pulseCtrl.isAnimating) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  // ── Couleur selon proximité ──
  Color get _proximityColor {
    if (_proximity < 0.3) return AppColors.error;
    if (_proximity < 0.6) return const Color(0xFFF59E0B);
    return AppColors.success;
  }

  String get _proximityLabel {
    if (_proximity < 0.2) return 'Très loin';
    if (_proximity < 0.4) return 'Loin';
    if (_proximity < 0.6) return 'Proche';
    if (_proximity < 0.8) return 'Très proche';
    return '🎯 Trouvé !';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_proximity * 100).round();

    return Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          // Barre de glissement
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Titre
          Row(
            children: [
              const Icon(Icons.radar_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text('Localisation de la puce',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  await _stopFinding();
                  if (mounted) Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.close_rounded,
                      size: 16, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // EPC
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.epc,
              style: const TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // ── Radar visuel ──
          SizedBox(
            width: 200, height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Cercles de radar animés
                AnimatedBuilder(
                  animation: _radarCtrl,
                  builder: (_, _) => CustomPaint(
                    size: const Size(200, 200),
                    painter: _RadarPainter(
                      progress:   _radarCtrl.value,
                      color:      _proximityColor,
                      proximity:  _proximity,
                    ),
                  ),
                ),

                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, _) {
                    final scale = 1.0 + _pulseCtrl.value * 0.08 * _proximity;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          color: _proximityColor.withValues(alpha: .15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _proximityColor,
                            width: 2.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$pct%',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: _proximityColor,
                              ),
                            ),
                            Text(
                              '${_rssi.toStringAsFixed(0)} dBm',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Label proximité
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              _proximityLabel,
              key: ValueKey(_proximityLabel),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _proximityColor,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 8,
              child: LinearProgressIndicator(
                value: _proximity,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(_proximityColor),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.directions_walk_rounded,
                    color: AppColors.primary, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Déplacez-vous lentement — le % augmente quand vous approchez de la puce',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
     ),
    );
  }
}

// ── Painter radar ──
class _RadarPainter extends CustomPainter {
  final double progress;
  final Color  color;
  final double proximity;

  const _RadarPainter({
    required this.progress,
    required this.color,
    required this.proximity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR   = size.width / 2;

    // Cercles statiques de fond
    for (int i = 1; i <= 3; i++) {
      final r = maxR * i / 3;
      canvas.drawCircle(
        center, r,
        Paint()
          ..color  = color.withValues(alpha: .08)
          ..style  = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Onde radar animée
    final waveR = maxR * progress;
    canvas.drawCircle(
      center, waveR,
      Paint()
        ..color  = color.withValues(alpha: (1 - progress) * 0.4)
        ..style  = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Secteur radar (sweep)
    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxR * 0.85),
      -pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color  = color.withValues(alpha: .25)
        ..style  = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.progress != progress || old.proximity != proximity;
}