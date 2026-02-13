import 'package:flutter/foundation.dart';

class DetectionResult {
  final double x1;
  final double y1;
  final double x2;
  final double y2;
  final double confidence;
  final int classId;
  final String className;

  DetectionResult({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.confidence,
    required this.classId,
    required this.className,
  });

  DetectionResult copyWith({
    double? x1,
    double? y1,
    double? x2,
    double? y2,
    double? confidence,
    int? classId,
    String? className,
  }) {
    return DetectionResult(
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      x2: x2 ?? this.x2,
      y2: y2 ?? this.y2,
      confidence: confidence ?? this.confidence,
      classId: classId ?? this.classId,
      className: className ?? this.className,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x1': x1,
      'y1': y1,
      'x2': x2,
      'y2': y2,
      'confidence': confidence,
      'classId': classId,
      'className': className,
    };
  }

  factory DetectionResult.fromMap(Map<String, dynamic> map) {
    return DetectionResult(
      x1: (map['x1'] as num).toDouble(),
      y1: (map['y1'] as num).toDouble(),
      x2: (map['x2'] as num).toDouble(),
      y2: (map['y2'] as num).toDouble(),
      confidence: (map['confidence'] as num).toDouble(),
      classId: map['classId'] as int,
      className: map['className'] as String,
    );
  }

  @override
  String toString() {
    return 'DetectionResult(className: $className, conf: ${confidence.toStringAsFixed(2)}, '
        'x1: $x1, y1: $y1, x2: $x2, y2: $y2)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DetectionResult &&
        other.x1 == x1 &&
        other.y1 == y1 &&
        other.x2 == x2 &&
        other.y2 == y2 &&
        other.confidence == confidence &&
        other.classId == classId &&
        other.className == className;
  }

  @override
  int get hashCode {
    return x1.hashCode ^
        y1.hashCode ^
        x2.hashCode ^
        y2.hashCode ^
        confidence.hashCode ^
        classId.hashCode ^
        className.hashCode;
  }
}
