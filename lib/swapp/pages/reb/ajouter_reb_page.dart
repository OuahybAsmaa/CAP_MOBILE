// =============================================================================
// CapMobile — Module Swapp — Nouvelle remise en banque
// -----------------------------------------------------------------------------
// Formulaire guidé calqué sur la maquette HTML/CSS :
//   bandeau indigo (agent + date + total) · encaissements sélectionnables ·
//   preuve photo/fichier · signature · observations · CTA de validation.
// Architecture : état via rebProvider ; données démo isolées dans le service.
// =============================================================================

import 'dart:io';

import 'package:cap_mobile/core/apiswap/reb/providers/reb_provider.dart';
import 'package:cap_mobile/core/apiswap/shared/config/swapp_api_constants.dart';
import 'package:cap_mobile/core/widgets/photo_annotation_editor.dart';
import 'package:cap_mobile/features/auth/providers/auth_provider.dart';
import 'package:cap_mobile/swapp/models/reb/reb.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

// Palette issue de la maquette HTML.
const _bg = Color(0xFFEFF0F8);
const _ink = Color(0xFF181B2A);
const _inkSoft = Color(0xFF9094AA);
const _card = Color(0xFFFFFFFF);
const _indigo = Color(0xFF2B2F8F);
const _indigoDeep = Color(0xFF14173F);
const _indigoTint = Color(0xFFEEEEFC);
const _green = Color(0xFF16B978);
const _greenTint = Color(0xFFE4F9EF);
const _amber = Color(0xFFEE9A0F);
const _amberTint = Color(0xFFFDF0D6);
const _slate = Color(0xFF767C97);
const _slateTint = Color(0xFFEEEFF6);
const _grayBorder = Color(0xFFE9EAF2);

class AjouterRebPage extends ConsumerStatefulWidget {
  const AjouterRebPage({super.key});

  static Route<RebItem?> fadeRoute() => PageRouteBuilder<RebItem?>(
    pageBuilder: (_, _, _) => const AjouterRebPage(),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 300),
  );

  @override
  ConsumerState<AjouterRebPage> createState() => _AjouterRebPageState();
}

