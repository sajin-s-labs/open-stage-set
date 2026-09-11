import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Render Tuning Fork Logo to PNG', () async {
    const double size = 1024;
    
    // 1. Render Full Master Logo (Black Background + White Tuning Fork)
    {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

      // Black background
      final bgPaint = Paint()..color = const Color(0xFF000000);
      canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), bgPaint);

      // Draw tuning fork with padding (padded to 80% to ensure margin)
      canvas.save();
      const double scale = 0.82;
      canvas.translate(size * (1 - scale) / 2, size * (1 - scale) / 2);
      canvas.scale(scale, scale);
      _drawTuningFork(canvas, const Size(size, size), const Color(0xFFFFFFFF));
      canvas.restore();

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      File('assets/images/logo.png').writeAsBytesSync(bytes);
      print('Wrote assets/images/logo.png (${bytes.length} bytes)');
    }

    // 2. Render Adaptive Icon Foreground (Transparent background, centered in safe-zone)
    {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, size, size));

      // Android adaptive safe-zone is 66/108 = ~61%
      canvas.save();
      const double scale = 0.58;
      canvas.translate(size * (1 - scale) / 2, size * (1 - scale) / 2);
      canvas.scale(scale, scale);
      _drawTuningFork(canvas, const Size(size, size), const Color(0xFFFFFFFF));
      canvas.restore();

      final picture = recorder.endRecording();
      final img = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      File('assets/images/logo_foreground.png').writeAsBytesSync(bytes);
      print('Wrote assets/images/logo_foreground.png (${bytes.length} bytes)');
    }
  });
}

void _drawTuningFork(Canvas canvas, Size size, Color color) {
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
