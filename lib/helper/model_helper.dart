import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'dart:math' as math;

class ModelHelper {
  static late Interpreter _interpreter;
  static late List<String> _labels;
  static bool _isLoaded = false;

  // Tensor metadata
  static late TensorType _inputType;
  static late TensorType _outputType;
  static double _outputScale = 1.0;
  static int _outputZeroPoint = 0;

  // Model configuration
  static const int inputSize = 224;
  static const int numChannels = 3;

  static bool _isQuantizedType(TensorType type) =>
      type == TensorType.uint8 || type == TensorType.int8;

  static bool get _isQuantizedInput => _isQuantizedType(_inputType);
  static bool get _isQuantizedOutput => _isQuantizedType(_outputType);

  static bool get isLoaded => _isLoaded;
  static Interpreter get interpreter => _interpreter;
  static List<String> get labels => _labels;

  static Future<void> loadModel() async {
    try {
      if (_isLoaded) return;

      debugPrint('📦 Starting model loading...');

      // Load model dengan error handling yang lebih baik
      final options = InterpreterOptions();

      // Reduce threads untuk menghindari crash di device rendah
      options.threads = 2;

      _interpreter = await Interpreter.fromAsset(
        'assets/models/model.tflite',
        options: options,
      );

      debugPrint('✅ Model interpreter created');

      // Cache tensor metadata for later de/quantization (if available)
      final inputTensor = _interpreter.getInputTensors().first;
      final outputTensor = _interpreter.getOutputTensors().first;

      _inputType = inputTensor.type;
      _outputType = outputTensor.type;

      // Read quantization params if exposed by this tflite_flutter version
      try {
        final outParams = outputTensor.params;
        _outputScale = outParams.scale;
        _outputZeroPoint = outParams.zeroPoint;
      } catch (_) {}

      // Load labels
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData
          .split('\n')
          .where((label) => label.trim().isNotEmpty)
          .map((label) => label.trim())
          .toList();

      _isLoaded = true;

      debugPrint('✅ Labels loaded: ${_labels.length}');

      // Debug information
      _printModelInfo();
    } catch (e, stackTrace) {
      _isLoaded = false;
      debugPrint('❌ Failed to load model: $e');
      debugPrint('📝 Stack trace: $stackTrace');
      rethrow;
    }
  }

  static void _printModelInfo() {
    try {
      final inputTensors = _interpreter.getInputTensors();
      final outputTensors = _interpreter.getOutputTensors();
      debugPrint('📊 Input tensors: ${inputTensors.length}');
      debugPrint('📈 Output tensors: ${outputTensors.length}');
    } catch (e) {
      debugPrint('⚠️ Could not print model info: $e');
    }
  }

  static List<dynamic> predict(List<dynamic> input) {
    if (!_isLoaded) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    try {
      debugPrint('🎯 Starting prediction...');

      // Prepare output buffer based on actual model output shape
      final outputTensor = _interpreter.getOutputTensors()[0];
      final output = _createOutputBuffer(outputTensor);

      debugPrint('🚀 Running inference...');
      _interpreter.run(input, output);
      debugPrint('✅ Inference completed successfully');

      return output;
    } catch (e, stackTrace) {
      debugPrint('❌ Prediction failed: $e');
      debugPrint('📝 Stack trace: $stackTrace');
      throw Exception('Prediction failed: $e');
    }
  }

  static Future<Map<String, dynamic>> preprocessImage(
      Uint8List imageBytes) async {
    try {
      debugPrint('🖼️ Starting image preprocessing...');
      debugPrint('📊 Image bytes: ${imageBytes.length}');

      final isQuantizedInput = _isQuantizedInput;

      // Offload decode + resize + quality + tensor build ke isolate untuk hindari jank
      final payload = _PreprocessPayload(
        bytes: imageBytes,
        isQuantized: isQuantizedInput,
        inputSize: inputSize,
        numChannels: numChannels,
      );

      final result = await compute(_preprocessOnIsolate, payload);
      return result;
    } catch (e) {
      debugPrint('⚠️ Image preprocessing failed: $e');
      rethrow;
    }
  }

