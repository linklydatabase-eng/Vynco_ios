import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionRequestModel {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderProfileImageUrl;
  final String receiverId;
  final String receiverName;
  final String? receiverProfileImageUrl;
  final String? message;
  final DateTime createdAt;
  final ConnectionRequestStatus status;
  final DateTime? respondedAt;
  final String? responseMessage;

  ConnectionRequestModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderProfileImageUrl,
    required this.receiverId,
    required this.receiverName,
    this.receiverProfileImageUrl,
    this.message,
    required this.createdAt,
    required this.status,
    this.respondedAt,
    this.responseMessage,
  });

  factory ConnectionRequestModel.fromMap(Map<String, dynamic> map) {
    return ConnectionRequestModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderProfileImageUrl: map['senderProfileImageUrl'],
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      receiverProfileImageUrl: map['receiverProfileImageUrl'],
      message: map['message'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: ConnectionRequestStatus.values.firstWhere(
        (e) => e.toString() == 'ConnectionRequestStatus.${map['status']}',
        orElse: () => ConnectionRequestStatus.pending,
      ),
      respondedAt: map['respondedAt'] != null 
          ? (map['respondedAt'] as Timestamp).toDate() 
          : null,
      responseMessage: map['responseMessage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfileImageUrl': senderProfileImageUrl,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'receiverProfileImageUrl': receiverProfileImageUrl,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.toString().split('.').last,
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'responseMessage': responseMessage,
    };
  }

  ConnectionRequestModel copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? senderProfileImageUrl,
    String? receiverId,
    String? receiverName,
    String? receiverProfileImageUrl,
    String? message,
    DateTime? createdAt,
    ConnectionRequestStatus? status,
    DateTime? respondedAt,
    String? responseMessage,
  }) {
    return ConnectionRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderProfileImageUrl: senderProfileImageUrl ?? this.senderProfileImageUrl,
      receiverId: receiverId ?? this.receiverId,
      receiverName: receiverName ?? this.receiverName,
      receiverProfileImageUrl: receiverProfileImageUrl ?? this.receiverProfileImageUrl,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      respondedAt: respondedAt ?? this.respondedAt,
      responseMessage: responseMessage ?? this.responseMessage,
    );
  }
}

enum ConnectionRequestStatus {
  pending,
  accepted,
  declined,
  cancelled,
}
