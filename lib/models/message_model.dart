import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final DateTime timestamp;
  final bool isRead;
  final String messageType;
  final String? replyToMessageId;
  final String? replyToText;
  final bool isEdited;
  final DateTime? editedAt;
  final List<String> reactions;
  final bool isDeleted;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    required this.timestamp,
    this.isRead = false,
    this.messageType = 'text',
    this.replyToMessageId,
    this.replyToText,
    this.isEdited = false,
    this.editedAt,
    this.reactions = const [],
    this.isDeleted = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['imageUrl'],
      fileUrl: map['fileUrl'],
      fileName: map['fileName'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      messageType: map['messageType'] ?? 'text',
      replyToMessageId: map['replyToMessageId'],
      replyToText: map['replyToText'],
      isEdited: map['isEdited'] ?? false,
      editedAt: map['editedAt'] != null ? (map['editedAt'] as Timestamp).toDate() : null,
      reactions: List<String>.from(map['reactions'] ?? []),
      isDeleted: map['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'messageType': messageType,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'isEdited': isEdited,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'reactions': reactions,
      'isDeleted': isDeleted,
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    DateTime? timestamp,
    bool? isRead,
    String? messageType,
    String? replyToMessageId,
    String? replyToText,
    bool? isEdited,
    DateTime? editedAt,
    List<String>? reactions,
    bool? isDeleted,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      messageType: messageType ?? this.messageType,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      reactions: reactions ?? this.reactions,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