  // Process prediction results
  static Map<String, dynamic> processResults(List<dynamic> output) {
    try {
      debugPrint('📊 Processing results...');

      if (output.isEmpty) {
        throw Exception('Empty output from model');
      }

      final predictions = output[0];

      debugPrint('📈 Predictions length: ${predictions.length}');

      // Validate predictions
      if (predictions.isEmpty) {
        throw Exception('No predictions received from model');
      }

      // Convert raw logits to probabilities (softmax) dengan temperature scaling
      const double temperature = 2.0; // naikan untuk melembutkan probabilitas
      final rawPredictions = List<double>.generate(predictions.length, (i) {
        try {
          return _dequantizeOutput(predictions[i]);
        } catch (e) {
          debugPrint('⚠️ Error processing prediction $i: $e');
          return 0.0;
        }
      });

      final probabilities = _softmax(
        rawPredictions,
        temperature: temperature,
      );

      // Find highest probability
      double maxConfidence = 0.0;
      double secondConfidence = 0.0;
      int maxIndex = 0;

      for (int i = 0; i < probabilities.length; i++) {
        final confidence = probabilities[i];
        if (confidence > maxConfidence) {
          secondConfidence = maxConfidence;
          maxConfidence = confidence;
          maxIndex = i;
        } else if (confidence > secondConfidence) {
          secondConfidence = confidence;
        }
      }

      // Convert to percentage and clamp to valid range
      final confidencePercent = (maxConfidence * 100).clamp(0.0, 100.0);
      final margin =
          ((maxConfidence - secondConfidence) * 100).clamp(0.0, 100.0);

      // Get prediction label
      String prediction =
          _labels.length > maxIndex ? _labels[maxIndex] : 'Unknown';

      debugPrint(
          '🎯 Raw prediction: $prediction, Confidence: $maxConfidence, Margin: $margin');

      // Gunakan confidence apa adanya (tanpa penolakan) agar hasil mentah ditampilkan
      final adjustedConfidence = confidencePercent;

      // Determine risk level
      final riskInfo = _determineRiskLevel(prediction, adjustedConfidence);

      // Log full distribution to debug overconfident outputs
      final allPreds = _getAllPredictions(probabilities);
      debugPrint('🔎 All predictions: $allPreds');

      debugPrint(
        '✅ Final prediction: $prediction (${confidencePercent.toStringAsFixed(2)}%)',
      );

      return {
        'prediction': prediction,
        'confidence': adjustedConfidence,
        'riskLevel': riskInfo['level'],
        'description': riskInfo['description'],
        'allPredictions': allPreds,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ Result processing failed: $e');
      debugPrint('📝 Stack trace: $stackTrace');

      // Return safe default result
      return {
        'prediction': 'Error',
        'confidence': 0.0,
        'riskLevel': 'UNKNOWN',
        'description':
            'Terjadi kesalahan dalam memproses hasil. Silakan coba lagi.',
        'allPredictions': [],
      };
    }
  }

  static Map<String, dynamic> _determineRiskLevel(
    String prediction,
    double confidence,
  ) {
    try {
      final predictionLower = prediction.toLowerCase();

      if (predictionLower.contains('normal') ||
          predictionLower.contains('healthy')) {
        return {
          'level': 'RENDAH',
          'description':
              'Tidak terdeteksi tanda-tanda katarak. Mata dalam kondisi sehat.',
        };
      } else if (predictionLower.contains('immature') ||
          predictionLower.contains('early') ||
          predictionLower.contains('stage1')) {
        return {
          'level': 'SEDANG',
          'description':
              'Terdeteksi katarak tahap awal. Disarankan untuk konsultasi dengan dokter mata.',
        };
      } else if (predictionLower.contains('mature') ||
          predictionLower.contains('advanced') ||
          predictionLower.contains('stage2') ||
          predictionLower.contains('stage3')) {
        return {
          'level': 'TINGGI',
          'description':
              'Terdeteksi katarak tahap lanjut. Segera konsultasi dengan dokter mata.',
        };
      } else {
        return {
          'level': 'TIDAK DIKETAHUI',
          'description':
              'Hasil analisis tidak dapat diklasifikasikan. Silakan coba dengan gambar yang lebih jelas.',
        };
      }
    } catch (e) {
      debugPrint('⚠️ Risk level determination failed: $e');
      return {
        'level': 'ERROR',
        'description': 'Terjadi kesalahan dalam analisis.',
      };
    }
  }

  static List<Map<String, dynamic>> _getAllPredictions(
    List<double> probabilities,
  ) {
    final results = <Map<String, dynamic>>[];

    try {
      for (int i = 0; i < probabilities.length; i++) {
        if (i < _labels.length) {
          results.add({
            'label': _labels[i],
            'confidence': (probabilities[i] * 100).clamp(0.0, 100.0),
          });
        }
      }

      // Sort by confidence descending
      results.sort((a, b) => b['confidence'].compareTo(a['confidence']));
    } catch (e) {
      debugPrint('⚠️ Getting all predictions failed: $e');
    }

    return results;
  }

  // Convert quantized outputs back to float logits/probabilities
  static double _dequantizeOutput(dynamic value) {
    if (_isQuantizedOutput) {
      final numVal = value as num;
      return (numVal - _outputZeroPoint) * _outputScale;
    }
    return (value as num).toDouble();
  }

  static List<dynamic> _createOutputBuffer(Tensor outputTensor) {
    final shape = outputTensor.shape;
    return _isQuantizedType(outputTensor.type)
        ? List.generate(shape[0], (_) => List<int>.filled(shape[1], 0))
        : List.generate(shape[0], (_) => List<double>.filled(shape[1], 0.0));
  }

  static List<double> _softmax(
    List<double> logits, {
    double temperature = 1.0,
  }) {
    if (logits.isEmpty) return const [];
    final maxLogit = logits.reduce(math.max);
    final expValues = logits
        .map((p) => math.exp(((p - maxLogit) / temperature)))
        .toList(growable: false);
    final sumExp = expValues.fold<double>(0.0, (s, e) => s + e);
    final safeSum = sumExp == 0 ? double.minPositive : sumExp;
    return expValues
        .map((e) => (e / safeSum).clamp(0.0, 1.0))
        .toList(growable: false);
  }

  // Utility method to get model input shape
  // (removed unused getInputShape/getOutputShape)

  static void dispose() {
    if (_isLoaded) {
      try {
        _interpreter.close();
        _isLoaded = false;
        debugPrint('🔚 Model disposed successfully');
      } catch (e) {
        debugPrint('⚠️ Error disposing model: $e');
      }
    }
  }
}

// Payload untuk isolate preprocessing
class _PreprocessPayload {
  final Uint8List bytes;
  final bool isQuantized;
  final int inputSize;
  final int numChannels;

