import 'package:cloud_firestore/cloud_firestore.dart';

class HealthCard {
  final String id;
  final String userId;
  final String diseaseName;
  final double initialConfidence;
  final double initialDiseaseScore;
  final String initialSeverity;
  final String initialImageUrl;
  final GeoPoint location;
  final DateTime createdAt;
  final String treatmentVoiceNote; // Kept for legacy, but we'll use notesLog now
  final String status;
  final List<RecoveryCheckup> followUps;
  final List<NoteEntry> notesLog;

  HealthCard({
    required this.id,
    required this.userId,
    required this.diseaseName,
    required this.initialConfidence,
    required this.initialDiseaseScore,
    required this.initialSeverity,
    required this.initialImageUrl,
    required this.location,
    required this.createdAt,
    required this.treatmentVoiceNote,
    this.status = 'active',
    required this.followUps,
    required this.notesLog,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'diseaseName': diseaseName,
      'initialConfidence': initialConfidence,
      'initialDiseaseScore': initialDiseaseScore,
      'initialSeverity': initialSeverity,
      'initialImageUrl': initialImageUrl,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
      'treatmentVoiceNote': treatmentVoiceNote,
      'status': status,
      'followUps': followUps.map((e) => e.toMap()).toList(),
      'notesLog': notesLog.map((e) => e.toMap()).toList(),
    };
  }

  factory HealthCard.fromMap(String id, Map<String, dynamic> map) {
    return HealthCard(
      id: id,
      userId: map['userId'] ?? '',
      diseaseName: map['diseaseName'] ?? '',
      initialConfidence: (map['initialConfidence'] as num?)?.toDouble() ?? 0.0,
      initialDiseaseScore: (map['initialDiseaseScore'] as num?)?.toDouble() ?? 0.0,
      initialSeverity: map['initialSeverity'] ?? 'Active',
      initialImageUrl: map['initialImageUrl'] ?? '',
      location: map['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      treatmentVoiceNote: map['treatmentVoiceNote'] ?? '',
      status: map['status'] ?? 'active',
      followUps: (map['followUps'] as List? ?? [])
          .map((e) => RecoveryCheckup.fromMap(e))
          .toList(),
      notesLog: (map['notesLog'] as List? ?? [])
          .map((e) => NoteEntry.fromMap(e))
          .toList(),
    );
  }
}

class RecoveryCheckup {
  final DateTime timestamp;
  final String resultLabel;
  final double confidence;
  final double diseaseScore;
  final String severity;
  final String imageUrl;

  RecoveryCheckup({
    required this.timestamp,
    required this.resultLabel,
    required this.confidence,
    required this.diseaseScore,
    required this.severity,
    required this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
    'timestamp': Timestamp.fromDate(timestamp),
    'resultLabel': resultLabel,
    'confidence': confidence,
    'diseaseScore': diseaseScore,
    'severity': severity,
    'imageUrl': imageUrl,
  };

  factory RecoveryCheckup.fromMap(Map<String, dynamic> map) {
    return RecoveryCheckup(
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      resultLabel: map['resultLabel'] ?? '',
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      diseaseScore: (map['diseaseScore'] as num?)?.toDouble() ?? 0.0,
      severity: map['severity'] ?? 'Active',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}

class NoteEntry {
  final String text;
  final DateTime timestamp;

  NoteEntry({required this.text, required this.timestamp});

  Map<String, dynamic> toMap() => {
    'text': text,
    'timestamp': Timestamp.fromDate(timestamp),
  };

  factory NoteEntry.fromMap(Map<String, dynamic> map) {
    return NoteEntry(
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
