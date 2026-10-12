import 'package:cloud_firestore/cloud_firestore.dart';

class ScanModel {
  final String id;
  final String disease;
  final double confidence;
  final String imageUrl;
  final DateTime timestamp;
  final String userId;

  ScanModel({
    required this.id,
    required this.disease,
    required this.confidence,
    required this.imageUrl,
    required this.timestamp,
    required this.userId,
  });

  factory ScanModel.fromMap(String id, Map<String, dynamic> map) {
    return ScanModel(
      id: id,
      disease: map['disease'] ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'] ?? '',
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      userId: map['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'disease': disease,
      'confidence': confidence,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': userId,
    };
  }
}