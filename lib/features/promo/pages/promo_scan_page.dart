import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/promo_provider.dart';
import '../models/promo_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/rfid/providers/rfid_provider.dart';
import '../../../core/services/datawedge_service.dart';

class PromoScanPage extends ConsumerStatefulWidget {
  const PromoScanPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PromoScanPage> createState() => _PromoScanPageState();
}

class _PromoScanPageState extends ConsumerState<PromoScanPage>
    with SingleTickerProviderStateMixin {

  static const _indigo     = Color(0xFF3949AB);
  static const _indigoDark = Color(0xFF1A237E);
  static const _green      = Color(0xFF2E7D32);
  static const _greenLight = Color(0xFFE8F5E9);
  static const _red        = Color(0xFFD32F2F);
  static const _redLight   = Color(0xFFFFEBEB);

  static const _nativeChannel =
  MethodChannel('com.example.cap_mobile1/rfid');

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(promoProvider.notifier).resetScan();
    });

    _initDataWedge();
  }

  void _initDataWedge() async {
    await ref.read(dataWedgeServiceProvider).initialize();
    if (!mounted) return;

    _nativeChannel.setMethodCallHandler((call) async {
      if (call.method == 'onEmdkScan') {
        final data = call.arguments as String;
        if (!mounted) return;
        final state = ref.read(promoProvider);
        if (!state.isLoadingPromo) {
          ref.read(promoProvider.notifier).verifierGencode(data.trim());
        }
      }
    });

    try {
      await _nativeChannel.invokeMethod('startEmdkScan');
    } catch (e) {
      debugPrint('Erreur demarrage EMDK: $e');
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _nativeChannel.invokeMethod('stopEmdkScan').catchError((e) {
      debugPrint('Erreur arret EMDK: $e');
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(promoProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xFFF0F2FF),
        body: Column(
          children: [
            _buildHeader(state),
            Expanded(child: _buildBody(state)),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────

  Widget _buildHeader(PromoState state) {
    return Container(
      width: double.infinity,
      color: _indigoDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  ref.read(promoProvider.notifier).resetScan();
                  Navigator.pop(context);
                },
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
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Consulter Tarif',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Scanner un article',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              _buildReaderButton(),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showKeyboardInput,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.keyboard_alt_outlined,
                      color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showKeyboardInput() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Saisir le gencode',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
        content: SingleChildScrollView(          // <-- ajoute ce wrapper
          child: Column(
            mainAxisSize: MainAxisSize.min,        // <-- ajoute
            children: [
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Ex: 34544068037110',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submitKeyboardGencode(controller.text),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _submitKeyboardGencode(controller.text),
            style: ElevatedButton.styleFrom(
                backgroundColor: _indigo, foregroundColor: Colors.white),
            child: const Text('Vérifier'),
          ),
        ],
      ),
    );
  }

  void _submitKeyboardGencode(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    Navigator.pop(context); // ferme le dialog
    ref.read(promoProvider.notifier).verifierGencode(trimmed);
  }

  Widget _buildReaderButton() {
    final rfidState     = ref.watch(rfidProvider);
    final uniqueReaders = rfidState.availableReaders.toSet().toList();
    final connected     = rfidState.connectedReader;

    return GestureDetector(
      onTap: rfidState.isLoading
          ? null
          : () => _showReaderPicker(connected, rfidState, uniqueReaders),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: connected != null
              ? Colors.green.withOpacity(.2)
              : Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: connected != null
                ? Colors.greenAccent.withOpacity(.6)
                : Colors.white.withOpacity(.3),
          ),
        ),
        child: rfidState.isLoading && connected == null
            ? const SizedBox(
          width: 12, height: 12,
          child: CircularProgressIndicator(
              strokeWidth: 1.5, color: Colors.white),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: connected != null
                    ? Colors.greenAccent
                    : Colors.white38,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              connected != null ? 'Connected' : 'Disconnected',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: connected != null
                    ? Colors.greenAccent
                    : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReaderPicker(connected, RfidState rfidState, List uniqueReaders) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.all(16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'RFID Reader',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(rfidProvider.notifier).loadAvailableReaders();
                  },
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EAF6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: Color(0xFF3949AB), size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (uniqueReaders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('No reader available',
                    style: TextStyle(
                        color: Colors.grey, fontSize: 11)),
              )
            else
              ...uniqueReaders.map((r) {
                final isSelected = connected?.name == r.name;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    if (isSelected) {
                      ref.read(rfidProvider.notifier).disconnectReader();
                    } else {
                      if (connected != null) {
                        ref.read(rfidProvider.notifier).disconnectReader();
                      }
                      ref.read(rfidProvider.notifier).connectToReader(r);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2E7D32).withOpacity(.06)
                          : const Color(0xFFF4F4F4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFE0E0E0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.nfc_rounded,
                            color: isSelected
                                ? const Color(0xFF2E7D32)
                                : Colors.grey,
                            size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(r.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFF1A1A2E),
                              )),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: Color(0xFF2E7D32), size: 16),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────

  Widget _buildBody(PromoState state) {
    if (state.isLoadingPromo) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _indigo),
            SizedBox(height: 16),
            Text('Vérification en cours...',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
          ],
        ),
      );
    }

    if (state.hasResults) {
      return _buildResults(state);
    }

    return _buildScanWaiting();
  }

  // ── Attente scan ──────────────────────────────────────────

  Widget _buildScanWaiting() {
    final isConnected = ref.watch(rfidProvider).connectedReader != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseCtrl,
              builder: (_, __) => Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  color: _indigo.withOpacity(.08 + .04 * _pulseCtrl.value),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _indigo.withOpacity(.2 + .1 * _pulseCtrl.value),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.qr_code_scanner_rounded,
                    size: 40, color: _indigo),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Scanner un article',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(
              'Pointez le scanner vers le code-barres\nde l\'article à vérifier',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[600], height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ── Résultats ─────────────────────────────────────────────

  Widget _buildResults(PromoState state) {
    final results = state.promoResults!;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildArticlePhoto(state),
          ...results.map((r) => _buildResultCard(r)),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ref.read(promoProvider.notifier).resetScan(),
                icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                label: const Text('Scanner un autre article',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticlePhoto(PromoState state) {
    final article = state.article;
    final photoUrl = article != null
        ? ref.read(articleServiceProvider).getPhotoUrl(article.codeMod)
        : null;

    return Center(
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _indigo.withOpacity(.25), width: 2),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: photoUrl != null
              ? Image.network(
            photoUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.image_not_supported_rounded,
              color: Colors.grey[400],
              size: 32,
            ),
          )
              : Icon(
            Icons.inventory_2_rounded,
            color: Colors.grey[350],
            size: 36,
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(PromoResult result) {
    final isEnPromo = result.isEnPromo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          Text(
            result.libPromo,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    if (isEnPromo)
                      Text(
                        '${result.pvInitial.toStringAsFixed(2)}€',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFAED581),
                          decoration: TextDecoration.lineThrough,
                          decorationThickness: 2.2,
                          decorationColor: Color(0xFFAED581),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      '${(isEnPromo ? result.pvPromo : result.pvInitial).toStringAsFixed(2)}€',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: isEnPromo ? _red : const Color(0xFF1A1A2E),
                      ),
                    ),
                  ],
                ),
              ),
              if (isEnPromo)
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: ShapeDecoration(
                          color: _red,
                          shape: StarBorder(
                            points: 14,
                            innerRadiusRatio: 0.85,
                            pointRounding: 0.3,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '- ${result.percentPromo}%',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        color: const Color(0xFFFFF176),
                        child: const Text(
                          'EN POURCENTAGE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}