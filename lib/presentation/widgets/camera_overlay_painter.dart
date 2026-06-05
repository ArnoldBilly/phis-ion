import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// FR-03: Custom painter for rendering bounding boxes over camera preview.
/// Scales bounding boxes from image coordinate space to screen space.
class CameraOverlayPainter extends CustomPainter {
  final List<Rect> boundingBoxes;
  final Size imageSize;
  final bool isMirrored; // front camera needs horizontal flip

  CameraOverlayPainter({
    required this.boundingBoxes,
    required this.imageSize,
    this.isMirrored = false,
  });

  @override
  void paint(Canvas canvas, Size screenSize) {
    if (boundingBoxes.isEmpty || imageSize == Size.zero) return;

    final scaleX = screenSize.width / imageSize.width;
    final scaleY = screenSize.height / imageSize.height;

    // Glow paint — outer glow
    final glowPaint = Paint()
      ..color = AppTheme.primary.withOpacity(0.25)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Main border paint
    final borderPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    // Corner accent paint
    final cornerPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final rect in boundingBoxes) {
      double left = rect.left * scaleX;
      double top = rect.top * scaleY;
      double right = rect.right * scaleX;
      double bottom = rect.bottom * scaleY;

      if (isMirrored) {
        final tmp = left;
        left = screenSize.width - right;
        right = screenSize.width - tmp;
      }

      final scaledRect = Rect.fromLTRB(left, top, right, bottom);

      // Draw glow
      canvas.drawRect(scaledRect, glowPaint);

      // Draw border
      canvas.drawRect(scaledRect, borderPaint);

      // Draw corner accents
      _drawCorners(canvas, scaledRect, cornerPaint);
    }
  }

  void _drawCorners(Canvas canvas, Rect rect, Paint paint) {
    const double cornerLen = 16.0;
    final corners = [
      // Top-left
      [
        Offset(rect.left, rect.top + cornerLen),
        Offset(rect.left, rect.top),
        Offset(rect.left + cornerLen, rect.top),
      ],
      // Top-right
      [
        Offset(rect.right - cornerLen, rect.top),
        Offset(rect.right, rect.top),
        Offset(rect.right, rect.top + cornerLen),
      ],
      // Bottom-left
      [
        Offset(rect.left, rect.bottom - cornerLen),
        Offset(rect.left, rect.bottom),
        Offset(rect.left + cornerLen, rect.bottom),
      ],
      // Bottom-right
      [
        Offset(rect.right - cornerLen, rect.bottom),
        Offset(rect.right, rect.bottom),
        Offset(rect.right, rect.bottom - cornerLen),
      ],
    ];

    for (final corner in corners) {
      final path = Path()
        ..moveTo(corner[0].dx, corner[0].dy)
        ..lineTo(corner[1].dx, corner[1].dy)
        ..lineTo(corner[2].dx, corner[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(CameraOverlayPainter oldDelegate) {
    return oldDelegate.boundingBoxes != boundingBoxes ||
        oldDelegate.imageSize != imageSize;
  }
}

/// Scanning crosshair overlay shown when no URL is detected
class ScannerFramePainter extends CustomPainter {
  final bool isScanning;
  final double animValue;

  const ScannerFramePainter({
    required this.isScanning,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final frameW = size.width * 0.72;
    final frameH = frameW * 0.62;
    final left = centerX - frameW / 2;
    final top = centerY - frameH / 2;
    final rect = Rect.fromLTWH(left, top, frameW, frameH);

    final dimPaint = Paint()..color = Colors.black.withOpacity(0.5);
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(fullRect),
        Path()
          ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))),
      ),
      dimPaint,
    );

    final cornerPaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLen = 22.0;
    _drawFrameCorners(canvas, rect, cornerPaint, cornerLen);

    if (isScanning) {
      final scanY = rect.top + (rect.height * animValue);
      final scanPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            AppTheme.primary.withOpacity(0),
            AppTheme.primary.withOpacity(0.8),
            AppTheme.primary.withOpacity(0),
          ],
        ).createShader(Rect.fromLTWH(rect.left, scanY - 2, rect.width, 4));
      canvas.drawRect(Rect.fromLTWH(rect.left, scanY - 2, rect.width, 4),
          scanPaint);
    }
  }

  void _drawFrameCorners(
      Canvas canvas, Rect rect, Paint paint, double len) {
    final paths = [
      _cornerPath(rect.topLeft, len, 1, 1),
      _cornerPath(rect.topRight, len, -1, 1),
      _cornerPath(rect.bottomLeft, len, 1, -1),
      _cornerPath(rect.bottomRight, len, -1, -1),
    ];
    for (final p in paths) canvas.drawPath(p, paint);
  }

  Path _cornerPath(Offset origin, double len, double dx, double dy) {
    return Path()
      ..moveTo(origin.dx + dx * len, origin.dy)
      ..lineTo(origin.dx, origin.dy)
      ..lineTo(origin.dx, origin.dy + dy * len);
  }

  @override
  bool shouldRepaint(ScannerFramePainter old) =>
      old.animValue != animValue || old.isScanning != isScanning;
}
