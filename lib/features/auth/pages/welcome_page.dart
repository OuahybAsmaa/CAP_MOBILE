import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';
import '../../home/pages/home_page.dart';

class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  final _scanController = TextEditingController();
  final _scanFocusNode = FocusNode();
  bool _scanMode = false;

  String _scanBuffer = '';

  @override
  void initState() {
    super.initState();
    _setupMethodChannel();
  }

  void _setupMethodChannel() {
    const MethodChannel('com.example.cap_mobile1/rfid')
        .setMethodCallHandler((call) async {
      if (call.method == 'onScanButton') {
        if (!_scanMode && !ref.read(authProvider).isLoading) {
          _startScan();
        }
      }
    });
  }

  void _startScan() {
    setState(() {
      _scanMode = true;
      _scanBuffer = '';
      _scanController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scanFocusNode.requestFocus();
    });
  }

  void _onCodeScanned(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return;

    setState(() => _scanMode = false);
    ref.read(authProvider.notifier).authenticate(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && !(previous?.isAuthenticated ?? false)) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // ─── TextField invisible pour DataWedge ─────────────────────────
            if (_scanMode)
              Positioned(
                top: -100,
                child: SizedBox(
                  width: 1,
                  height: 1,
                  child: TextField(
                    controller: _scanController,
                    focusNode: _scanFocusNode,
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    onChanged: (value) {
                      if (value.contains('\n') || value.contains('\r')) {
                        _onCodeScanned(value);
                      } else {
                        _scanBuffer = value;
                        _checkScanComplete();
                      }
                    },
                    onSubmitted: _onCodeScanned,
                    style: const TextStyle(color: Colors.transparent),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.transparent),
                    ),
                  ),
                ),
              ),

            // ─── Contenu principal ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.nfc,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Titre
                  const Text(
                    'CapMobile',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Gestion RFID & Étiquetage',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[500],
                      letterSpacing: 1,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Instructions scan ──
                  if (_scanMode && !authState.isLoading)
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.qr_code_scanner,
                              size: 40, color: Colors.blue),
                          SizedBox(height: 12),
                          Text(
                            'Scannez votre badge collaborateur',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Pointez le scanner vers votre code-barres',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Chargement ──
                  if (authState.isLoading)
                    Container(
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22, height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(width: 14),
                          Text(
                            'Authentification en cours...',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Erreur ──
                  if (authState.error != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              authState.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Bouton Authentifier ──
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: authState.isLoading
                            ? Colors.grey[400]
                            : Colors.blue[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 4,
                      ),
                      icon: authState.isLoading
                          ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.qr_code_scanner,
                          color: Colors.white),
                      label: Text(
                        authState.isLoading
                            ? 'Authentification...'
                            : 'Authentifier',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: authState.isLoading ? null : _startScan,
                    ),
                  ),

                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Timer? _scanTimer;

  void _checkScanComplete() {
    _scanTimer?.cancel();
    _scanTimer = Timer(const Duration(milliseconds: 200), () {
      if (_scanBuffer.isNotEmpty) {
        _onCodeScanned(_scanBuffer);
      }
    });
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _scanController.dispose();
    _scanFocusNode.dispose();
    super.dispose();
  }
}