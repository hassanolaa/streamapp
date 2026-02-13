import 'package:flutter/material.dart';
import 'package:streamapp/features/video_player/data/models/detection_result.dart';

class DetectionPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final double imageWidth;
  final double imageHeight;

  DetectionPainter({
    required this.detections,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Safety checks
    if (detections.isEmpty) return;
    if (size.width <= 0 || size.height <= 0) return;
    if (imageWidth <= 0 || imageHeight <= 0) return;

    try {
      canvas.save();
      
      final scaleX = size.width / imageWidth;
      final scaleY = size.height / imageHeight;

      for (int i = 0; i < detections.length; i++) {
        try {
          _drawDetection(canvas, detections[i], scaleX, scaleY, size, i);
        } catch (e) {
          print('[Painter] Error drawing detection $i: $e');
          continue;
        }
      }
      
      canvas.restore();
    } catch (e) {
      print('[Painter] Fatal paint error: $e');
    }
  }

  void _drawDetection(
    Canvas canvas,
    DetectionResult detection,
    double scaleX,
    double scaleY,
    Size canvasSize,
    int index,
  ) {
    // Validate detection coordinates
    if (!detection.x1.isFinite || !detection.y1.isFinite ||
        !detection.x2.isFinite || !detection.y2.isFinite) {
      return;
    }

    // Scale coordinates
    double x1 = detection.x1 * scaleX;
    double y1 = detection.y1 * scaleY;
    double x2 = detection.x2 * scaleX;
    double y2 = detection.y2 * scaleY;

    // Clamp to canvas bounds
    x1 = x1.clamp(0.0, canvasSize.width - 1);
    y1 = y1.clamp(0.0, canvasSize.height - 1);
    x2 = x2.clamp(x1 + 1, canvasSize.width);
    y2 = y2.clamp(y1 + 1, canvasSize.height);

    // Skip if box is too small
    if (x2 - x1 < 2 || y2 - y1 < 2) return;

    final color = _getColor(index);
    final rect = Rect.fromLTRB(x1, y1, x2, y2);

    // Draw filled box
    final fillPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    canvas.drawRect(rect, fillPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..isAntiAlias = true;
    canvas.drawRect(rect, borderPaint);

    // Draw corner indicators
    _drawCorners(canvas, rect, color);

    // Draw label
    _drawLabel(canvas, detection, x1, y1, canvasSize, color);
  }

  void _drawCorners(Canvas canvas, Rect rect, Color color) {
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const cornerLength = 15.0;

    // Top-left
    canvas.drawLine(Offset(rect.left, rect.top), 
                    Offset(rect.left + cornerLength, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.top), 
                    Offset(rect.left, rect.top + cornerLength), cornerPaint);

    // Top-right
    canvas.drawLine(Offset(rect.right - cornerLength, rect.top), 
                    Offset(rect.right, rect.top), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.top), 
                    Offset(rect.right, rect.top + cornerLength), cornerPaint);

    // Bottom-left
    canvas.drawLine(Offset(rect.left, rect.bottom - cornerLength), 
                    Offset(rect.left, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.left, rect.bottom), 
                    Offset(rect.left + cornerLength, rect.bottom), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(rect.right - cornerLength, rect.bottom), 
                    Offset(rect.right, rect.bottom), cornerPaint);
    canvas.drawLine(Offset(rect.right, rect.bottom - cornerLength), 
                    Offset(rect.right, rect.bottom), cornerPaint);
  }

  void _drawLabel(
    Canvas canvas,
    DetectionResult detection,
    double x,
    double y,
    Size canvasSize,
    Color color,
  ) {
    try {
      final label = '${detection.className} ${(detection.confidence * 100).toStringAsFixed(0)}%';
      
      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.8),
            offset: const Offset(1, 1),
            blurRadius: 2,
          ),
        ],
      );

      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: 1,
      );
      
      textPainter.layout(maxWidth: canvasSize.width - 20);

      // Position label
      double labelX = x.clamp(5.0, canvasSize.width - textPainter.width - 5);
      double labelY = (y - textPainter.height - 10).clamp(5.0, canvasSize.height - textPainter.height - 5);

      // Draw background
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          labelX - 6,
          labelY - 4,
          textPainter.width + 12,
          textPainter.height + 8,
        ),
        const Radius.circular(4),
      );

      final bgPaint = Paint()
        ..color = color.withOpacity(0.9)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(bgRect, bgPaint);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawRRect(bgRect, borderPaint);

      // Draw text
      textPainter.paint(canvas, Offset(labelX, labelY));
      
    } catch (e) {
      print('[Painter] Error drawing label: $e');
    }
  }

  Color _getColor(int index) {
    const colors = [
      Color(0xFFE74C3C), // Red
      Color(0xFF3498DB), // Blue
      Color(0xFF2ECC71), // Green
      Color(0xFFF39C12), // Orange
      Color(0xFF9B59B6), // Purple
      Color(0xFF1ABC9C), // Turquoise
      Color(0xFFE91E63), // Pink
      Color(0xFF00BCD4), // Cyan
    ];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(covariant DetectionPainter oldDelegate) {
    return detections.length != oldDelegate.detections.length ||
           imageWidth != oldDelegate.imageWidth ||
           imageHeight != oldDelegate.imageHeight;
  }
}
