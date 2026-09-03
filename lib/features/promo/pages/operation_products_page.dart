import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/promo_provider.dart';
import '../models/promo_model.dart';
import '../../../core/services/article_service.dart';
import 'package:cap_mobile/core/l10n/app_localizations_scope.dart';

class OperationProductsPage extends ConsumerStatefulWidget {
  final int codePromo;
  final String libPromo;

  const OperationProductsPage({
    Key? key,
    required this.codePromo,
    required this.libPromo,
  }) : super(key: key);

  @override
  ConsumerState<OperationProductsPage> createState() => _OperationProductsPageState();
}

class _OperationProductsPageState extends ConsumerState<OperationProductsPage> {

  static const _indigo     = Color(0xFF3949AB);
  static const _indigoDark = Color(0xFF1A237E);
  static const _green      = Color(0xFF2E7D32);
  static const _amber      = Color(0xFFF59E0B);

  bool _onlyNouveaute = false;

  @override
  Widget build(BuildContext context) {
    final modelesAsync = ref.watch(operationModelesProvider(widget.codePromo));

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: Column(
        children: [
          _buildHeader(context, modelesAsync),
          _buildFilterBar(),
          _buildColumnHeaders(),
          Expanded(
            child: modelesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: _indigo),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 48, color: Color(0xFFD32F2F)),
                      const SizedBox(height: 16),
                      Text(e.toString().replaceFirst('Exception: ', ''),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFD32F2F))),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.refresh(operationModelesProvider(widget.codePromo)),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(context.f.promoRetry),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _indigo, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              data: (modeles) {
                final filtered = _onlyNouveaute
                    ? modeles.where((m) => m.nouveaute).toList()
                    : modeles;

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      _onlyNouveaute
                          ? context.f.operationNoNouveaute
                          : context.f.operationNoArticle,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) => _buildProductRow(filtered[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AsyncValue<List<ModeleProduit>> modelesAsync) {
    final refs = modelesAsync.maybeWhen(data: (m) => m.length, orElse: () => 0);
    final articles = modelesAsync.maybeWhen(
      data: (m) => m.fold<int>(0, (sum, e) => sum + e.stock),
      orElse: () => 0,
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_indigoDark, _indigo],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
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
              Expanded(
                child: Text(widget.libPromo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w900,
                        color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$refs refs · $articles art.',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.fiber_new_rounded, size: 20, color: _amber),
          const SizedBox(width: 8),
          Text(context.f.operationFilterNouveautes,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const Spacer(),
          Switch(
            value: _onlyNouveaute,
            activeColor: _amber,
            onChanged: (v) => setState(() => _onlyNouveaute = v),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnHeaders() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(context.f.operationColArticle,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey)),
          ),
          SizedBox(
            width: 48,
            child: Text(context.f.operationColPvIni, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey[700])),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 48,
            child: Text(context.f.operationColPromo, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _green)),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 48,
            child: Text(context.f.operationColStock, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  Widget _buildProductRow(ModeleProduit m) {
    final photoUrl = ref.read(articleServiceProvider).getPhotoUrl(m.codeMod);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Photo ronde
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: m.nouveaute ? _amber : Colors.grey.shade300,
                width: m.nouveaute ? 2 : 1,
              ),
            ),
            child: ClipOval(
              child: Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.image_not_supported_rounded,
                  color: Colors.grey[350], size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Code modèle + badge nouveauté
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.codeMod,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                if (m.nouveaute) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _amber.withOpacity(.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: _amber.withOpacity(.4)),
                    ),
                    child: Text(context.f.operationNouveaute,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: _amber)),
                  ),
                ],
              ],
            ),
          ),

          // 3 badges ronds : PV Ini / Promo / Stock
          _priceBadge('${m.pvInitial.toStringAsFixed(0)}€', Colors.black, strikethrough: true),
          const SizedBox(width: 6),
          _priceBadge('${m.pvPromo.toStringAsFixed(0)}€', _green),
          const SizedBox(width: 6),
          _priceBadge('${m.stock}', Colors.grey.shade400, textColor: Colors.black87),
        ],
      ),
    );
  }

  Widget _priceBadge(String text, Color bgColor, {bool strikethrough = false, Color textColor = Colors.white}) {
    return Container(
      width: 48, height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor,
          decoration: strikethrough ? TextDecoration.lineThrough : null,
        ),
      ),
    );
  }
}