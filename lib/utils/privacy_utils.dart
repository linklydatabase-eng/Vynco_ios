import '../models/user_model.dart';

class PrivacyUtils {
  /// Determines if personal information (email and phone) should be visible
  /// based on the user's account type and connection status
  static bool shouldShowPersonalInfo({
    required String accountType,
    required bool isConnected,
  }) {
    switch (accountType.toLowerCase()) {
      case 'public':
        // Public accounts: personal info visible to connections
        return isConnected;
      case 'private':
        // Private accounts: personal info never visible to connections
        return false;
      default:
        // Default to private behavior for safety
        return false;
    }
  }

  /// Gets the appropriate display text for personal information
  /// Returns the actual info if visible, or a placeholder if not
  static String getPersonalInfoDisplay({
    required String? personalInfo,
    required String accountType,
    required bool isConnected,
    String placeholder = 'Connect to view',
  }) {
    if (shouldShowPersonalInfo(
      accountType: accountType,
      isConnected: isConnected,
    )) {
      return personalInfo ?? '';
    } else {
      return placeholder;
    }
  }

  /// Gets the appropriate icon for personal information visibility
  static String getPersonalInfoIcon({
    required String accountType,
    required bool isConnected,
  }) {
    if (shouldShowPersonalInfo(
      accountType: accountType,
      isConnected: isConnected,
    )) {
      return 'visible';
    } else {
      return 'hidden';
    }
  }

  /// Determines if phone number should be visible based on privacy settings
  /// Returns true if the viewer can see the phone number
  static bool shouldShowPhoneNumber({
    required String phoneNumberPrivacy,
    required bool isConnected,
    required String viewerUserId,
    required String ownerUserId,
    required List<String> allowedPhoneViewers,
  }) {
    // Owner can always see their own phone number
    if (viewerUserId == ownerUserId) {
      return true;
    }

    switch (phoneNumberPrivacy) {
      case 'connections_only':
        // Phone number visible to all connections
        return isConnected;
      case 'private':
        // Phone number hidden from everyone except owner
        return false;
      case 'custom':
        // Phone number visible only to selected users
        return allowedPhoneViewers.contains(viewerUserId);
      default:
        // Default to private behavior for safety
        return false;
    }
  }

  /// Gets the appropriate display text for phone number
  /// Returns the actual phone number if visible, or a placeholder if not
  static String getPhoneNumberDisplay({
    required String? phoneNumber,
    required String phoneNumberPrivacy,
    required bool isConnected,
    required String viewerUserId,
    required String ownerUserId,
    required List<String> allowedPhoneViewers,
    String placeholder = 'Phone number hidden',
  }) {
    if (shouldShowPhoneNumber(
      phoneNumberPrivacy: phoneNumberPrivacy,
      isConnected: isConnected,
      viewerUserId: viewerUserId,
      ownerUserId: ownerUserId,
      allowedPhoneViewers: allowedPhoneViewers,
    )) {
      return phoneNumber ?? '';
    } else {
      return placeholder;
    }
  }
}
