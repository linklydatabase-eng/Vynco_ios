import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/digital_card_themes.dart';

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String username;
  final String? profileImageUrl;
  final String? company;
  final String? position;
  final String? bio;
  final String? phoneNumber;
  final String accountType;
  final String phoneNumberPrivacy; // 'connections_only', 'private', 'custom'
  final List<String> allowedPhoneViewers; // List of user IDs who can see phone number when privacy is 'custom'
  final DateTime createdAt;
  final DateTime lastSeen;
  final bool isOnline;
  final String? fcmToken;
  final Map<String, String> socialLinks;
  final String digitalCardTheme;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.username,
    this.profileImageUrl,
    this.company,
    this.position,
    this.bio,
    this.phoneNumber,
    this.accountType = 'Public',
    this.phoneNumberPrivacy = 'connections_only',
    this.allowedPhoneViewers = const [],
    required this.createdAt,
    required this.lastSeen,
    this.isOnline = false,
    this.fcmToken,
    this.socialLinks = const {},
    this.digitalCardTheme = DigitalCardThemes.defaultThemeId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Safe timestamp conversion
    DateTime safeCreatedAt;
    final dynamic createdAt = map['createdAt'];
    if (createdAt is Timestamp) {
      safeCreatedAt = createdAt.toDate();
    } else if (createdAt is DateTime) {
      safeCreatedAt = createdAt;
    } else {
      safeCreatedAt = DateTime.now();
    }
    
    DateTime safeLastSeen;
    final dynamic lastSeen = map['lastSeen'];
    if (lastSeen is Timestamp) {
      safeLastSeen = lastSeen.toDate();
    } else if (lastSeen is DateTime) {
      safeLastSeen = lastSeen;
    } else {
      safeLastSeen = DateTime.now();
    }
    
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      username: map['username'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      company: map['company'],
      position: map['position'],
      bio: map['bio'],
      phoneNumber: map['phoneNumber'],
      accountType: map['accountType'] ?? 'Public',
      phoneNumberPrivacy: map['phoneNumberPrivacy'] ?? 'connections_only',
      allowedPhoneViewers: List<String>.from(map['allowedPhoneViewers'] ?? const []),
      createdAt: safeCreatedAt,
      lastSeen: safeLastSeen,
      isOnline: map['isOnline'] ?? false,
      fcmToken: map['fcmToken'],
      socialLinks: _parseSocialLinks(map['socialLinks']),
      digitalCardTheme: map['digitalCardTheme'] ?? DigitalCardThemes.defaultThemeId,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      username: data['username'] ?? '',
      profileImageUrl: data['profileImageUrl'],
      company: data['company'],
      position: data['position'],
      bio: data['bio'],
      phoneNumber: data['phoneNumber'],
      accountType: data['accountType'] ?? 'Public',
      phoneNumberPrivacy: data['phoneNumberPrivacy'] ?? 'connections_only',
      allowedPhoneViewers: List<String>.from(data['allowedPhoneViewers'] ?? const []),
      createdAt: data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : DateTime.now(),
      lastSeen: data['lastSeen'] != null ? (data['lastSeen'] as Timestamp).toDate() : DateTime.now(),
      isOnline: data['isOnline'] ?? false,
      fcmToken: data['fcmToken'],
      socialLinks: _parseSocialLinks(data['socialLinks']),
      digitalCardTheme: data['digitalCardTheme'] ?? DigitalCardThemes.defaultThemeId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'username': username,
      'profileImageUrl': profileImageUrl,
      'company': company,
      'position': position,
      'bio': bio,
      'phoneNumber': phoneNumber,
      'accountType': accountType,
      'phoneNumberPrivacy': phoneNumberPrivacy,
      'allowedPhoneViewers': allowedPhoneViewers,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastSeen': Timestamp.fromDate(lastSeen),
      'isOnline': isOnline,
      'fcmToken': fcmToken,
      'socialLinks': socialLinks,
      'digitalCardTheme': digitalCardTheme,
    };
  }

  static Map<String, String> _parseSocialLinks(dynamic socialLinksData) {
    if (socialLinksData == null) {
      return {};
    }
    
    try {
      if (socialLinksData is Map<String, dynamic>) {
        return socialLinksData.map((key, value) => MapEntry(key, value?.toString() ?? ''));
      } else if (socialLinksData is Map) {
        return socialLinksData.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
      } else {
        return {};
      }
    } catch (e) {
      debugPrint('Error parsing socialLinks: $e');
      return {};
    }
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? username,
    String? profileImageUrl,
    String? company,
    String? position,
    String? bio,
    String? phoneNumber,
    String? accountType,
    String? phoneNumberPrivacy,
    List<String>? allowedPhoneViewers,
    DateTime? createdAt,
    DateTime? lastSeen,
    bool? isOnline,
    String? fcmToken,
    Map<String, String>? socialLinks,
    String? digitalCardTheme,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      company: company ?? this.company,
      position: position ?? this.position,
      bio: bio ?? this.bio,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      accountType: accountType ?? this.accountType,
      phoneNumberPrivacy: phoneNumberPrivacy ?? this.phoneNumberPrivacy,
      allowedPhoneViewers: allowedPhoneViewers ?? this.allowedPhoneViewers,
      createdAt: createdAt ?? this.createdAt,
      lastSeen: lastSeen ?? this.lastSeen,
      isOnline: isOnline ?? this.isOnline,
      fcmToken: fcmToken ?? this.fcmToken,
      socialLinks: socialLinks ?? this.socialLinks,
      digitalCardTheme: digitalCardTheme ?? this.digitalCardTheme,
    );
  }
}
