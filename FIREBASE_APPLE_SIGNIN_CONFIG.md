# Firebase Configuration for Apple Sign-In (Android)

Complete Firebase setup required to enable Apple Sign-In on Android.

---

## Firebase Console Setup Steps

### 1. Enable Apple Sign-In Provider

**Location**: Firebase Console → Authentication → Sign-in method

1. Go to https://console.firebase.google.com
2. Select project: **vynco-3b5dd**
3. Click **Authentication** in left sidebar
4. Click **Sign-in method** tab
5. Locate **Apple** in the provider list
6. Click on **Apple** to expand configuration
7. Toggle **Enable** (switch should be ON)

### 2. Configure Apple Provider Settings

In the Apple Sign-In configuration panel, you'll need to fill:

```
┌─────────────────────────────────────┐
│ Apple Sign-In Configuration         │
├─────────────────────────────────────┤
│ ☑ Enable                             │
│                                     │
│ Service ID: [com.vynco.app.service] │
│ Team ID: [ABC123XYZ0]               │
│ Key ID: [XXXXXXXXXX]                │
│ Private Key: [-----BEGIN PRIVATE...] │
└─────────────────────────────────────┘
```

#### Field Explanations:

- **Service ID**: `com.vynco.app.service`
  - This is created in Apple Developer Portal
  - Must match the Service ID in your Xcode project
  - Used for OAuth authentication

- **Team ID**: Your Apple Developer Team ID (10 characters)
  - Find in: https://developer.apple.com/account → Membership
  - Format: Letters and numbers like `ABC123XYZ0`

- **Key ID**: Apple Private Key ID (10 characters)
  - Generated in Apple Developer Portal
  - Found in: Certificates, Identifiers & Profiles → Keys
  - Copy from the key details page

- **Private Key**: Full content of the .p8 file
  - Generated in Apple Developer Portal
  - Downloaded as a `.p8` file (only downloaded once!)
  - Full content includes:
    ```
    -----BEGIN PRIVATE KEY-----
    MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC...
    ...
    -----END PRIVATE KEY-----
    ```

### 3. Save Configuration

Click **Save** button to apply settings.

---

## Detailed Configuration Guide

### Step A: Get Team ID from Apple Developer Account

1. Go to https://developer.apple.com/account
2. Click **Membership** in top menu
3. Look for **Team ID** section
4. Copy your Team ID (10 characters)
5. Paste into Firebase Console

### Step B: Create/Verify Service ID

**Required**: Service ID must exist and be configured correctly

1. Go to https://developer.apple.com/account/resources/identifiers/list
2. Click **Identifiers**
3. In the filter dropdown (top-left), select **Service IDs**
4. Look for `com.vynco.app.service`
   - If not found, create it:
     1. Click **+** button
     2. Select **Service IDs**
     3. Enter Description: `Vynco Apple Sign In`
     4. Enter Identifier: `com.vynco.app.service`
     5. Click **Continue**
5. Click on `com.vynco.app.service` to configure
6. Check ✅ **Sign in with Apple**
7. Click **Configure**
8. Set:
   - **Primary App ID**: `com.vynco.app`
   - **Web URLs**: Add `https://vynco-3b5dd.firebaseapp.com/__/auth/handler`
9. Click **Save**

### Step C: Create Private Key

1. Go to https://developer.apple.com/account/resources/certificates/list
2. Click **Keys** in left sidebar
3. Click **+** button to create new key
4. Enter **Key Name**: `Vynco Apple Sign In`
5. Check ✅ **Sign in with Apple**
6. Click **Configure**
7. Under **Primary App ID**: Select `com.vynco.app`
8. Click **Save**
9. Click **Continue**
10. Click **Register**
11. Click **Download** (save the `.p8` file securely)
12. Note your **Key ID** (displayed on the page)

### Step D: Add Private Key to Firebase

1. Open the downloaded `.p8` file in a text editor
2. Copy the entire contents (including `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----`)
3. Go to Firebase Console → Authentication → Sign-in method → Apple
4. Paste the key content into the **Private Key** field
5. Click **Save**

---

## Firebase Redirect URL Configuration

The Firebase redirect URL is automatically configured as:
```
https://vynco-3b5dd.firebaseapp.com/__/auth/handler
```

**Must match in two places:**

1. **Apple Developer Portal** (Service ID configuration):
   - Service ID: `com.vynco.app.service`
   - Web URLs: Include the redirect URL

