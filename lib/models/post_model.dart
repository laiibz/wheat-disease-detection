import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhoto;
  final String caption;
  final String imageUrl;
  final DateTime timestamp;
  final List<String> likes;
  final int commentsCount;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhoto,
    required this.caption,
    required this.imageUrl,
    required this.timestamp,
    required this.likes,
    required this.commentsCount,
  });

  factory PostModel.fromMap(String id, Map<String, dynamic> map) {
    return PostModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      userPhoto: map['userPhoto'] ?? '',
      caption: map['caption'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: List<String>.from(map['likes'] ?? []),
      commentsCount: map['commentsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhoto': userPhoto,
      'caption': caption,
      'imageUrl': imageUrl,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': likes,
      'commentsCount': commentsCount,
    };
  }
}
