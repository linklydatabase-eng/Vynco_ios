# Apple Sign-In Setup Guide for Vynco App

This guide explains how to set up Apple Sign-In authentication for your Flutter app with Firebase.

## Overview

Apple Sign-In allows users to authenticate using their Apple ID. It's available on iOS 13+ and macOS 10.15+. This implementation integrates with Firebase Authentication.

---

## Step 1: Set Up Apple Developer Account

### Prerequisites:
- Apple Developer Account (paid membership required: $99/year)
- Xcode installed on macOS
- Your app's Bundle Identifier: `com.vynco.app`

### Get Your Team ID:
1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Click **Membership** in the top menu
3. Note your **Team ID** (format: 10 characters like `ABC123XYZ0`)
4. You'll need this for configuration

---

## Step 2: Configure Sign in with Apple Capability in Xcode

### On macOS:

1. Open your iOS project in Xcode:
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. Select the **Runner** project in the left sidebar
3. Select the **Runner** target
4. Go to **Signing & Capabilities** tab
5. Click **+ Capability** button
6. Search for and select **Sign in with Apple**
7. Xcode will automatically add the capability

### Verify the Configuration:
- Check that `Runner.entitlements` now contains:
  ```xml
  <key>com.apple.developer.applesignin</key>
  <array>
    <string>Default</string>
  </array>
  ```

---

## Step 3: Create a Service ID in Apple Developer Portal

Service IDs are used for OAuth authentication on web platforms.

### Steps:

1. Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list)
2. Click **Identifiers** > **+** button
3. Select **Service IDs** → **Continue**
4. Enter:
   - **Description**: `Vynco App Sign In Service`
   - **Identifier**: `com.vynco.app.service` (must be unique)
5. Check the checkbox for **Sign in with Apple**
6. Click **Configure** next to "Sign in with Apple"
7. Under **Primary App ID**, select your main app ID (`com.vynco.app`)
8. For **Web URLs**, add your Firebase redirect URL:
   ```
   https://vynco-auth.firebaseapp.com/__/auth/handler
   ```
   (Replace `vynco-auth` with your actual Firebase project ID)
9. Click **Save**
10. Click **Continue** → **Register** → **Done**

---

## Step 4: Configure Firebase for Apple Sign-In

### 4.1 Enable Apple Sign-In in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`vynco-auth` or your project name)
3. In the left menu, go to **Authentication** → **Sign-in method**
4. Click **Add new provider** → **Apple**
5. Click **Enable**
6. You'll see the following fields to fill:

### 4.2 Fill in Apple Provider Details

You need to provide:

- **Services ID**: `com.vynco.app.service` (from Step 3)
- **Team ID**: Your 10-character Apple Team ID (from Step 1)
- **Key ID**: Private key identifier (from Step 4.3)
- **Private Key**: The actual private key file content (from Step 4.3)

### 4.3 Generate and Upload Private Key

1. Go to [Keys in Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list)
2. Click the **+** button to create a new key
3. Select **Sign in with Apple** checkbox
4. Click **Configure**
5. Select your primary App ID (`com.vynco.app`)
6. Click **Save**
7. Click **Continue** → **Register**
8. **Download** the key file (save as `AuthKey_XXXXXXXXXX.p8`)
   - Note the **Key ID** shown on the page (10-character alphanumeric)

### 4.4 Add Key to Firebase

In Firebase Console (Step 4.1 continued):

