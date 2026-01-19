import 'package:cloud_firestore/cloud_firestore.dart';

class StatusModel {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImageUrl;
  final String? text;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime expiresAt;
  final List<String> viewers;
  final bool isViewed;

  StatusModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userProfileImageUrl,
    this.text,
    this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
    this.viewers = const [],
    this.isViewed = false,
  });

  factory StatusModel.fromMap(Map<String, dynamic> map) {
    return StatusModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userProfileImageUrl: map['userProfileImageUrl'],
      text: map['text'],
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(hours: 24)),
      viewers: List<String>.from(map['viewers'] ?? []),
      isViewed: map['isViewed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfileImageUrl': userProfileImageUrl,
      'text': text,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'viewers': viewers,
      'isViewed': isViewed,
    };
  }

  StatusModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfileImageUrl,
    String? text,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? expiresAt,
    List<String>? viewers,
    bool? isViewed,
  }) {
    return StatusModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewers: viewers ?? this.viewers,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