  _PreprocessPayload({
    required this.bytes,
    required this.isQuantized,
    required this.inputSize,
    required this.numChannels,
  });
}

// Isolate function: decode, resize, quality, dan tensor build
Future<Map<String, dynamic>> _preprocessOnIsolate(
    _PreprocessPayload payload) async {
  // Normalization constants must match training (ImageNet-style mean/std)
  const mean = [0.485, 0.456, 0.406];
  const std = [0.229, 0.224, 0.225];

  final image = img.decodeImage(payload.bytes);
  if (image == null) {
    throw Exception('Failed to decode image');
  }

  final resizedImage = img.copyResize(
    image,
    width: payload.inputSize,
    height: payload.inputSize,
  );

  final input = List.generate(
    1,
    (_) => List.generate(
      payload.inputSize,
      (_) => List.generate(
        payload.inputSize,
        (_) => payload.isQuantized
            ? List.filled(payload.numChannels, 0)
            : List.filled(payload.numChannels, 0.0),
      ),
    ),
  );

  for (var y = 0; y < payload.inputSize; y++) {
    for (var x = 0; x < payload.inputSize; x++) {
      final pixel = resizedImage.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      if (payload.isQuantized) {
        input[0][y][x][0] = r;
        input[0][y][x][1] = g;
        input[0][y][x][2] = b;
      } else {
        input[0][y][x][0] = (r / 255.0 - mean[0]) / std[0];
        input[0][y][x][1] = (g / 255.0 - mean[1]) / std[1];
        input[0][y][x][2] = (b / 255.0 - mean[2]) / std[2];
      }
    }
  }

  final quality = _analyzeQuality(resizedImage);

  return {
    'input': input,
    'quality': quality,
  };
}

Map<String, dynamic> _analyzeQuality(img.Image image) {
  final luminance = <double>[];
  double brightnessSum = 0;

  double rSum = 0;
  double gSum = 0;
  double bSum = 0;
  double rSqSum = 0;
  double gSqSum = 0;
  double bSqSum = 0;
  int pixelCount = 0;

  double centerSum = 0;
  int centerCount = 0;
  double outerSum = 0;
  int outerCount = 0;

  final cx1 = (image.width * 0.3).round();
  final cx2 = (image.width * 0.7).round();
  final cy1 = (image.height * 0.3).round();
  final cy2 = (image.height * 0.7).round();

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      luminance.add(lum);
      brightnessSum += lum;

      rSum += p.r;
      gSum += p.g;
      bSum += p.b;
      rSqSum += p.r * p.r;
      gSqSum += p.g * p.g;
      bSqSum += p.b * p.b;
      pixelCount++;

      final isCenter = x >= cx1 && x <= cx2 && y >= cy1 && y <= cy2;
      if (isCenter) {
        centerSum += lum;
        centerCount++;
      } else {
        outerSum += lum;
        outerCount++;
      }
    }
  }

  final brightness = luminance.isEmpty ? 0 : brightnessSum / luminance.length;
  final centerBrightness = centerCount == 0 ? 0 : centerSum / centerCount;
  final outerBrightness = outerCount == 0 ? 0 : outerSum / outerCount;
  final eyeContrast = (outerBrightness - centerBrightness).toDouble();

  final rMean = pixelCount == 0 ? 0 : rSum / pixelCount;
  final gMean = pixelCount == 0 ? 0 : gSum / pixelCount;
  final bMean = pixelCount == 0 ? 0 : bSum / pixelCount;

  final rVar = pixelCount == 0 ? 0 : (rSqSum / pixelCount) - (rMean * rMean);
  final gVar = pixelCount == 0 ? 0 : (gSqSum / pixelCount) - (gMean * gMean);
  final bVar = pixelCount == 0 ? 0 : (bSqSum / pixelCount) - (bMean * bMean);
  final colorStd =
      math.sqrt(math.max(0, (rVar + gVar + bVar) / 3.0)).toDouble();

  // Variance of Laplacian untuk deteksi blur sederhana
  final laplacianValues = <double>[];
  for (var y = 1; y < image.height - 1; y++) {
    for (var x = 1; x < image.width - 1; x++) {
      final c = _luma(image.getPixel(x, y));
      final l = _luma(image.getPixel(x, y - 1));
      final r = _luma(image.getPixel(x + 1, y));
      final t = _luma(image.getPixel(x - 1, y));
      final btm = _luma(image.getPixel(x, y + 1));
      final lap = 4 * c - l - r - t - btm;
      laplacianValues.add(lap);
    }
  }

  double blurVariance = 0.0;
  double edgeDensity = 0.0;
  if (laplacianValues.isNotEmpty) {
    final meanLap =
        laplacianValues.reduce((a, b) => a + b) / laplacianValues.length;
    final variance = laplacianValues
            .map((v) => math.pow(v - meanLap, 2))
            .reduce((a, b) => a + b) /
        laplacianValues.length;
    blurVariance = variance.toDouble();

    // Proporsi edge kuat (deteksi teks kasar)
    const edgeThreshold = 20.0;
    final strongEdges =
        laplacianValues.where((v) => v.abs() > edgeThreshold).length;
    edgeDensity = strongEdges / laplacianValues.length;
  }

  // Thresholds bisa disesuaikan
  const blurThreshold = 60.0; // makin kecil makin blur
  const darkThreshold = 60.0;
  const brightThreshold = 200.0;
  const eyeContrastMin = 12.0; // lebih ketat untuk non-eye
  const textEdgeDensityMin = 0.22;
  const lowColorStdMax = 18.0;

  final isBlurred = blurVariance < blurThreshold;
  final isDark = brightness < darkThreshold;
  final isTooBright = brightness > brightThreshold;
  final looksLikeText =
      edgeDensity > textEdgeDensityMin && colorStd < lowColorStdMax;
  final isNonEye = eyeContrast < eyeContrastMin ||
      looksLikeText ||
      (brightness > 210 && colorStd < 14.0);

  String qualityLabel = 'Baik';
  if (isNonEye) {
    qualityLabel = 'Bukan mata';
  } else if (isBlurred) {
    qualityLabel = 'Buram';
  } else if (isDark) {
    qualityLabel = 'Terlalu gelap';
  } else if (isTooBright) {
    qualityLabel = 'Terlalu terang';
  }

  return {
    'blurVariance': blurVariance,
    'brightness': brightness,
    'centerBrightness': centerBrightness,
    'outerBrightness': outerBrightness,
    'eyeContrast': eyeContrast,
    'colorStd': colorStd,
    'edgeDensity': edgeDensity,
    'isBlurred': isBlurred,
    'isDark': isDark,
    'isTooBright': isTooBright,
    'isNonEye': isNonEye,
    'qualityLabel': qualityLabel,
  };
}

double _luma(img.Pixel pixel) {
  return 0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b;
}
