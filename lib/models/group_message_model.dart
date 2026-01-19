import 'package:cloud_firestore/cloud_firestore.dart';

class GroupMessageModel {
  final String id;
  final String groupId;
  final String senderId;
  final String senderName;
  final String? senderProfileImageUrl;
  final String text;
  final String messageType;
  final DateTime timestamp;
  final bool isRead;
  final bool isEdited;
  final String? replyToMessageId;
  final String? replyToText;
  final List<String> reactions;
  final List<String> readBy;

  GroupMessageModel({
    required this.id,
    required this.groupId,
    required this.senderId,
    required this.senderName,
    this.senderProfileImageUrl,
    required this.text,
    this.messageType = 'text',
    required this.timestamp,
    this.isRead = false,
    this.isEdited = false,
    this.replyToMessageId,
    this.replyToText,
    this.reactions = const [],
    this.readBy = const [],
  });

  factory GroupMessageModel.fromMap(Map<String, dynamic> map) {
    return GroupMessageModel(
      id: map['id'] ?? '',
      groupId: map['groupId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      senderProfileImageUrl: map['senderProfileImageUrl'],
      text: map['text'] ?? '',
      messageType: map['messageType'] ?? 'text',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isRead: map['isRead'] ?? false,
      isEdited: map['isEdited'] ?? false,
      replyToMessageId: map['replyToMessageId'],
      replyToText: map['replyToText'],
      reactions: List<String>.from(map['reactions'] ?? []),
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }

  factory GroupMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMessageModel(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      senderProfileImageUrl: data['senderProfileImageUrl'],
      text: data['text'] ?? '',
      messageType: data['messageType'] ?? 'text',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] ?? false,
      isEdited: data['isEdited'] ?? false,
      replyToMessageId: data['replyToMessageId'],
      replyToText: data['replyToText'],
      reactions: List<String>.from(data['reactions'] ?? []),
      readBy: List<String>.from(data['readBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfileImageUrl': senderProfileImageUrl,
      'text': text,
      'messageType': messageType,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'isEdited': isEdited,
      'replyToMessageId': replyToMessageId,
      'replyToText': replyToText,
      'reactions': reactions,
      'readBy': readBy,
    };
  }

  GroupMessageModel copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? senderName,
    String? senderProfileImageUrl,
    String? text,
    String? messageType,
    DateTime? timestamp,
    bool? isRead,
    bool? isEdited,
    String? replyToMessageId,
    String? replyToText,
    List<String>? reactions,
    List<String>? readBy,
  }) {
    return GroupMessageModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderProfileImageUrl: senderProfileImageUrl ?? this.senderProfileImageUrl,
      text: text ?? this.text,
      messageType: messageType ?? this.messageType,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isEdited: isEdited ?? this.isEdited,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToText: replyToText ?? this.replyToText,
      reactions: reactions ?? this.reactions,
      readBy: readBy ?? this.readBy,
    );
  }
}
