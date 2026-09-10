import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Model representing a candidate logo option
class AppLogoModel {
  final String id;
  final String title;
  final String subtitle;
  final String typeLabel;

  const AppLogoModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.typeLabel,
  });
}

/// Reusable Open Stage Set Logo Icon / Emblem Widget with multi-candidate support
class AppLogo extends StatelessWidget {
  final double size;
  final bool circular;
  final String? logoId;

  /// Global reactive selected logo ID
  static final ValueNotifier<String> activeLogoIdNotifier =
      ValueNotifier<String>('tuning_fork');

  /// Full catalogue of candidate logo options
  static const List<AppLogoModel> candidateLogos = [
    AppLogoModel(
      id: 'orbit',
      title: 'Orbit & Wave',
      subtitle: 'Concentric orbital rings with acoustic wave pulse',
      typeLabel: 'GRAPHIC',
    ),
    AppLogoModel(
      id: 'spotlight',
      title: 'Stage Spotlight',
      subtitle: 'Proscenium beam illuminating sound equalizer bars',
      typeLabel: 'GRAPHIC',
    ),
    AppLogoModel(
      id: 'harmonic',
      title: 'Harmonic Wheel',
      subtitle: '12-node Circle of Fifths geometric constellation',
      typeLabel: 'VECTOR',
    ),
    AppLogoModel(
      id: 'proscenium',
      title: 'Proscenium Stage',
      subtitle: 'Architectural stage arch over soundwave horizon',
      typeLabel: 'VECTOR',
    ),
    AppLogoModel(
      id: 'tuning_fork',
      title: 'Resonance Fork',
      subtitle: 'Minimalist tuning fork within sound ripple rings',
      typeLabel: 'VECTOR',
    ),
    AppLogoModel(
      id: 'legacy',
      title: 'Legacy Arch',
      subtitle: 'Original arch and jagged waveform emblem',
      typeLabel: 'ORIGINAL',
    ),
  ];

  const AppLogo({
    super.key,
    this.size = 28,
    this.circular = true,
    this.logoId,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (logoId != null) {
      return _buildFrame(context, colorScheme, logoId!);
    }

    return ValueListenableBuilder<String>(
      valueListenable: activeLogoIdNotifier,
      builder: (context, activeId, _) {
        return _buildFrame(context, colorScheme, activeId);
      },
    );
  }

  Widget _buildFrame(BuildContext context, ColorScheme colorScheme, String effectiveId) {
    final content = _buildLogoContent(effectiveId, colorScheme, size);

    if (circular) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surface,
          border: Border.all(
            color: colorScheme.outline,
            width: 1.0,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.18),
        color: colorScheme.surface,
        border: Border.all(
          color: colorScheme.outline,
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: content,
    );
  }

  Widget _buildLogoContent(String id, ColorScheme colorScheme, double s) {
    switch (id) {
      case 'orbit':
        return Image.asset(
          'assets/images/logo_orbit.jpg',
          width: s,
          height: s,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(colorScheme, s),
        );
      case 'spotlight':
        return Image.asset(
          'assets/images/logo_spotlight.jpg',
          width: s,
          height: s,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(colorScheme, s),
        );
      case 'harmonic':
        return SizedBox(
          width: s,
          height: s,
          child: CustomPaint(
            size: Size(s, s),
            painter: _HarmonicCircleLogoPainter(color: colorScheme.onSurface),
          ),
        );
      case 'proscenium':
        return SizedBox(
          width: s,
          height: s,
          child: CustomPaint(
            size: Size(s, s),
            painter: _ProsceniumLogoPainter(color: colorScheme.onSurface),
          ),
        );
      case 'legacy':
        return Image.asset(
          'assets/images/logo.png',
          width: s,
          height: s,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildFallback(colorScheme, s),
        );
      case 'tuning_fork':
      default:
        return SizedBox(
          width: s,
          height: s,
          child: CustomPaint(
            size: Size(s, s),
            painter: _TuningForkLogoPainter(color: colorScheme.onSurface),
          ),
        );
    }
  }

  Widget _buildFallback(ColorScheme colorScheme, double s) {
    return Container(
      width: s,
      height: s,
      color: colorScheme.onSurface,
      child: Center(
        child: Icon(
          Icons.graphic_eq,
          size: s * 0.6,
          color: colorScheme.surface,
        ),
      ),
    );
  }
}

/// Custom Vector Painter: Harmonic Circle of Fifths Geometric Constellation
class _HarmonicCircleLogoPainter extends CustomPainter {
  final Color color;

  _HarmonicCircleLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * 0.78;

    final outerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.042;

    final innerPaint = Paint()
      ..color = color.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.022;

