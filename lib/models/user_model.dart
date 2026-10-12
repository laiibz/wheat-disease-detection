import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String photoUrl;
  final String provider;
  final String role; // 'admin' or 'user'
  final String status; // 'active', 'warned', 'suspended'
  final String? adminNote;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.provider,
    this.role = 'user',
    this.status = 'active',
    this.adminNote,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'provider': provider,
      'role': role,
      'status': status,
      'adminNote': adminNote,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      provider: map['provider'] ?? '',
      role: map['role'] ?? 'user',
      status: map['status'] ?? 'active',
      adminNote: map['adminNote'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
