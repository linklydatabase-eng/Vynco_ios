import 'package:cloud_firestore/cloud_firestore.dart';

class ConnectionModel {
  final String id;
  final String userId;
  final String contactUserId;
  final String contactName;
  final String contactEmail;
  final String? contactPhone;
  final String? contactCompany;
  final String? connectionNote;
  final String? groupId;
  final String connectionMethod;
  final DateTime createdAt;
  final bool isNewConnection;

  ConnectionModel({
    required this.id,
    required this.userId,
    required this.contactUserId,
    required this.contactName,
    required this.contactEmail,
    this.contactPhone,
    this.contactCompany,
    this.connectionNote,
    this.groupId,
    required this.connectionMethod,
    required this.createdAt,
    this.isNewConnection = true,
  });

  factory ConnectionModel.fromMap(Map<String, dynamic> map) {
    DateTime safeCreatedAt;
    final dynamic created = map['createdAt'];
    if (created is Timestamp) {
      safeCreatedAt = created.toDate();
    } else if (created is DateTime) {
      safeCreatedAt = created;
    } else if (created is String) {
      // Attempt to parse ISO strings if present
      safeCreatedAt = DateTime.tryParse(created) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      // Fallback for legacy docs missing createdAt
      safeCreatedAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    String asString(dynamic v) => v is String ? v : (v?.toString() ?? '');

    return ConnectionModel(
      id: asString(map['id']),
      userId: asString(map['userId']),
      contactUserId: asString(
        map['contactUserId'] ?? map['contactUid'] ?? map['contact_id'] ?? map['contact'],
      ),
      contactName: asString(
        map['contactName'] ?? map['name'] ?? map['fullName'] ?? map['displayName'],
      ),
      contactEmail: asString(
        map['contactEmail'] ?? map['email'] ?? map['mail'],
      ),
      contactPhone: (map['contactPhone'] ?? map['phoneNumber'] ?? map['phone'] ?? map['mobile']) as String?,
      contactCompany: (map['contactCompany'] ?? map['company'] ?? map['organization'] ?? map['org']) as String?,
      connectionNote: map['connectionNote'] as String?,
      groupId: asString(map['groupId'] ?? map['groupID']),
      connectionMethod: asString(map['connectionMethod'] ?? map['method']),
      createdAt: safeCreatedAt,
      isNewConnection: map['isNewConnection'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'contactUserId': contactUserId,
      'contactName': contactName,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'contactCompany': contactCompany,
      'connectionNote': connectionNote,
      'groupId': groupId,
      'connectionMethod': connectionMethod,
      'createdAt': Timestamp.fromDate(createdAt),
      'isNewConnection': isNewConnection,
    };
  }

  ConnectionModel copyWith({
    String? id,
    String? userId,
    String? contactUserId,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    String? contactCompany,
    String? connectionNote,
    String? groupId,
    String? connectionMethod,
    DateTime? createdAt,
    bool? isNewConnection,
  }) {
    return ConnectionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contactUserId: contactUserId ?? this.contactUserId,
      contactName: contactName ?? this.contactName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      contactCompany: contactCompany ?? this.contactCompany,
      connectionNote: connectionNote ?? this.connectionNote,
      groupId: groupId ?? this.groupId,
      connectionMethod: connectionMethod ?? this.connectionMethod,
      createdAt: createdAt ?? this.createdAt,
      isNewConnection: isNewConnection ?? this.isNewConnection,
    );
  }
}
