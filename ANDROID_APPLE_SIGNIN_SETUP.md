# Apple Sign-In Setup Guide for Android (Vynco App)

This guide explains how to set up Apple Sign-In authentication for Android in your Flutter app with Firebase.

## Overview

Apple Sign-In on Android works through OAuth 2.0 using the Apple Service ID created in your Apple Developer account. Unlike iOS (which has native support), Android uses web-based authentication with `webAuthenticationOptions`.

---

## Prerequisites

- Apple Developer Account with paid membership ($99/year)
- Service ID already created in Apple Developer Portal (see main APPLE_SIGNIN_SETUP.md)
- Firebase Project configured for Apple Sign-In
- Your Firebase project ID: `vynco-3b5dd`

---

## Step 1: Configure webAuthenticationOptions in Code

The code has been updated in `lib/services/auth_service.dart` with the following configuration:

```dart
final appleCredential = await SignInWithApple.getAppleIDCredential(
  scopes: [],
  webAuthenticationOptions: WebAuthenticationOptions(
    clientId: 'com.vynco.app.service',  // Your Service ID
    redirectUrl: Uri.parse('https://vynco-3b5dd.firebaseapp.com/__/auth/handler'),
  ),
);
```

**Important:** Replace values if your Firebase project ID or Service ID differs.

---

## Step 2: Verify Service ID Configuration in Apple Developer Portal

Your Service ID must be properly configured for web authentication:

1. Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list)
2. Select **Identifiers** → Find your Service ID: `com.vynco.app.service`
3. Click on it to edit
4. Under **Sign in with Apple**, click **Configure**
5. Verify these settings:
   - **Primary App ID**: Should be set to `com.vynco.app` (your main app)
   - **Web URLs** section should contain:
     ```
     https://vynco-3b5dd.firebaseapp.com/__/auth/handler
     ```
   - **Return URLs** (if available) should also include the Firebase redirect URL
6. Save changes

---

## Step 3: Update Android Manifest (if needed)

Android 11+ requires explicit intent handling. Ensure your `android/app/src/main/AndroidManifest.xml` includes:

```xml
<queries>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <data android:scheme="https" />
    </intent>
</queries>
```

This allows the browser to handle the OAuth redirect.

---

## Step 4: Configure Firebase Authentication

### Enable Apple Sign-In Provider in Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **vynco-3b5dd**
3. Navigate to **Authentication** → **Sign-in method**
4. Click on **Apple** in the list
5. Enable it (toggle should be ON)
6. Enter your Service ID: `com.vynco.app.service`
7. Enter your Team ID (from your Apple Developer account - format: 10 characters like `ABC123XYZ0`)
8. Enter your Private Key ID and Private Key (see Step 5 below)
9. Click **Save**

---

## Step 5: Generate and Configure Apple Private Key

You need to create a Private Key for authentication:

### Generate Private Key in Apple Developer Portal:

1. Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/certificates/list)
2. Click **Keys** in the left sidebar
3. Click the **+** button to create a new key
4. **Key Name**: `Vynco Apple Sign In`
5. Under **Key Services**, check:
   - ✅ **Sign in with Apple**
6. Click **Configure**
7. Under **Primary App ID**, select: `com.vynco.app`
8. Click **Save**
9. Click **Continue**
10. Click **Register**
11. **Download** the key file (save it securely - you can only download once!)
12. The **Key ID** will be displayed - copy and save it

### Add Private Key to Firebase Console:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select **vynco-3b5dd** project
3. Navigate to **Authentication** → **Sign-in method** → **Apple**
4. In the Apple configuration:
   - **Team ID**: Your Apple Developer Team ID (10 characters)
   - **Key ID**: The Key ID from Step 12 above
   - **Private Key**: Open the downloaded `.p8` file in a text editor, copy the entire content, and paste it here
5. Click **Save**

---

## Step 6: Test Apple Sign-In on Android

### Testing Options:

#### Option A: Physical Android Device
1. Build and run the app on a physical Android device
2. Navigate to the login screen
3. Click "Continue with Apple ID"
4. You should be redirected to Apple's OAuth page
5. Sign in with your Apple ID
6. You'll be redirected back to the app

#### Option B: Android Emulator (Limited Support)
- Android emulators have limited browser support
- A physical device is recommended for testing

---

## Troubleshooting

### Error: "webAuthenticationOptions argument must be provided on Android"
**Fix**: This error should now be resolved as we've added the `webAuthenticationOptions` to the code.

### Error: "redirect_uri_mismatch"
**Cause**: The redirect URL in your code doesn't match the one in Apple Developer Portal
**Fix**: 
- Verify the redirect URL is exactly: `https://vynco-3b5dd.firebaseapp.com/__/auth/handler`
- Add it to both Service ID and Key configuration in Apple Developer Portal

### Error: "invalid_client"
**Cause**: Incorrect Service ID or missing Private Key configuration
**Fix**:
- Verify Service ID is: `com.vynco.app.service`
- Ensure Private Key is correctly entered in Firebase Console
- Check Team ID is correct

### Error: "access_denied"
**Cause**: User cancelled the authentication or Service ID is not properly configured
**Fix**:
- Verify Service ID is correctly configured in Apple Developer Portal
- Check that the Primary App ID is set to `com.vynco.app`
- Test with a different Apple ID

### Browser Not Opening
**Cause**: Missing Android Manifest configuration or incorrect redirect handling
**Fix**:
- Verify Android Manifest has the queries element
- Check that Chrome/Browser is the default handler
- Ensure device has internet connection

---

## Important Notes

1. **Service ID is required for Android**: Unlike iOS which uses native sign-in, Android requires a Service ID for web-based OAuth
2. **Private Key is sensitive**: Keep your private key secure and never commit it to version control
3. **Firebase Project ID**: Replace `vynco-3b5dd` with your actual Firebase project ID if it's different
4. **URL Scheme**: The redirect URL must use HTTPS and match exactly in all locations

---

## Firebase Security Rules for Apple Sign-In

No special security rules are needed for Apple Sign-In - it uses the same Firebase authentication mechanism as Google Sign-In.

Your existing Firestore rules will work with Apple Sign-In users. Users authenticated via Apple will have `auth.uid` set just like any other provider.

---

## Comparison: iOS vs Android

| Aspect | iOS | Android |
|--------|-----|---------|
| **Authentication Method** | Native (iOS 13+) | OAuth 2.0 (Web-based) |
| **Service ID Required** | No (uses app bundle ID) | Yes (com.vynco.app.service) |
| **webAuthenticationOptions** | Not used | Required |
| **Redirect URL** | Not needed | Required |
| **Browser Redirect** | No | Yes |

---

## Support & Resources

- Apple Documentation: https://developer.apple.com/documentation/sign_in_with_apple
- Flutter sign_in_with_apple package: https://pub.dev/packages/sign_in_with_apple
- Firebase Apple Authentication: https://firebase.google.com/docs/auth/ios/apple

---

## Next Steps

1. ✅ Code updated with `webAuthenticationOptions`
2. Verify Service ID configuration in Apple Developer Portal (Step 2)
3. Generate Private Key (Step 5)
4. Configure Firebase Console (Step 4)
5. Test on Android device (Step 6)

Once all steps are complete, Apple Sign-In will work identically on iOS and Android!