1. Open the downloaded `.p8` file with a text editor
2. Copy the entire contents (including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`)
3. Paste into the **Private Key** field in Firebase
4. Enter your **Team ID**
5. Enter the **Key ID** from the downloaded file name or the portal
6. Click **Save**

---

## Step 5: Update Flutter Code Configuration

### Update AuthService.dart

In your `lib/services/auth_service.dart`, you need to update the Apple Sign-In configuration with your Team ID:

```dart
final appleCredential = await SignInWithApple.getAppleIDCredential(
  scopes: [
    AppleIDSignInScopes.email,
    AppleIDSignInScopes.fullName,
  ],
  webAuthenticationOptions: WebAuthenticationOptions(
    clientId: 'com.vynco.app',
    teamId: 'ABC123XYZ0', // ← Replace with your Team ID from Step 1
    redirectUri: Uri.parse('https://vynco-auth.firebaseapp.com/__/auth/handler'), // ← Update with your Firebase project
    state: 'state',
  ),
);
```

**Important:** Replace:
- `ABC123XYZ0` with your actual Apple Team ID
- `vynco-auth` with your actual Firebase project ID

### Current Status:
The code is already prepared in `lib/services/auth_service.dart`. Just update the Team ID and Firebase project ID in the `signInWithApple()` method.

---

## Step 6: Update iOS Runner Configuration

### Update Runner.entitlements (if needed)

If Xcode didn't automatically add it, manually add to `ios/Runner/Runner.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- ... other entitlements ... -->
    <key>com.apple.developer.applesignin</key>
    <array>
        <string>Default</string>
    </array>
</dict>
</plist>
```

---

## Step 7: Testing

### Test on iOS Device:

1. Connect an iOS device (iOS 13+)
2. Run the app:
   ```bash
   flutter run -d <device-id>
   ```
3. Navigate to the Sign-In screen
4. Tap **"Continue with Apple ID"** button
5. Authenticate with your Apple ID
6. User should be created in Firebase if new, or signed in if existing

### Test on iOS Simulator:

Apple Sign-In works on iOS 13+ simulators, but requires:
- Signed in Apple ID in Simulator Settings
- Valid Apple Developer Account

---

## Step 8: Troubleshooting

### Common Issues and Solutions:

#### 1. **"Apple Sign-In is not available"**
- Ensure iOS target is 13.0+
- Check that capability is enabled in Xcode

#### 2. **"Invalid Service ID"**
- Verify Service ID matches Firebase configuration
- Ensure Service ID is registered in Apple Developer Portal

#### 3. **"Team ID mismatch"**
- Double-check Team ID in Flutter code matches Apple Developer Account
- Verify same Team ID in Firebase Console

#### 4. **"Redirect URI mismatch"**
- Ensure redirect URL in Apple Developer Portal matches Firebase:
  ```
  https://YOUR-PROJECT.firebaseapp.com/__/auth/handler
  ```
- Check spelling and protocol (https, not http)

#### 5. **"Unable to exchange credential"**
- Verify Private Key is properly added to Firebase Console
- Check that Key ID matches the one from Apple
- Ensure the .p8 file content was copied completely

#### 6. **"Firebase project not found"**
- Verify your Firebase project is accessible
- Check internet connection
- Try clearing app cache and signing in again

---

## Step 9: Verify Firebase User Creation

After successfully signing in with Apple:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Authentication** → **Users**
4. You should see a new user with provider **Apple**
5. The user's UID will be the Apple ID identifier

---

## Additional Notes

### Privacy Considerations:
- Apple's Sign in with Apple provides privacy by default
- Users can hide their email address
- Your app receives a unique identifier per app (not shared across apps)
- Handle email privacy by storing what Apple provides

### User Data Handling:
```dart
// Full Name (only available on first sign-in)
final givenName = appleCredential.givenName; // e.g., "John"
final familyName = appleCredential.familyName; // e.g., "Doe"

// Email (may be hidden/private)
final email = appleCredential.email; // e.g., "user@privaterelay.appleid.com"

// User ID (always available)
final userId = userCredential.user!.uid;
```

### References:
- [Apple Sign in with Apple Documentation](https://developer.apple.com/sign-in-with-apple/)
- [Firebase Apple Authentication](https://firebase.google.com/docs/auth/ios/apple)
- [sign_in_with_apple Package](https://pub.dev/packages/sign_in_with_apple)

---

## Implementation Summary

Your app already has:
✅ `sign_in_with_apple` package installed
✅ `signInWithApple()` method in `AuthService`
✅ **"Continue with Apple ID"** button in login screen
✅ Proper error handling and user creation in Firestore

**What you need to do:**
1. Complete Apple Developer setup (Steps 1-3)
2. Create Service ID (Step 3)
3. Generate Private Key and add to Firebase (Step 4)
4. Update Team ID in code (Step 5)
5. Enable Apple Sign-In in Firebase (Step 4.1)
6. Test on iOS device (Step 7)

---

**Last Updated:** January 27, 2026
**App Package:** com.vynco.app
**Platform:** iOS 13+, macOS 10.15+