    final chordPaint = Paint()
      ..color = color.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.025;

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw outer circle
    canvas.drawCircle(center, radius, outerPaint);
    // Draw concentric inner harmonic ring
    canvas.drawCircle(center, radius * 0.52, innerPaint);

    // Calculate 12 node positions
    final points = <Offset>[];
    for (int i = 0; i < 12; i++) {
      final angle = (i * 2 * math.pi / 12) - (math.pi / 2);
      points.add(Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      ));
    }

    // Connect chord lines (Major Triad: 0 -> 4 -> 7 -> 0)
    canvas.drawLine(points[0], points[4], chordPaint);
    canvas.drawLine(points[4], points[7], chordPaint);
    canvas.drawLine(points[7], points[0], chordPaint);

    // Connect Fifth axis (0 -> 7) and Fourth axis (0 -> 5)
    canvas.drawLine(points[0], points[5], chordPaint);
    canvas.drawLine(points[2], points[9], chordPaint);

    // Draw 12 node dots
    for (int i = 0; i < 12; i++) {
      final isRoot = (i == 0);
      final r = isRoot ? size.width * 0.05 : size.width * 0.032;
      canvas.drawCircle(points[i], r, dotPaint);
    }

    // Central harmonic nucleus
    canvas.drawCircle(center, size.width * 0.045, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _HarmonicCircleLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Custom Vector Painter: Architectural Proscenium Stage Arch & Equalizer Bars
class _ProsceniumLogoPainter extends CustomPainter {
  final Color color;

  _ProsceniumLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Outer stage arch path
    final archPath = Path();
    final leftX = w * 0.20;
    final rightX = w * 0.80;
    final bottomY = h * 0.80;
    final shoulderY = h * 0.44;

    archPath.moveTo(leftX, bottomY);
    archPath.lineTo(leftX, shoulderY);
    archPath.quadraticBezierTo(w * 0.50, h * 0.12, rightX, shoulderY);
    archPath.lineTo(rightX, bottomY);

    canvas.drawPath(archPath, strokePaint);

    // Stage floor line
    canvas.drawLine(
      Offset(w * 0.14, bottomY),
      Offset(w * 0.86, bottomY),
      strokePaint..strokeWidth = w * 0.055,
    );

    // Sound equalizer bars rising from stage floor
    final barFractions = [0.22, 0.38, 0.50, 0.36, 0.24];
    final barCount = barFractions.length;
    final barW = w * 0.055;
    final spacing = w * 0.04;
    final totalBarsW = (barCount * barW) + ((barCount - 1) * spacing);
    final startX = (w - totalBarsW) / 2;

    for (int i = 0; i < barCount; i++) {
      final x = startX + i * (barW + spacing);
      final barH = h * barFractions[i];
      final topY = bottomY - barH - (h * 0.03);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, topY, barW, barH),
        Radius.circular(barW / 2),
      );
      canvas.drawRRect(rect, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ProsceniumLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Custom Vector Painter: Minimalist Tuning Fork with Acoustic Resonance Rings
class _TuningForkLogoPainter extends CustomPainter {
  final Color color;

  _TuningForkLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final ringPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.032;

    final solidPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.048
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Outer acoustic resonance ring
    canvas.drawCircle(center, (w / 2) * 0.82, solidPaint..strokeWidth = w * 0.04);
    canvas.drawCircle(center, (w / 2) * 0.60, ringPaint);

    // Tuning fork prongs and stem
    final forkLeft = w * 0.43;
    final forkRight = w * 0.57;
    final prongTop = h * 0.24;
    final prongBottom = h * 0.52;
    final stemBottom = h * 0.76;

    // Prongs
    final forkPath = Path();
    forkPath.moveTo(forkLeft, prongTop);
    forkPath.lineTo(forkLeft, prongBottom);
    forkPath.quadraticBezierTo(w * 0.50, h * 0.58, forkRight, prongBottom);
    forkPath.lineTo(forkRight, prongTop);

    canvas.drawPath(forkPath, solidPaint..strokeWidth = w * 0.045);

    // Stem
    canvas.drawLine(
      Offset(w * 0.50, h * 0.56),
      Offset(w * 0.50, stemBottom),
      solidPaint..strokeWidth = w * 0.048,
    );

    // Base knob
    canvas.drawCircle(Offset(w * 0.50, stemBottom), w * 0.04, fillPaint);

    // Subtle horizontal acoustic ripple
    final ripplePaint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.025
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(w * 0.22, h * 0.45),
      Offset(w * 0.36, h * 0.45),
      ripplePaint,
    );
    canvas.drawLine(
      Offset(w * 0.64, h * 0.45),
      Offset(w * 0.78, h * 0.45),
      ripplePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TuningForkLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
