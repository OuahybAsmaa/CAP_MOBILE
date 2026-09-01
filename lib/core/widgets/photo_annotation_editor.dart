import 'dart:io';
import 'dart:ui' as ui;

import 'package:cap_mobile/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Éditeur partagé affiché après une prise de photo.
class PhotoAnnotationEditor extends StatefulWidget {
  final String imagePath;

  const PhotoAnnotationEditor({super.key, required this.imagePath});

  static Future<String?> open(BuildContext context, String imagePath) {
    return Navigator.push<String?>(
      context,
      MaterialPageRoute<String?>(
        fullscreenDialog: true,
        builder: (_) => PhotoAnnotationEditor(imagePath: imagePath),
      ),
    );
  }

  @override
  State<PhotoAnnotationEditor> createState() => _PhotoAnnotationEditorState();
}

class _PhotoAnnotationEditorState extends State<PhotoAnnotationEditor> {
  final _boundaryKey = GlobalKey();
  final List<_AnnotationStroke> _strokes = [];
  List<Offset> _currentPoints = [];
  Color _color = const Color(0xFFEF4444);
  double _strokeWidth = 4;
  bool _saving = false;

  static const _colors = [
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF22C55E),
    Color(0xFF38BDF8),
    Colors.white,
    Colors.black,
  ];

  void _startStroke(DragStartDetails details) {
    setState(() => _currentPoints = [details.localPosition]);
  }

  void _updateStroke(DragUpdateDetails details) {
    setState(() => _currentPoints = [..._currentPoints, details.localPosition]);
  }

  void _endStroke(DragEndDetails details) {
    if (_currentPoints.isEmpty) return;
    setState(() {
      _strokes.add(
        _AnnotationStroke(
          points: List<Offset>.of(_currentPoints),
          color: _color,
          width: _strokeWidth,
        ),
      );
      _currentPoints = [];
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _strokes.removeLast());
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _strokes.clear();
      _currentPoints = [];
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_strokes.isEmpty) {
      Navigator.pop(context, widget.imagePath);
      return;
    }
    setState(() => _saving = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      final boundary = _boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('Image indisponible');
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('Encodage impossible');
      final source = File(widget.imagePath);
      final outputPath =
          '${source.parent.path}${Platform.pathSeparator}photo_annotee_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(outputPath).writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.pop(context, outputPath);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'enregistrer les annotations.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: AppColors.primaryDark,
        systemNavigationBarColor: const Color(0xFF11131B),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF11131B),
        appBar: AppBar(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Annuler la photo',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded),
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Annoter la photo', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              Text('Dessinez directement sur l’image', style: TextStyle(fontSize: 10, color: Colors.white60)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('TERMINER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: RepaintBoundary(
                key: _boundaryKey,
                child: GestureDetector(
                  onPanStart: _startStroke,
                  onPanUpdate: _updateStroke,
                  onPanEnd: _endStroke,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: Colors.black,
                        child: Image.file(File(widget.imagePath), fit: BoxFit.contain),
                      ),
                      CustomPaint(
                        painter: _AnnotationPainter(
                          strokes: _strokes,
                          currentPoints: _currentPoints,
                          currentColor: _color,
                          currentWidth: _strokeWidth,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(14, 10, 14, 10 + bottom),
              color: const Color(0xFF1B1E29),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      for (final color in _colors) ...[
                        _ColorChoice(
                          color: color,
                          selected: color == _color,
                          onTap: () => setState(() => _color = color),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Spacer(),
                      IconButton.filledTonal(
                        tooltip: 'Annuler le dernier trait',
                        onPressed: _strokes.isEmpty ? null : _undo,
                        icon: const Icon(Icons.undo_rounded),
                      ),
                      IconButton.filledTonal(
                        tooltip: 'Tout effacer',
                        onPressed: _strokes.isEmpty ? null : _clear,
                        icon: const Icon(Icons.delete_sweep_outlined),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.edit_rounded, color: Colors.white60, size: 16),
                      Expanded(
                        child: Slider(
                          value: _strokeWidth,
                          min: 2,
                          max: 12,
                          divisions: 5,
                          activeColor: AppColors.primary,
                          onChanged: (value) => setState(() => _strokeWidth = value),
                        ),
                      ),
                      const Icon(Icons.edit_rounded, color: Colors.white, size: 25),
                    ],
                  ),
                  TextButton(
                    onPressed: _saving ? null : () => Navigator.pop(context, widget.imagePath),
                    child: const Text('UTILISER SANS ANNOTATION', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
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

class _AnnotationStroke {
  final List<Offset> points;
  final Color color;
  final double width;

  const _AnnotationStroke({required this.points, required this.color, required this.width});
}

class _AnnotationPainter extends CustomPainter {
  final List<_AnnotationStroke> strokes;
  final List<Offset> currentPoints;
  final Color currentColor;
  final double currentWidth;

  const _AnnotationPainter({required this.strokes, required this.currentPoints, required this.currentColor, required this.currentWidth});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke.points, stroke.color, stroke.width);
    }
    _paintStroke(canvas, currentPoints, currentColor, currentWidth);
  }

  void _paintStroke(Canvas canvas, List<Offset> points, Color color, double width) {
    if (points.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (points.length == 1) {
      canvas.drawCircle(points.first, width / 2, paint..style = PaintingStyle.fill);
      return;
    }
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 1; index < points.length; index++) {
      path.lineTo(points[index].dx, points[index].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AnnotationPainter oldDelegate) => true;
}

class _ColorChoice extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorChoice({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: selected ? 30 : 25,
        height: selected ? 30 : 25,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: selected ? Colors.white : Colors.white24, width: selected ? 3 : 1),
          boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 8)] : null,
        ),
      ),
    );
  }
}
