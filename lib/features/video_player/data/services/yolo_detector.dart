import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:onnxruntime/onnxruntime.dart';
import '../models/detection_result.dart';

class YOLODetector {
  OrtSession? _session;
  OrtSessionOptions? _sessionOptions;


  static const List<String> classNames = [
    'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train',
    'truck', 'boat', 'traffic light', 'fire hydrant', 'stop sign',
    'parking meter', 'bench', 'bird', 'cat', 'dog', 'horse', 'sheep', 'cow',
    'elephant', 'bear', 'zebra', 'giraffe', 'backpack', 'umbrella', 'handbag',
    'tie', 'suitcase', 'frisbee', 'skis', 'snowboard', 'sports ball', 'kite',
    'baseball bat', 'baseball glove', 'skateboard', 'surfboard',
    'tennis racket', 'bottle', 'wine glass', 'cup', 'fork', 'knife', 'spoon',
    'bowl', 'banana', 'apple', 'sandwich', 'orange', 'broccoli', 'carrot',
    'hot dog', 'pizza', 'donut', 'cake', 'chair', 'couch', 'potted plant',
    'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse', 'remote',
    'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink',
    'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear',
    'hair drier', 'toothbrush'
  ];

  bool get isInitialized => _session != null;

  Future<void> initialize({Uint8List? modelBytes}) async {
    try {
      
      // Initialize environment
      OrtEnv.instance.init();

      // Check available providers
      print('[YOLO] Available providers:');
      OrtEnv.instance.availableProviders().forEach((provider) {
        print('  - $provider');
      });

      // Configure session options
      _sessionOptions = OrtSessionOptions()
        ..setInterOpNumThreads(4)
        ..setIntraOpNumThreads(4)
        ..setSessionGraphOptimizationLevel(
          GraphOptimizationLevel.ortEnableAll,
        );

      // 🚀 TRY GPU ACCELERATION (in priority order)
      bool gpuEnabled = false;


      // Load model
      Uint8List bytes;
      if (modelBytes != null) {
        bytes = modelBytes;
        print('[YOLO] Using provided model bytes (${bytes.length})');
      } else {
        final modelData = await rootBundle.load('assets/models/best-s-2-ir9.onnx');
        bytes = modelData.buffer.asUint8List();
        print('[YOLO] Loaded model from assets (${bytes.length} bytes)');
      }

      _session = OrtSession.fromBuffer(bytes, _sessionOptions!);
      print('[YOLO] ✓ Model loaded successfully');
     
      
    } catch (e) {
      print('[YOLO] ✗ Initialization error: $e');
      rethrow;
    }
  }

  /// Alternative: Use automatic provider selection
  Future<void> initializeWithAutoGPU({Uint8List? modelBytes}) async {
    try {
      print('[YOLO] Initializing with auto GPU selection...');
      
      OrtEnv.instance.init();

      _sessionOptions = OrtSessionOptions()
        ..setInterOpNumThreads(4)
        ..setIntraOpNumThreads(4)
        ..setSessionGraphOptimizationLevel(GraphOptimizationLevel.ortEnableAll);

      

      // Load model
      Uint8List bytes;
      if (modelBytes != null) {
        bytes = modelBytes;
      } else {
        final modelData = await rootBundle.load('assets/models/best-s-2.onnx');
        bytes = modelData.buffer.asUint8List();
      }

      _session = OrtSession.fromBuffer(bytes, _sessionOptions!);
      print('[YOLO] ✓ Initialized with auto acceleration');
      
    } catch (e) {
      print('[YOLO] ✗ Initialization error: $e');
      rethrow;
    }
  }

  Future<List<DetectionResult>> detectObjects(
    Uint8List imageBytes, {
    double confidenceThreshold = 0.5,
  }) async {
    if (_session == null) {
      throw Exception('Detector not initialized');
    }

    OrtValueTensor? inputTensor;
    OrtRunOptions? runOptions;
    List<OrtValue?>? outputs;

    try {
      final startTime = DateTime.now();

      // Decode image
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Failed to decode image');

      final originalWidth = image.width;
      final originalHeight = image.height;

      // Preprocess
      final preprocessedDoubles = _preprocessImage(image);
      final preprocessedFloat32 = Float32List.fromList(preprocessedDoubles);

      // Create input tensor
      inputTensor = OrtValueTensor.createTensorWithDataList(
        preprocessedFloat32,
        [1, 3, 640, 640],
      );

      // Run inference
      final inputs = {'images': inputTensor};
      runOptions = OrtRunOptions();
      
      final inferenceStart = DateTime.now();
      outputs = await _session!.runAsync(runOptions, inputs);
      final inferenceTime = DateTime.now().difference(inferenceStart).inMilliseconds;

      if (outputs == null || outputs.isEmpty) {
        throw Exception('ONNX inference returned null or empty outputs');
      }

      // Parse results
      final detections = _parseOutputs(
        outputs,
        originalWidth,
        originalHeight,
        confidenceThreshold,
      );

      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      
      print('[YOLO] Found ${detections.length} detections');

      return detections;
    } catch (e) {
      print('[YOLO] Detection error: $e');
      rethrow;
    } finally {
      // Cleanup
      try {
        inputTensor?.release();
        runOptions?.release();
        if (outputs != null) {
          for (var output in outputs) {
            output?.release();
          }
        }
      } catch (e) {
        print('[YOLO] Cleanup error: $e');
      }
    }
  }

