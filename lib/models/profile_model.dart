import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ProfileModel {
  final String userId;
  final String displayName;
  final String designation;
  final String company;
  final String? phone;
  final String? bio;
  final String? profileImageUrl;
  final Map<String, String> socialLinks;
  final String cardTheme;
  final bool isPublic;
  final bool locationSharing;
  final DateTime updatedAt;

  ProfileModel({
    required this.userId,
    required this.displayName,
    required this.designation,
    required this.company,
    this.phone,
    this.bio,
    this.profileImageUrl,
    this.socialLinks = const {},
    this.cardTheme = 'navy',
    this.isPublic = true,
    this.locationSharing = false,
    required this.updatedAt,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      designation: map['designation'] ?? '',
      company: map['company'] ?? '',
      phone: map['phone'],
      bio: map['bio'],
      profileImageUrl: map['profileImageUrl'],
      socialLinks: _parseSocialLinks(map['socialLinks']),
      cardTheme: map['cardTheme'] ?? 'navy',
      isPublic: map['isPublic'] ?? true,
      locationSharing: map['locationSharing'] ?? false,
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'designation': designation,
      'company': company,
      'phone': phone,
      'bio': bio,
      'profileImageUrl': profileImageUrl,
      'socialLinks': socialLinks,
      'cardTheme': cardTheme,
      'isPublic': isPublic,
      'locationSharing': locationSharing,
      'updatedAt': Timestamp.fromDate(updatedAt),
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

  ProfileModel copyWith({
    String? userId,
    String? displayName,
    String? designation,
    String? company,
    String? phone,
    String? bio,
    String? profileImageUrl,
    Map<String, String>? socialLinks,
    String? cardTheme,
    bool? isPublic,
    bool? locationSharing,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      designation: designation ?? this.designation,
      company: company ?? this.company,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      socialLinks: socialLinks ?? this.socialLinks,
      cardTheme: cardTheme ?? this.cardTheme,
      isPublic: isPublic ?? this.isPublic,
      locationSharing: locationSharing ?? this.locationSharing,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
