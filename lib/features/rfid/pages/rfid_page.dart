import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/rfid_service.dart';
import '../../article/models/article_model.dart';
import '../../article/providers/article_provider.dart';
import '../providers/rfid_provider.dart';
import '../utils/epc_calculator.dart';

class RfidPage extends ConsumerStatefulWidget {
  const RfidPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RfidPage> createState() => _RfidPageState();
}

class _RfidPageState extends ConsumerState<RfidPage> {
  // ── Scan article (DataWedge → TextField invisible) ──
  final _articleScanController = TextEditingController();
  final _articleFocusNode = FocusNode();
  bool _articleScanMode = false;

  // ── Mode sélectionné ──
  String? _selectedMode;
  static const _modes = ['Écriture puce'];

  // ── EPC résultats ──
  String? _factoryEpc;
  String? _newEpc;
  String? _error;
  String? _message;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rfidState = ref.read(rfidProvider);
      if (rfidState.connectedReader == null &&
          rfidState.availableReaders.isEmpty) {
        ref.read(rfidProvider.notifier).loadAvailableReaders();
      }
      ref.read(rfidProvider.notifier).clearScannedTag();
    });

    _setupMethodChannel();
  }

  void _setupMethodChannel() {
    const MethodChannel('com.example.cap_mobile1/rfid')
        .setMethodCallHandler((call) async {
      if (call.method == 'onScanButton') {
        final articleState = ref.read(articleProvider);

        if (articleState.article == null) {
          _startArticleScan();
        } else {
          _scanAndWrite();
        }
      }
    });
  }
  void _resetRfidState() {
    final notifier = ref.read(rfidProvider.notifier);
    if (ref.read(rfidProvider).connectedReader != null) {
      notifier.disconnectReader();
    }

    setState(() {
      _factoryEpc = null;
      _newEpc = null;
      _error = null;
      _message = null;
      _selectedMode = null;
      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    const MethodChannel('com.example.cap_mobile1/rfid')
        .setMethodCallHandler(null);

    final rfidService = ref.read(rfidServiceProvider);
    rfidService.onScanButtonPressed = null;
    _articleScanController.dispose();
    _articleFocusNode.dispose();
    super.dispose();
  }

  // ─── Scan article ──────────────────────────────────────────────────────────
  void _startArticleScan() {
    setState(() {
      _articleScanMode = true;
      _articleScanController.clear();
      _factoryEpc = null;
      _newEpc = null;
      _error = null;
      _message = null;
    });
    ref.read(articleProvider.notifier).clearArticle();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _articleFocusNode.requestFocus();
    });
  }

  void _onArticleCodeScanned(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    setState(() => _articleScanMode = false);
    ref.read(articleProvider.notifier).fetchArticle(trimmed);
  }

  // ─── Scan puce + écriture EPC ──────────────────────────────────────────────
  Future<void> _scanAndWrite() async {
    final articleState = ref.read(articleProvider);
    final article = articleState.article;
    final rfidState = ref.read(rfidProvider);

    if (article == null) {
      setState(() => _error = 'Scannez d\'abord le code article');
      return;
    }
    if (rfidState.connectedReader == null) {
      setState(() => _error = 'Connectez d\'abord un lecteur RFID');
      return;
    }
    if (_selectedMode == null) {
      setState(() => _error = 'Sélectionnez un mode d\'opération');
      return;
    }
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _error = null;
      _factoryEpc = null;
      _newEpc = null;
      _message = null;
    });

    try {
      // Étape 1 : Lire l'EPC usine
      await ref.read(rfidProvider.notifier).readSingleTag();
      final epc = ref.read(rfidProvider).lastScannedTag;

      if (epc == null || epc.isEmpty) {
        setState(() => _error = 'Aucun tag détecté, réessayez');
        return;
      }

      // Étape 2 : Vérifier que la puce est vierge
      if (!epc.toUpperCase().startsWith('3034')) {
        setState(() {
          _error = 'Cette puce est déjà utilisée !\n'
              'EPC détecté : $epc\n'
              'Veuillez utiliser une puce vierge.';
        });
        return;
      }

      // Étape 3 : Calculer nouvel EPC
      final serial = EpcCalculator.extractSerialFromEpc(epc);
      final newEpc = EpcCalculator.buildEpcFromGtin(article.gtin, serial);

      setState(() {
        _factoryEpc = epc;
        _newEpc = newEpc;
      });

      // Étape 4 : Écrire le nouvel EPC
      await ref.read(rfidProvider.notifier).writeTag(
        tagId: epc,
        data: newEpc,
      );

      setState(() => _message = 'EPC écrit avec succès dans la puce !');
    } catch (e) {
      setState(() => _error = 'Erreur: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final rfidState = ref.watch(rfidProvider);
    final articleState = ref.watch(articleProvider);

    // Écoute des erreurs du provider
    ref.listen<RfidState>(rfidProvider, (_, next) {
      if (next.error != null) {
        setState(() {
          _error = next.error;
          _isProcessing = false;
        });
      }
    });

    // Suppression des doublons (très important pour ton cas)
    final uniqueReaders = rfidState.availableReaders.toSet().toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('RFID - Écriture EPC'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // TextField invisible pour DataWedge
          if (_articleScanMode)
            Positioned(
              top: -100,
              child: SizedBox(
                width: 1,
                height: 1,
                child: TextField(
                  controller: _articleScanController,
                  focusNode: _articleFocusNode,
                  autofocus: true,
                  keyboardType: TextInputType.none,
                  onSubmitted: _onArticleCodeScanned,
                  onChanged: (val) {
                    if (val.endsWith('\n') || val.endsWith('\r')) {
                      _onArticleCodeScanned(val.trim());
                    }
                  },
                ),
              ),
            ),

          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Lecteur RFID
                _sectionTitle('1. Lecteur RFID'),
                const SizedBox(height: 8),
                _buildReaderDropdown(rfidState, uniqueReaders),

                const SizedBox(height: 20),

                // 2. Mode d'opération
                _sectionTitle('2. Mode d\'opération'),
                const SizedBox(height: 8),
                _buildModeDropdown(rfidState),

                const SizedBox(height: 20),

                // 3. Article
                if (_selectedMode != null) ...[
                  _sectionTitle('3. Article'),
                  const SizedBox(height: 8),
                  _buildArticleSection(articleState),
                  const SizedBox(height: 20),
                ],

                // Instruction
                if (!_isProcessing &&
                    _selectedMode != null &&
                    articleState.article != null &&
                    rfidState.connectedReader != null &&
                    _message == null &&
                    _error == null)
                  _buildBanner(
                    color: Colors.blue,
                    icon: Icons.info_outline,
                    text: 'Approchez la puce du lecteur\n'
                        'puis appuyez sur le bouton latéral du TC52',
                  ),

                // En cours
                if (_isProcessing)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: const Column(
                      children: [
                        CircularProgressIndicator(color: Colors.orange),
                        SizedBox(height: 12),
                        Text(
                          'Scan + écriture en cours...',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Résultats EPC
                if (_factoryEpc != null) ...[
                  const SizedBox(height: 16),
                  _buildEpcCard('EPC usine (lu)', _factoryEpc!, Colors.orange),
                  const SizedBox(height: 8),
                  _buildEpcCard('Nouvel EPC (écrit)', _newEpc!, Colors.green),
                ],

                // Erreur
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _buildBanner(
                    color: _error!.contains('déjà utilisée') ? Colors.orange : Colors.red,
                    icon: _error!.contains('déjà utilisée')
                        ? Icons.warning_amber_rounded
                        : Icons.error_outline,
                    text: _error!,
                  ),
                ],

                // Succès
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  _buildBanner(
                    color: Colors.green,
                    icon: Icons.check_circle_outline,
                    text: _message!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Widgets helpers ───────────────────────────────────────────────────────
  Widget _sectionTitle(String title) => Text(
    title,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: Colors.blueGrey,
      letterSpacing: 0.5,
    ),
  );

  Widget _buildReaderDropdown(RfidState rfidState, List<dynamic> uniqueReaders) {
    final connected = rfidState.connectedReader;
    final loading = rfidState.isLoading;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: connected != null ? Colors.green : Colors.grey[300]!,
          width: connected != null ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
        color: connected != null ? Colors.green[50] : Colors.white,
      ),
      child: Row(
        children: [
          Icon(
            connected != null ? Icons.nfc : Icons.nfc_outlined,
            color: connected != null ? Colors.green : Colors.grey,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: loading && connected == null
                ? const Text('Recherche...', style: TextStyle(color: Colors.grey))
                : DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: connected?.name,
                isExpanded: true,
                hint: Text(
                  uniqueReaders.isEmpty
                      ? 'Aucun lecteur détecté'
                      : 'Choisir un lecteur',
                  style: const TextStyle(color: Colors.grey),
                ),
                items: uniqueReaders.map((r) {
                  return DropdownMenuItem<String>(
                    value: r.name,
                    child: Text(r.name),
                  );
                }).toList(),
                onChanged: loading
                    ? null
                    : (name) {
                  if (name == null) return;
                  final reader = uniqueReaders.firstWhere((r) => r.name == name);

                  // Sécurité : déconnecter d'abord si déjà connecté
                  if (rfidState.connectedReader != null) {
                    ref.read(rfidProvider.notifier).disconnectReader();
                  }

                  ref.read(rfidProvider.notifier).connectToReader(reader);
                },
              ),
            ),
          ),
          if (connected != null)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: EdgeInsets.zero,
                minimumSize: const Size(70, 30),
              ),
              onPressed: loading
                  ? null
                  : () => ref.read(rfidProvider.notifier).disconnectReader(),
              child: const Text('Déconnecter'),
            ),
          if (loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Rafraîchir',
            onPressed: loading
                ? null
                : () {
              _resetRfidState();
              ref.read(rfidProvider.notifier).loadAvailableReaders();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeDropdown(RfidState rfidState) {
    final isConnected = rfidState.connectedReader != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedMode != null ? Colors.blue : Colors.grey[300]!,
          width: _selectedMode != null ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
        color: _selectedMode != null ? Colors.blue[50] : Colors.white,
      ),
      child: Row(
        children: [
          Icon(Icons.tune,
              color: _selectedMode != null ? Colors.blue : Colors.grey,
              size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedMode,
                isExpanded: true,
                hint: Text(
                  isConnected
                      ? 'Choisir un mode'
                      : 'Connectez d\'abord un lecteur',
                  style: const TextStyle(color: Colors.grey),
                ),
                items: !isConnected
                    ? []
                    : _modes.map((m) => DropdownMenuItem(
                  value: m,
                  child: Row(
                    children: [
                      const Icon(Icons.edit, size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(m),
                    ],
                  ),
                )).toList(),
                onChanged: isConnected
                    ? (val) => setState(() {
                  _selectedMode = val;
                  _error = null;
                  _message = null;
                })
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleSection(ArticleState articleState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: articleState.isLoading
                  ? Colors.grey[400]
                  : Colors.blue[700],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            icon: articleState.isLoading
                ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.qr_code_scanner, color: Colors.white),
            label: Text(
              articleState.isLoading
                  ? 'Chargement...'
                  : articleState.article != null
                  ? 'Scanner un autre article'
                  : 'Scanner le code article',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            onPressed: articleState.isLoading ? null : _startArticleScan,
          ),
        ),

        if (articleState.error != null) ...[
          const SizedBox(height: 10),
          _buildBanner(
            color: Colors.red,
            icon: Icons.error_outline,
            text: articleState.error!,
          ),
        ],

        if (articleState.article != null) ...[
          const SizedBox(height: 12),
          _buildArticleCard(articleState.article!),
        ],
      ],
    );
  }

  Widget _buildArticleCard(ArticleModel article) {
    final photoUrl =
        'https://digitalapi.monchaussea.com/store-api/image/produit/${article.gencode}.jpg';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                photoUrl,
                width: 80,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: const Icon(Icons.image_outlined,
                      size: 36, color: Colors.grey),
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    width: 80,
                    height: 90,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.libArticle,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.marque,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _badge(article.libTaille, Colors.blue),
                      const SizedBox(width: 8),
                      _badge(article.libColoris, Colors.purple),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article.prixFormate,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'GTIN: ${article.gtin}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
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

  Widget _badge(String label, MaterialColor color) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color[200]!),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color[800],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEpcCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner({
    required Color color,
    required IconData icon,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: color, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}