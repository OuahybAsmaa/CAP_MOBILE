import 'package:cap_mobile/features/article/providers/article_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rfid_provider.dart';
import '../utils/epc_calculator.dart';
import 'package:flutter/services.dart';
import '../../article/models/article_model.dart';

class EpcWritePage extends ConsumerStatefulWidget {
  const EpcWritePage({Key? key}) : super(key: key);

  @override
  ConsumerState<EpcWritePage> createState() => _EpcWritePageState();
}

class _EpcWritePageState extends ConsumerState<EpcWritePage> {
  final _sg1Controller = TextEditingController();

  String? _factoryEpc;
  String? _newEpc;
  String? _error;
  String? _message;
  bool _isProcessing = false; // scan + écriture en un seul état

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rfidProvider.notifier).clearScannedTag();
    });
    final rfidService = ref.read(rfidServiceProvider);
    rfidService.onScanButtonPressed = () {
      scanAndWrite();
    };
  }

  @override
  Widget build(BuildContext context) {
    final rfidState   = ref.watch(rfidProvider);
    final isConnected = rfidState.connectedReader != null;

    ref.listen<RfidState>(rfidProvider, (previous, next) {
      if (next.error != null && next.error != previous?.error) {
        setState(() {
          _error        = next.error;
          _isProcessing = false;
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Écriture EPC'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Statut connexion ──
            _buildConnectionStatus(rfidState),
            const SizedBox(height: 20),

            // ── Saisie SG1 ──
            TextField(
              controller: _sg1Controller,
              keyboardType: TextInputType.number,
              maxLength: 6,
              enabled: isConnected && !_isProcessing,
              decoration: const InputDecoration(
                labelText: 'Code SG1 (6 chiffres)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
                counterText: '',
                hintText: 'ex: 123456',
              ),
              onChanged: (_) {
                setState(() {
                  _factoryEpc = null;
                  _newEpc     = null;
                  _message    = null;
                  _error      = null;
                });
              },
            ),
            const SizedBox(height: 20),

            // ── Instruction ──
            if (isConnected && !_isProcessing && _message == null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Approchez la puce du lecteur\npuis appuyez sur le bouton latéral du TC52',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── En cours ──
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
                    SizedBox(height: 14),
                    Text(
                      'Scan + écriture en cours...',
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // ── Résultats EPC ──
            if (_factoryEpc != null) ...[
              _buildEpcCard('EPC Usine (lu)', _factoryEpc!, Colors.orange),
              const SizedBox(height: 10),
              _buildEpcCard('Nouvel EPC (écrit)', _newEpc!, Colors.green),
              const SizedBox(height: 20),
            ],

            // ── Erreur ──
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _error!.contains('déjà utilisée')
                      ? Colors.orange[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _error!.contains('déjà utilisée')
                        ? Colors.orange[300]!
                        : Colors.red[200]!,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _error!.contains('déjà utilisée')
                          ? Icons.warning_amber_rounded
                          : Icons.error_outline,
                      color: _error!.contains('déjà utilisée')
                          ? Colors.orange
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: _error!.contains('déjà utilisée')
                              ? Colors.orange[800]
                              : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Message succès ──
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _message!,
                        style: const TextStyle(color: Colors.green),
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

  Future<void> scanAndWrite() async {
    final sg1 = _sg1Controller.text.trim();
    final gtin = '03617580797830';

    if (sg1.isEmpty || sg1.length != 6) {
      setState(() => _error = 'Saisissez d\'abord un code SG1 de 6 chiffres');
      return;
    }

    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _error        = null;
      _factoryEpc   = null;
      _newEpc       = null;
      _message      = null;
    });

    try {
      // ── Étape 1 : Scan ──
      await ref.read(rfidProvider.notifier).readSingleTag();
      final epc = ref.read(rfidProvider).lastScannedTag;

      if (epc == null || epc.isEmpty) {
        setState(() => _error = 'Aucun tag détecté, réessayez');
        return;
      }

      // ── Étape 2 : Vérifier puce vierge ──
      if (!epc.toUpperCase().startsWith('3034')) {
        setState(() {
          _error = '⚠️ Cette puce est déjà utilisée !\n'
              'EPC détecté : $epc\n'
              'Veuillez utiliser une puce vierge.';
        });
        return;
      }

      // ── Étape 3 : Calculer nouvel EPC ──
      final serial = EpcCalculator.extractSerialFromEpc(epc);
      //final newEpc = EpcCalculator.buildEpc(sg1, serial);
      //icic juste a bricolage
      final newEpc = EpcCalculator.buildEpcFromGtin(gtin, serial);

      setState(() {
        _factoryEpc = epc;
        _newEpc     = newEpc;
      });

      // ── Étape 4 : Écrire automatiquement ──
      await ref.read(rfidProvider.notifier).writeTag(
        tagId: epc,
        data:  newEpc,
      );

      setState(() => _message = '✅ EPC écrit avec succès dans la puce !');

    } catch (e) {
      setState(() => _error = 'Erreur: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Widget _buildConnectionStatus(RfidState rfidState) {
    final isConnected = rfidState.connectedReader != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected ? Colors.green[200]! : Colors.red[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.nfc : Icons.nfc_outlined,
            color: isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isConnected
                  ? '✅ ${rfidState.connectedReader!.name}'
                  : '❌ Aucun lecteur connecté',
              style: TextStyle(
                color: isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpcCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    final rfidService = ref.read(rfidServiceProvider);
    rfidService.onScanButtonPressed = null;
    _sg1Controller.dispose();
    super.dispose();
  }
}