class _AjouterRebPageState extends ConsumerState<AjouterRebPage> {
  static final _euro = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: '€',
    decimalDigits: 2,
  );
  static final _dateShort = DateFormat('dd/MM/yyyy');
  static final _dateRow = DateFormat('EEE. dd-MM', 'fr_FR');
  static final _dateTime = DateFormat('dd/MM/yyyy · HH:mm');

  final _observationController = TextEditingController();
  final _picker = ImagePicker();
  final _selectedIds = <String>{};
  final _strokes = <List<Offset>>[];
  List<Offset> _currentStroke = [];

  DateTime _selectedDate = DateTime.now();
  List<RebEncaissementItem> _encaissements = const [];
  bool _loading = true;
  bool _pickingPhoto = false;
  String? _photoPath;
  String? _loadError;

  int get _codeMag => SwappApiConstants.resolveCodeMagFromCollab(
    ref.read(authProvider).collaborateur,
  );

  double get _totalSelected => _encaissements
      .where((item) => _selectedIds.contains(item.id))
      .fold(0.0, (total, item) => total + item.montant);

  int get _selectableCount =>
      _encaissements.where((item) => !item.dejaRemis).length;

  bool get _hasSignature =>
      _strokes.any((stroke) => stroke.length > 1) || _currentStroke.length > 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEncaissements());
  }

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _loadEncaissements() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final items = await ref
          .read(rebProvider.notifier)
          .fetchEncaissements(codeMag: _codeMag, date: _selectedDate);
      if (!mounted) return;
      setState(() {
        _encaissements = items;
        _selectedIds
          ..clear()
          ..addAll(
            items.where((item) => !item.dejaRemis).map((item) => item.id),
          );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _toggleEncaissement(RebEncaissementItem item) {
    if (item.dejaRemis) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selectedIds.add(item.id)) _selectedIds.remove(item.id);
    });
  }

  Future<void> _selectDate() async {
    HapticFeedback.selectionClick();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      locale: const Locale('fr', 'FR'),
      helpText: 'DATE DE LA REMISE',
      cancelText: 'ANNULER',
      confirmText: 'VALIDER',
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedDate = selected);
    await _loadEncaissements();
  }

  Future<void> _pickProof(ImageSource source) async {
    if (_pickingPhoto) return;
    setState(() => _pickingPhoto = true);
    try {
      if (source == ImageSource.camera) {
        final permission = await Permission.camera.request();
        if (!permission.isGranted) {
          _snack('Autorisez la caméra pour photographier le bordereau.');
          return;
        }
      }
      final photo = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (!mounted || photo == null) return;
      final selectedPath = source == ImageSource.camera
          ? await PhotoAnnotationEditor.open(context, photo.path)
          : photo.path;
      if (!mounted || selectedPath == null) return;
      setState(() => _photoPath = selectedPath);
      HapticFeedback.mediumImpact();
    } catch (_) {
      if (mounted) _snack("Impossible d'ouvrir la source d'image.");
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _annotateCurrentPhoto() async {
    final path = _photoPath;
    if (path == null || _pickingPhoto) return;
    final annotatedPath = await PhotoAnnotationEditor.open(context, path);
    if (!mounted || annotatedPath == null) return;
    setState(() => _photoPath = annotatedPath);
  }

  void _clearSignature() {
    HapticFeedback.selectionClick();
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  Future<void> _submit() async {
    if (_selectedIds.isEmpty) {
      _snack('Sélectionnez au moins un encaissement.');
      return;
    }
    if (_photoPath == null) {
      _snack('Ajoutez une preuve du dépôt (photo ou fichier).');
      return;
    }
    if (!_hasSignature) {
      _snack('Signez avant de valider la remise.');
      return;
    }

    final collab = ref.read(authProvider).collaborateur;
    final request = RebCreateRequest(
      date: _selectedDate,
      codeMag: _codeMag,
      codeCollab: collab?.codeCollab ?? 0,
      prenom: collab?.prenom.trim().isNotEmpty == true
          ? collab!.prenom
          : 'Collaborateur',
      nom: collab?.nom ?? '',
      photoCollaborateurUrl: collab?.pictureLink,
      encaissementIds: _selectedIds.toList(growable: false),
      totalEncaissements: _totalSelected,
      montantDeclare: _totalSelected,
      observations: _observationController.text,
      bordereauLocalPath: _photoPath,
    );

    HapticFeedback.mediumImpact();
    final created = await ref.read(rebProvider.notifier).createReb(request);
    if (!mounted) return;
    if (created == null) {
      _snack(ref.read(rebProvider).error ?? 'Création impossible.');
      return;
    }
    Navigator.pop(context, created);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scale = (MediaQuery.sizeOf(context).width / 390).clamp(0.88, 1.25);
    double dp(double value) => value * scale;
    final insets = MediaQuery.paddingOf(context);
    final saving = ref.watch(rebProvider.select((s) => s.isSaving));
    final collab = ref.watch(authProvider).collaborateur;
    final photoUrl = collab == null
        ? null
        : ref.read(authProvider.notifier).getPhotoUrl(collab.codeCollab);
    final agentName = collab == null
        ? 'Collaborateur'
        : '${collab.prenom} ${collab.nom}'.trim();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: _bg,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _bg,
        body: Column(
          children: [
            _TopBar(
              dp: dp,
              top: insets.top,
              agentName: agentName,
              agentPhotoUrl: photoUrl,
              dateLabel: _dateShort.format(_selectedDate),
              totalLabel: _euro.format(_totalSelected),
              onBack: () => Navigator.pop(context),
              onCamera: () => _pickProof(ImageSource.camera),
              onSave: saving ? null : _submit,
              onPickDate: _selectDate,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(dp(14), dp(18), dp(14), dp(18)),
                children: [
                  _SectionHeader(
                    dp: dp,
                    badgeColor: _indigoTint,
                    iconColor: _indigo,
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Encaissements non remis',
                    subtitle: 'Sélectionnez ceux à inclure',
                    countLabel: '${_selectedIds.length}/$_selectableCount',
                  ),
                  SizedBox(height: dp(10)),
                  _EncaissementsList(
                    dp: dp,
                    loading: _loading,
                    error: _loadError,
                    items: _encaissements,
                    selectedIds: _selectedIds,
                    euro: _euro,
                    dateRow: _dateRow,
                    onRetry: _loadEncaissements,
                    onToggle: _toggleEncaissement,
                  ),
                  SizedBox(height: dp(22)),
                  _SectionHeader(
                    dp: dp,
                    badgeColor: _amberTint,
                    iconColor: _amber,
                    icon: Icons.photo_camera_rounded,
                    title: 'Preuve du dépôt',
                    subtitle: 'Photo ou fichier du bordereau',
                  ),
                  SizedBox(height: dp(10)),
                  _ProofSection(
                    dp: dp,
                    photoPath: _photoPath,
                    picking: _pickingPhoto,
                    onCamera: () => _pickProof(ImageSource.camera),
                    onFile: () => _pickProof(ImageSource.gallery),
                    onAnnotate: _annotateCurrentPhoto,
                    onRemove: () => setState(() => _photoPath = null),
                  ),
                  SizedBox(height: dp(22)),
                  _SectionHeader(
                    dp: dp,
                    badgeColor: _indigoTint,
                    iconColor: _indigo,
                    icon: Icons.draw_rounded,
                    title: 'Signature',
                    subtitle: "Confirmation de l'agent",
                  ),
                  SizedBox(height: dp(10)),
                  _SignatureCard(
                    dp: dp,
                    agentName: agentName,
                    agentPhotoUrl: photoUrl,
                    dateLabel: _dateTime.format(DateTime.now()),
                    strokes: _strokes,
                    currentStroke: _currentStroke,
                    onClear: _clearSignature,
                    onPanStart: (offset) {
                      setState(() => _currentStroke = [offset]);
                    },
                    onPanUpdate: (offset) {
                      setState(
                        () => _currentStroke = [..._currentStroke, offset],
                      );
                    },
                    onPanEnd: () {
                      setState(() {
                        if (_currentStroke.isNotEmpty) {
                          _strokes.add(List.of(_currentStroke));
                        }
                        _currentStroke = [];
                      });
                    },
                  ),
                  SizedBox(height: dp(22)),
                  _SectionHeader(
                    dp: dp,
                    badgeColor: _slateTint,
                    iconColor: _slate,
                    icon: Icons.edit_note_rounded,
                    title: 'Observations',
                    subtitle: 'Optionnel',
                  ),
                  SizedBox(height: dp(10)),
                  _ObservationsCard(dp: dp, controller: _observationController),
                  SizedBox(height: dp(90)),
                ],
              ),
            ),
            _BottomCta(
              dp: dp,
              bottom: insets.bottom,
              amountLabel: _euro.format(_totalSelected),
              saving: saving,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bandeau indigo — navigation, agent, date & total
// ---------------------------------------------------------------------------
class _TopBar extends StatelessWidget {
  final double Function(double) dp;
  final double top;
  final String agentName;
  final String? agentPhotoUrl;
  final String dateLabel;
  final String totalLabel;
  final VoidCallback onBack;
  final VoidCallback onCamera;
  final VoidCallback? onSave;
  final VoidCallback onPickDate;

  const _TopBar({
    required this.dp,
    required this.top,
    required this.agentName,
    required this.agentPhotoUrl,
    required this.dateLabel,
    required this.totalLabel,
    required this.onBack,
    required this.onCamera,
    required this.onSave,
    required this.onPickDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(dp(14), top + dp(4), dp(16), dp(20)),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.85, -0.9),
          radius: 1.35,
          colors: [Color(0xFF363BA8), _indigo, _indigoDeep],
          stops: [0, 0.38, 1],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _GlassBtn(dp: dp, icon: Icons.arrow_back_rounded, onTap: onBack),
              SizedBox(width: dp(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BANQUE',
                      style: TextStyle(
                        fontSize: dp(9.5),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    Text(
                      'Nouvelle remise',
                      style: TextStyle(
                        fontSize: dp(16),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
              ),
              _GlassBtn(
                dp: dp,
                icon: Icons.photo_camera_outlined,
                onTap: onCamera,
              ),
              SizedBox(width: dp(8)),
              Material(
                color: _green,
                borderRadius: BorderRadius.circular(dp(11)),
                elevation: 6,
                shadowColor: _green.withValues(alpha: 0.55),
                child: InkWell(
                  onTap: onSave,
                  borderRadius: BorderRadius.circular(dp(11)),
                  child: SizedBox(
                    width: dp(36),
                    height: dp(36),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: dp(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: dp(16)),
          Row(
            children: [
              _Avatar(dp: dp, size: 32, url: agentPhotoUrl, name: agentName),
              SizedBox(width: dp(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REB effectuée par',
                      style: TextStyle(
                        fontSize: dp(11.5),
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      agentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: dp(14),
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: dp(16)),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  dp: dp,
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: dateLabel,
                  onTap: onPickDate,
                ),
              ),
              SizedBox(width: dp(10)),
              Expanded(
                child: _StatCard(
                  dp: dp,
                  icon: Icons.payments_outlined,
                  label: 'Sélectionné',
                  value: totalLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassBtn extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final VoidCallback onTap;

  const _GlassBtn({required this.dp, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(dp(11)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(11)),
        child: SizedBox(
          width: dp(36),
          height: dp(36),
          child: Icon(icon, color: Colors.white, size: dp(17)),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  const _StatCard({
    required this.dp,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(dp(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(14)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(10)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(dp(14)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: dp(11),
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                  SizedBox(width: dp(5)),
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: dp(9),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              SizedBox(height: dp(4)),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: dp(16),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sections communes
// ---------------------------------------------------------------------------
class _SectionHeader extends StatelessWidget {
  final double Function(double) dp;
  final Color badgeColor;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? countLabel;

  const _SectionHeader({
    required this.dp,
    required this.badgeColor,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.countLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: dp(26),
          height: dp(26),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(dp(8)),
          ),
          child: Icon(icon, size: dp(13), color: iconColor),
        ),
        SizedBox(width: dp(9)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: dp(13),
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: dp(10.5),
                  fontWeight: FontWeight.w600,
                  color: _inkSoft,
                ),
              ),
            ],
          ),
        ),
        if (countLabel != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: dp(9), vertical: dp(3)),
            decoration: BoxDecoration(
              color: _indigo,
              borderRadius: BorderRadius.circular(dp(10)),
            ),
            child: Text(
              countLabel!,
              style: TextStyle(
                fontSize: dp(10.5),
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final double Function(double) dp;
  final double size;
  final String? url;
  final String name;

  const _Avatar({
    required this.dp,
    required this.size,
    required this.url,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final side = dp(size);
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      width: side,
      height: side,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _indigoTint,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.35),
            spreadRadius: 2,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null || url!.isEmpty
          ? Text(
              initials.isEmpty ? '?' : initials,
              style: TextStyle(
                fontSize: dp(size * 0.34),
                fontWeight: FontWeight.w800,
                color: _indigo,
              ),
            )
          : Image.network(
              url!,
              fit: BoxFit.cover,
              width: side,
              height: side,
              errorBuilder: (_, _, _) => Text(
                initials.isEmpty ? '?' : initials,
                style: TextStyle(
                  fontSize: dp(size * 0.34),
                  fontWeight: FontWeight.w800,
                  color: _indigo,
                ),
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Liste des encaissements
// ---------------------------------------------------------------------------
class _EncaissementsList extends StatelessWidget {
  final double Function(double) dp;
  final bool loading;
  final String? error;
  final List<RebEncaissementItem> items;
  final Set<String> selectedIds;
  final NumberFormat euro;
  final DateFormat dateRow;
  final VoidCallback onRetry;
  final ValueChanged<RebEncaissementItem> onToggle;

  const _EncaissementsList({
    required this.dp,
    required this.loading,
    required this.error,
    required this.items,
    required this.selectedIds,
    required this.euro,
    required this.dateRow,
    required this.onRetry,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator(color: _indigo)),
      );
    }
    if (error != null) {
      return TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: Text(error!),
      );
    }
    if (items.isEmpty) {
      return Text(
        'Aucun encaissement disponible.',
        style: TextStyle(
          fontSize: dp(12),
          fontWeight: FontWeight.w600,
          color: _inkSoft,
        ),
      );
    }

    return Column(
      children: [
        for (final item in items) ...[
          _EncRow(
            dp: dp,
            item: item,
            selected: selectedIds.contains(item.id),
            dateLabel: dateRow.format(item.date),
            amountLabel: euro.format(item.montant),
            onTap: () => onToggle(item),
          ),
          SizedBox(height: dp(8)),
        ],
      ],
    );
  }
}

class _EncRow extends StatelessWidget {
  final double Function(double) dp;
  final RebEncaissementItem item;
  final bool selected;
  final String dateLabel;
  final String amountLabel;
  final VoidCallback onTap;

  const _EncRow({
    required this.dp,
    required this.item,
    required this.selected,
    required this.dateLabel,
    required this.amountLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? _greenTint : _card,
      borderRadius: BorderRadius.circular(dp(14)),
      child: InkWell(
        onTap: item.dejaRemis ? null : onTap,
        borderRadius: BorderRadius.circular(dp(14)),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: dp(12), vertical: dp(11)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(dp(14)),
            border: Border.all(
              color: selected ? _green.withValues(alpha: 0.35) : _grayBorder,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: dp(22),
                height: dp(22),
                decoration: BoxDecoration(
                  color: selected ? _green : Colors.white,
                  borderRadius: BorderRadius.circular(dp(7)),
                  border: Border.all(
                    color: selected ? _green : const Color(0xFFD6D8E6),
                    width: 2,
                  ),
                ),
                child: selected
                    ? Icon(
                        Icons.check_rounded,
                        size: dp(14),
                        color: Colors.white,
                      )
                    : null,
              ),
              SizedBox(width: dp(11)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: dp(10.5),
                        fontWeight: FontWeight.w700,
                        color: _inkSoft,
                      ),
                    ),
                    SizedBox(height: dp(1)),
                    Text(
                      amountLabel,
                      style: TextStyle(
                        fontSize: dp(14),
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item.collaborateur,
                style: TextStyle(
                  fontSize: dp(12),
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              SizedBox(width: dp(8)),
              _Avatar(
                dp: dp,
                size: 30,
                url: item.photoUrl,
                name: item.collaborateur,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Preuve du dépôt
// ---------------------------------------------------------------------------
class _ProofSection extends StatelessWidget {
  final double Function(double) dp;
  final String? photoPath;
  final bool picking;
  final VoidCallback onCamera;
  final VoidCallback onFile;
  final VoidCallback onAnnotate;
  final VoidCallback onRemove;

  const _ProofSection({
    required this.dp,
    required this.photoPath,
    required this.picking,
    required this.onCamera,
    required this.onFile,
    required this.onAnnotate,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _ProofTile(
                dp: dp,
                icon: Icons.photo_camera_rounded,
                label: 'Prendre une photo',
                onTap: picking ? null : onCamera,
              ),
            ),
            SizedBox(width: dp(10)),
            Expanded(
              child: _ProofTile(
                dp: dp,
                icon: Icons.attach_file_rounded,
                label: 'Joindre un fichier',
                onTap: picking ? null : onFile,
              ),
            ),
          ],
        ),
        if (photoPath != null) ...[
          SizedBox(height: dp(10)),
          Container(
            height: dp(178),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(dp(14)),
              border: Border.all(color: _green.withValues(alpha: 0.5)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(photoPath!),
                  fit: BoxFit.contain,
                  key: ValueKey(photoPath),
                ),
                Positioned(
                  left: dp(8),
                  top: dp(8),
                  child: Material(
                    color: _indigo.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(dp(20)),
                    child: InkWell(
                      onTap: onAnnotate,
                      borderRadius: BorderRadius.circular(dp(20)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: dp(10),
                          vertical: dp(7),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.draw_rounded,
                              size: dp(14),
                              color: Colors.white,
                            ),
                            SizedBox(width: dp(5)),
                            Text(
                              'Annoter',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: dp(10),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: dp(8),
                  right: dp(8),
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: dp(28),
                      height: dp(28),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: dp(17),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: dp(6)),
                    color: _green.withValues(alpha: 0.85),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: dp(13),
                          color: Colors.white,
                        ),
                        SizedBox(width: dp(5)),
                        Text(
                          'Photo prête à être ajoutée',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: dp(9.5),
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
        ],
      ],
    );
  }
}

class _ProofTile extends StatelessWidget {
  final double Function(double) dp;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ProofTile({
    required this.dp,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFBFBFE),
      borderRadius: BorderRadius.circular(dp(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(dp(16)),
        child: Container(
          height: dp(92),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(dp(16)),
            border: Border.all(
              color: const Color(0xFFC9CCE4),
              width: 1.8,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: const Color(0xFFC9CCE4),
              radius: dp(16),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: dp(34),
                  height: dp(34),
                  decoration: BoxDecoration(
                    color: _indigoTint,
                    borderRadius: BorderRadius.circular(dp(10)),
                  ),
                  child: Icon(icon, size: dp(17), color: _indigo),
                ),
                SizedBox(height: dp(8)),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: dp(11),
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      const dash = 5.0;
      const gap = 4.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

// ---------------------------------------------------------------------------
// Signature
// ---------------------------------------------------------------------------
class _SignatureCard extends StatelessWidget {
  final double Function(double) dp;
  final String agentName;
  final String? agentPhotoUrl;
  final String dateLabel;
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final VoidCallback onClear;
  final ValueChanged<Offset> onPanStart;
  final ValueChanged<Offset> onPanUpdate;
  final VoidCallback onPanEnd;

  const _SignatureCard({
    required this.dp,
    required this.agentName,
    required this.agentPhotoUrl,
    required this.dateLabel,
    required this.strokes,
    required this.currentStroke,
    required this.onClear,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dp(14)),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(dp(18)),
        border: Border.all(color: _grayBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _indigoDeep.withValues(alpha: 0.08),
            blurRadius: dp(18),
            offset: Offset(0, dp(8)),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _Avatar(dp: dp, size: 26, url: agentPhotoUrl, name: agentName),
              SizedBox(width: dp(8)),
              Expanded(
                child: Text(
                  agentName,
                  style: TextStyle(
                    fontSize: dp(12.5),
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              Material(
                color: _slateTint,
                borderRadius: BorderRadius.circular(dp(9)),
                child: InkWell(
                  onTap: onClear,
                  borderRadius: BorderRadius.circular(dp(9)),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: dp(9),
                      vertical: dp(5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: dp(11),
                          color: _slate,
                        ),
                        SizedBox(width: dp(4)),
                        Text(
                          'Effacer',
                          style: TextStyle(
                            fontSize: dp(11),
                            fontWeight: FontWeight.w800,
                            color: _slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: dp(10)),
          Container(
            height: dp(136),
            decoration: BoxDecoration(
              color: const Color(0xFFFCFCFE),
              borderRadius: BorderRadius.circular(dp(14)),
              border: Border.all(color: const Color(0xFFC9CCE4), width: 1.8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(dp(14)),
              child: GestureDetector(
                onPanStart: (d) => onPanStart(d.localPosition),
                onPanUpdate: (d) => onPanUpdate(d.localPosition),
                onPanEnd: (_) => onPanEnd(),
                child: CustomPaint(
                  painter: _SignaturePainter(
                    strokes: strokes,
                    current: currentStroke,
                    lineColor: const Color(0xFFF1F1F7),
                    inkColor: _indigo,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
          SizedBox(height: dp(8)),
          Row(
            children: [
              Text(
                'Signez avec le doigt',
                style: TextStyle(
                  fontSize: dp(10.5),
                  fontWeight: FontWeight.w700,
                  color: _inkSoft,
                ),
              ),
              const Spacer(),
              Text(
                dateLabel,
                style: TextStyle(
                  fontSize: dp(10.5),
                  fontWeight: FontWeight.w700,
                  color: _inkSoft,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> current;
  final Color lineColor;
  final Color inkColor;

  _SignaturePainter({
    required this.strokes,
    required this.current,
    required this.lineColor,
    required this.inkColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final guide = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    for (var y = 22.0; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guide);
    }

    final ink = Paint()
      ..color = inkColor
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void drawStroke(List<Offset> points) {
      if (points.length < 2) return;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, ink);
    }

    for (final stroke in strokes) {
      drawStroke(stroke);
    }
    drawStroke(current);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// Observations
// ---------------------------------------------------------------------------
class _ObservationsCard extends StatelessWidget {
  final double Function(double) dp;
  final TextEditingController controller;

  const _ObservationsCard({required this.dp, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(dp(14), dp(4), dp(8), dp(4)),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(dp(16)),
        border: Border.all(color: _grayBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _indigoDeep.withValues(alpha: 0.07),
            blurRadius: dp(16),
            offset: Offset(0, dp(6)),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 3,
              style: TextStyle(
                fontSize: dp(12.5),
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
              decoration: InputDecoration(
                hintText: 'Vos observations ici',
                hintStyle: TextStyle(
                  fontSize: dp(12.5),
                  fontWeight: FontWeight.w600,
                  color: _inkSoft,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            width: dp(36),
            height: dp(36),
            decoration: BoxDecoration(
              color: _indigo,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _indigo.withValues(alpha: 0.35),
                  blurRadius: dp(12),
                  offset: Offset(0, dp(4)),
                ),
              ],
            ),
            child: Icon(Icons.mic_rounded, color: Colors.white, size: dp(16)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CTA bas de page
// ---------------------------------------------------------------------------
class _BottomCta extends StatelessWidget {
  final double Function(double) dp;
  final double bottom;
  final String amountLabel;
  final bool saving;
  final VoidCallback onTap;

  const _BottomCta({
    required this.dp,
    required this.bottom,
    required this.amountLabel,
    required this.saving,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(dp(14), dp(12), dp(14), dp(16) + bottom),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00EFF0F8), _bg],
          stops: [0, 0.34],
        ),
      ),
      child: Material(
        borderRadius: BorderRadius.circular(dp(15)),
        child: InkWell(
          onTap: saving ? null : onTap,
          borderRadius: BorderRadius.circular(dp(15)),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(dp(15)),
              gradient: const LinearGradient(colors: [_indigo, _indigoDeep]),
              boxShadow: [
                BoxShadow(
                  color: _indigo.withValues(alpha: 0.4),
                  blurRadius: dp(22),
                  offset: Offset(0, dp(10)),
                ),
              ],
            ),
            child: SizedBox(
              height: dp(52),
              child: saving
                  ? const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: dp(17),
                        ),
                        SizedBox(width: dp(9)),
                        Text(
                          'Valider la remise',
                          style: TextStyle(
                            fontSize: dp(14.5),
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: dp(6)),
                        Text(
                          '· $amountLabel',
                          style: TextStyle(
                            fontSize: dp(14.5),
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