2. **Code** (lib/services/auth_service.dart):
   ```dart
   redirectUrl: Uri.parse('https://vynco-3b5dd.firebaseapp.com/__/auth/handler'),
   ```

If your Firebase project ID is different, replace `vynco-3b5dd` with your actual project ID.

---

## Firestore Database Configuration

No special Firestore configuration is needed for Apple Sign-In. Users will authenticate the same way as Google Sign-In users.

### User Document Structure (Auto-created):

When a user signs in with Apple, the following document is created in Firestore:

```
Collection: users
Document ID: {Firebase UID}

{
  "uid": "...",
  "email": "user@example.com",
  "fullName": "User Name",
  "profileImageUrl": null,
  "phoneNumberPrivacy": "connections_only",
  "allowedPhoneViewers": [],
  "socialLinks": {},
  "createdAt": Timestamp,
  "lastSeen": Timestamp,
  "isOnline": true
}
```

This is handled automatically by `auth_service.dart`'s `signInWithApple()` method.

### Firestore Security Rules:

Your existing rules work with Apple Sign-In. No changes needed. Users are identified by `auth.uid` regardless of authentication method:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      // Allow read for own document and admins
      allow read: if request.auth.uid == userId || request.auth.token.admin == true;
      
      // Allow write for own document
      allow write: if request.auth.uid == userId;
    }
  }
}
```

---

## Verification Checklist

Before testing Apple Sign-In on Android, verify:

- [ ] Service ID `com.vynco.app.service` exists in Apple Developer Portal
- [ ] Service ID has "Sign in with Apple" enabled and configured
- [ ] Service ID has Primary App ID set to `com.vynco.app`
- [ ] Redirect URL in Service ID: `https://vynco-3b5dd.firebaseapp.com/__/auth/handler`
- [ ] Private Key (.p8 file) downloaded from Apple Developer Portal
- [ ] Private Key ID copied and available
- [ ] Firebase Console → Authentication → Apple is enabled
- [ ] Firebase Console Apple config has all fields filled:
  - Service ID: `com.vynco.app.service`
  - Team ID: (your 10-character team ID)
  - Key ID: (from private key)
  - Private Key: (full .p8 content)
- [ ] Code in auth_service.dart has `webAuthenticationOptions` configured
- [ ] Firebase project ID matches in code and Firebase Console

---

## Testing Apple Sign-In

### Prerequisites:
- Physical Android device (emulator has limited browser support)
- Android app built with updated auth_service.dart
- All Firebase configuration steps completed

### Test Steps:

1. Run app on Android device: `flutter run`
2. Navigate to login screen
3. Tap "Continue with Apple ID" button
4. Browser should open with Apple sign-in page
5. Sign in with Apple ID
6. Redirected back to app
7. Should be logged in and redirected to home screen

### If It Doesn't Work:

1. Check logcat for errors: `flutter logs`
2. Verify all configuration steps above
3. Check Firebase Console logs: Authentication → Logs
4. Verify internet connection on device
5. Try clearing app data and rebuilding

---

## Troubleshooting Reference

| Error | Cause | Solution |
|-------|-------|----------|
| `redirect_uri_mismatch` | Wrong redirect URL | Match URL in Apple Portal and Firebase exactly |
| `invalid_client` | Missing/wrong Service ID | Verify Service ID is `com.vynco.app.service` |
| `invalid_grant` | Private Key issue | Re-download and update private key in Firebase |
| User not created in Firestore | Not an error - check code execution | Check debugPrint logs for success message |
| Browser not opening | Missing Android Manifest or browser issue | Check device Chrome/Browser is set as default |

---

## Summary of Changes

✅ **Code Changes**:
- Updated `lib/services/auth_service.dart`
- Added `webAuthenticationOptions` to `signInWithApple()` method

✅ **Required Actions**:
1. Create/verify Service ID in Apple Developer Portal
2. Create Private Key in Apple Developer Portal
3. Configure Firebase Console with Service ID, Team ID, Key ID, and Private Key
4. Test on Android device

Once complete, Apple Sign-In will work identically on iOS and Android!

---

## Support Resources

- Firebase Apple Authentication: https://firebase.google.com/docs/auth/ios/apple
- Apple Sign-In Documentation: https://developer.apple.com/documentation/sign_in_with_apple
- Flutter sign_in_with_apple Package: https://pub.dev/packages/sign_in_with_apple