  List<double> _preprocessImage(img.Image image) {
    final resized = img.copyResize(
      image,
      width: 640,
      height: 640,
      interpolation: img.Interpolation.linear,
    );

    final List<double> inputData = [];
    
    for (int c = 0; c < 3; c++) {
      for (int y = 0; y < 640; y++) {
        for (int x = 0; x < 640; x++) {
          final pixel = resized.getPixel(x, y);
          double value;
          if (c == 0) {
            value = pixel.r / 255.0;
          } else if (c == 1) {
            value = pixel.g / 255.0;
          } else {
            value = pixel.b / 255.0;
          }
          inputData.add(value);
        }
      }
    }

    return inputData;
  }

  List<DetectionResult> _parseOutputs(
    List<OrtValue?> outputs,
    int originalWidth,
    int originalHeight,
    double confidenceThreshold,
  ) {
    if (outputs.isEmpty || outputs[0] == null) {
      print('[YOLO] No valid outputs received');
      return [];
    }

    try {
      final rawOutput = outputs[0]!.value;
      
      if (rawOutput is List) {
        if (rawOutput.length == 1 && rawOutput[0] is List) {
          final batch = rawOutput[0] as List;
          if (batch.isNotEmpty && batch[0] is List) {
            return _parseRawYOLOOutput(
              batch,
              originalWidth,
              originalHeight,
              confidenceThreshold,
            );
          }
        }
      }
      
      return [];
    } catch (e) {
      print('[YOLO] Error in _parseOutputs: $e');
      return [];
    }
  }

  List<DetectionResult> _parseRawYOLOOutput(
    List batch,
    int originalWidth,
    int originalHeight,
    double confidenceThreshold,
  ) {
    try {
      if (batch.isEmpty || batch[0] is! List) {
        return [];
      }

      final numFeatures = batch.length;
      final numBoxes = (batch[0] as List).length;
      final List<DetectionResult> detections = [];

      for (int boxIdx = 0; boxIdx < numBoxes; boxIdx++) {
        try {
          final cx = (batch[0][boxIdx] as num).toDouble();
          final cy = (batch[1][boxIdx] as num).toDouble();
          final w = (batch[2][boxIdx] as num).toDouble();
          final h = (batch[3][boxIdx] as num).toDouble();

          double maxConfidence = 0.0;
          int maxClassId = 0;

          for (int classIdx = 0; classIdx < numFeatures - 4; classIdx++) {
            final confidence = (batch[4 + classIdx][boxIdx] as num).toDouble();
            if (confidence > maxConfidence) {
              maxConfidence = confidence;
              maxClassId = classIdx;
            }
          }

          if (maxConfidence >= confidenceThreshold) {
            final x1 = cx - w / 2;
            final y1 = cy - h / 2;
            final x2 = cx + w / 2;
            final y2 = cy + h / 2;

            final scaleX = originalWidth / 640.0;
            final scaleY = originalHeight / 640.0;

            detections.add(DetectionResult(
              x1: x1 * scaleX,
              y1: y1 * scaleY,
              x2: x2 * scaleX,
              y2: y2 * scaleY,
              confidence: maxConfidence,
              classId: maxClassId,
              className: maxClassId < classNames.length
                  ? classNames[maxClassId]
                  : 'unknown',
            ));
          }
        } catch (e) {
          continue;
        }
      }

      return _applyNMS(detections, iouThreshold: 0.45);
    } catch (e) {
      print('[YOLO] Error parsing raw YOLO output: $e');
      return [];
    }
  }

  List<DetectionResult> _applyNMS(
    List<DetectionResult> detections, {
    double iouThreshold = 0.45,
  }) {
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final List<DetectionResult> keep = [];
    final suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      keep.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        final iou = _calculateIoU(detections[i], detections[j]);
        if (iou > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return keep;
  }

  double _calculateIoU(DetectionResult a, DetectionResult b) {
    final x1 = a.x1 > b.x1 ? a.x1 : b.x1;
    final y1 = a.y1 > b.y1 ? a.y1 : b.y1;
    final x2 = a.x2 < b.x2 ? a.x2 : b.x2;
    final y2 = a.y2 < b.y2 ? a.y2 : b.y2;

    if (x2 <= x1 || y2 <= y1) return 0.0;

    final intersection = (x2 - x1) * (y2 - y1);
    final areaA = (a.x2 - a.x1) * (a.y2 - a.y1);
    final areaB = (b.x2 - b.x1) * (b.y2 - b.y1);
    final union = areaA + areaB - intersection;

    return intersection / union;
  }

  void dispose() {
    _session?.release();
    _sessionOptions?.release();
    OrtEnv.instance.release();
    print('[YOLO] Resources released');
  }
}
