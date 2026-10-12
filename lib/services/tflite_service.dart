import 'dart:io';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class TFLiteService {
  // Singleton pattern to prevent multiple model loads
  static final TFLiteService _instance = TFLiteService._internal();
  factory TFLiteService() => _instance;
  TFLiteService._internal();

  Interpreter? _interpreter;
  List<String>? _labels;

  static const int    IMG_SIZE             = 300;
  static const double CONFIDENCE_THRESHOLD = 0.50;

  static const List<String> CLASS_NAMES = [
    'Aphid',
    'Black_Rust',
    'Fusarium',
    'Healthy',
    'Leaf_Blight',
    'Not_Wheat',
    'Smut',
    'Yellow_Rust',
  ];

  Future<void> loadModel() async {
    if (_interpreter != null) return;
    try {
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      _interpreter = await Interpreter.fromAsset('assets/models/wheat_v3_model.tflite');
      print("--- TFLite Model Loaded Successfully ---");
    } catch (e) {
      print("AI LOAD ERROR: $e");
      rethrow;
    }
  }

  static bool _looksLikeAPlant(img.Image image) {
    int plantPixels = 0;
    int totalPixels   = 0;
    int sampleStep    = 10; 

    for (int y = 0; y < image.height; y += sampleStep) {
      for (int x = 0; x < image.width; x += sampleStep) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        final isGreenish  = g > r * 1.1 && g > b * 1.1;
        final isBrownish  = r > 80 && g > 50 && b < 80 && r > b * 1.3;
        final isYellowish = r > 150 && g > 130 && b < 100;
        final isNotBlack  = (r + g + b) > 50;
        final isNotWhite  = (r + g + b) < 730;

        if ((isGreenish || isBrownish || isYellowish) && isNotBlack && isNotWhite) {
          plantPixels++;
        }
        totalPixels++;
      }
    }

    final plantRatio = plantPixels / totalPixels;
    return plantRatio > 0.10;
  }

  Future<Map<String, dynamic>> runInference(File imageFile) async {
    try {
      await loadModel();
      final bytes = await imageFile.readAsBytes();
      img.Image? original = img.decodeImage(bytes);
      if (original == null) throw Exception("Could not decode image.");
      original = img.bakeOrientation(original);
      
      final checkImage = img.copyResize(original, width: 100, height: 100);
      if (!_looksLikeAPlant(checkImage)) {
        return {
          "label": "Not_Wheat",
          "confidence": 0.99,
          "message": "This does not appear to be a plant.",
        };
      }

      List<img.Image> variants = [
        img.copyResize(original, width: IMG_SIZE, height: IMG_SIZE),
        img.copyResize(
          img.copyCrop(original, 
            x: (original.width * 0.1).toInt(), 
            y: (original.height * 0.1).toInt(), 
            width: (original.width * 0.8).toInt(), 
            height: (original.height * 0.8).toInt()
          ), 
          width: IMG_SIZE, height: IMG_SIZE
        ),
      ];

      List<double> avgScores = List.filled(CLASS_NAMES.length, 0.0);
      for (var variant in variants) {
        final scores = _runSingleInference(variant);
        for (int i = 0; i < scores.length; i++) {
          avgScores[i] += scores[i] / variants.length;
        }
      }

      double maxScore = avgScores[0];
      int maxIndex = 0;
      for (int i = 1; i < avgScores.length; i++) {
        if (avgScores[i] > maxScore) {
          maxScore = avgScores[i];
          maxIndex = i;
        }
      }

      final String label = (_labels != null && maxIndex < _labels!.length)
          ? _labels![maxIndex]
          : "Unknown";

      final notWheatIdx = CLASS_NAMES.indexOf('Not_Wheat');
      final notWheatScore = avgScores[notWheatIdx];
      if (notWheatScore > 0.45 && label != 'Not_Wheat') {
        return { "label": "Not_Wheat", "confidence": notWheatScore };
      }

      if (maxScore < CONFIDENCE_THRESHOLD) {
        return {"label": "Unknown", "confidence": maxScore};
      }

      return {"label": label, "confidence": maxScore};
    } catch (e) {
      print("INFERENCE ERROR: $e");
      return {"label": "Error", "confidence": 0.0};
    }
  }

  Future<Map<String, dynamic>> runInferenceForHealthCard(
      File imageFile, String targetDisease) async {
    try {
      await loadModel();
      final bytes = await imageFile.readAsBytes();
      img.Image? original = img.decodeImage(bytes);
      if (original == null) throw Exception("Invalid image.");
      original = img.bakeOrientation(original);
      img.Image resized = img.copyResize(original, width: IMG_SIZE, height: IMG_SIZE);

      final scores = _runSingleInference(resized);
      final diseaseIdx = CLASS_NAMES.indexOf(targetDisease);
      final diseaseScore = diseaseIdx >= 0 ? scores[diseaseIdx] : 0.0;

      String severity;
      if (diseaseScore > 0.80) {
        severity = "Severe";
      } else if (diseaseScore > 0.55) {
        severity = "Moderate";
      } else if (diseaseScore > 0.30) {
        severity = "Mild";
      } else {
        severity = "Minimal / Recovering";
      }

      double maxScore = scores[0];
      int maxIndex = 0;
      for (int i = 1; i < scores.length; i++) {
        if (scores[i] > maxScore) {
          maxScore = scores[i];
          maxIndex = i;
        }
      }

      return {
        "diseaseScore": diseaseScore,
        "severity": severity,
        "label": CLASS_NAMES[maxIndex],
        "confidence": maxScore,
      };
    } catch (e) {
      print("HEALTH CARD INFERENCE ERROR: $e");
      rethrow;
    }
  }

  List<double> _runSingleInference(img.Image resizedImage) {
    var input = Float32List(1 * IMG_SIZE * IMG_SIZE * 3);
    int buffer = 0;

    for (int y = 0; y < IMG_SIZE; y++) {
      for (int x = 0; x < IMG_SIZE; x++) {
        final pixel = resizedImage.getPixel(x, y);
        input[buffer++] = pixel.r.toDouble();
        input[buffer++] = pixel.g.toDouble();
        input[buffer++] = pixel.b.toDouble();
      }
    }

    final outputShape = _interpreter!.getOutputTensor(0).shape;
    var output = List.generate(outputShape[0], (_) => List.filled(outputShape[1], 0.0));
    _interpreter!.run(input.reshape([1, IMG_SIZE, IMG_SIZE, 3]), output);
    return output[0];
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}
