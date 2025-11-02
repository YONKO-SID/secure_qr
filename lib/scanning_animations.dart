import 'package:flutter/material.dart';

class ScanLineAnimation extends StatefulWidget {
  final Rect window;
  const ScanLineAnimation({super.key, required this.window});

  @override
  State<ScanLineAnimation> createState() => _ScanLineAnimationState();
}

class _ScanLineAnimationState extends State<ScanLineAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScanLinePainter(
            window: widget.window,
            progress: _controller.value,
          ),
        );
      },
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final Rect window;
  final double progress;

  _ScanLinePainter({required this.window, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = window.top + (window.height * progress);
    final paint = Paint()
      ..color = const Color(0xFF11F3E5)
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawLine(
      Offset(window.left, y),
      Offset(window.right, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(_ScanLinePainter old) => old.progress != progress;
}

class CornerIndicatorsPainter extends CustomPainter {
  final Rect window;
  final Color color;

  CornerIndicatorsPainter({required this.window, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6);

    final cornerLength = 24.0;
    final hex = _getHexPoints(window);

    // Draw L-shaped corners at each vertex
    for (int i = 0; i < hex.length; i++) {
      final curr = hex[i];
      final prev = hex[(i - 1 + hex.length) % hex.length];
      final next = hex[(i + 1) % hex.length];

      // Line toward previous point
      final toPrev = (prev - curr).normalized() * cornerLength;
      canvas.drawLine(curr, curr + toPrev, paint);

      // Line toward next point
      final toNext = (next - curr).normalized() * cornerLength;
      canvas.drawLine(curr, curr + toNext, paint);
    }
  }

  List<Offset> _getHexPoints(Rect r) {
    final cx = r.center.dx, cy = r.center.dy;
    final rx = r.width / 2, ry = r.height / 2;
    return [
      Offset(cx, cy - ry),
      Offset(cx + rx * 0.866, cy - ry / 2),
      Offset(cx + rx * 0.866, cy + ry / 2),
      Offset(cx, cy + ry),
      Offset(cx - rx * 0.866, cy + ry / 2),
      Offset(cx - rx * 0.866, cy - ry / 2),
    ];
  }

  @override
  bool shouldRepaint(covariant CornerIndicatorsPainter old) =>
      old.window != window || old.color != color;
}

extension OffsetExtensions on Offset {
  Offset normalized() {
    final d = distance;
    return d == 0 ? this : this / d;
  }
}