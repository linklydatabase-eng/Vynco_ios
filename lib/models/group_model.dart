import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String color;
  final String createdBy;
  final String? imageUrl;
  final List<String> members;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? qrCode;
  final bool isPublic;
  final String? inviteCode;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.createdBy,
    this.imageUrl,
    required this.members,
    required this.createdAt,
    required this.updatedAt,
    this.qrCode,
    this.isPublic = false,
    this.inviteCode,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      color: map['color'] ?? '#3B82F6',
      createdBy: map['createdBy'] ?? '',
      imageUrl: map['imageUrl'],
      members: List<String>.from(map['members'] ?? []),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      qrCode: map['qrCode'],
      isPublic: map['isPublic'] ?? false,
      inviteCode: map['inviteCode'],
    );
  }

  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      color: data['color'] ?? '#3B82F6',
      createdBy: data['createdBy'] ?? '',
      imageUrl: data['imageUrl'],
      members: List<String>.from(data['members'] ?? []),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      qrCode: data['qrCode'],
      isPublic: data['isPublic'] ?? false,
      inviteCode: data['inviteCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'createdBy': createdBy,
      'imageUrl': imageUrl,
      'members': members,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'qrCode': qrCode,
      'isPublic': isPublic,
      'inviteCode': inviteCode,
    };
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? color,
    String? createdBy,
    String? imageUrl,
    List<String>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? qrCode,
    bool? isPublic,
    String? inviteCode,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdBy: createdBy ?? this.createdBy,
      imageUrl: imageUrl ?? this.imageUrl,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      qrCode: qrCode ?? this.qrCode,
      isPublic: isPublic ?? this.isPublic,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}
