# iOS Setup Guide for Vynco App

## Overview
Your Flutter code is **already configured for iOS**. You only need to configure Firebase Console to add the iOS app and download the configuration file.

## Step-by-Step Instructions

### 1. Add iOS App to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **linklly-9525b**
3. Click the **⚙️ Settings** icon (gear) → **Project settings**
4. Scroll down to **Your apps** section
5. Click **Add app** → Select **iOS** (Apple icon)

### 2. Register iOS App

Fill in the iOS app registration form:

- **iOS bundle ID**: `com.vynco.app`
  - This must match exactly with your Xcode project bundle identifier
- **App nickname** (optional): `Vynco iOS`
- **App Store ID** (optional): Leave blank for now

Click **Register app**

### 3. Download GoogleService-Info.plist

1. After registering, Firebase will show a **Download GoogleService-Info.plist** button
2. **Download** the file
3. **Important**: Do NOT add it to Xcode yet (we'll do it via Flutter)

### 4. Add GoogleService-Info.plist to Your Project

**Option A: Using FlutterFire CLI (Recommended)**
```bash
# If you haven't already, install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for iOS
flutterfire configure --platforms=ios
```

**Option B: Manual Installation**
1. Copy the downloaded `GoogleService-Info.plist` file
2. Place it in: `ios/Runner/GoogleService-Info.plist`
3. Open Xcode: `open ios/Runner.xcworkspace`
4. In Xcode, right-click on `Runner` folder → **Add Files to "Runner"**
5. Select `GoogleService-Info.plist`
6. Make sure **"Copy items if needed"** is checked
7. Make sure **"Add to targets: Runner"** is checked
8. Click **Add**

### 5. Verify Bundle Identifier in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** project in the left sidebar
3. Select **Runner** target
4. Go to **Signing & Capabilities** tab
5. Verify **Bundle Identifier** is: `com.vynco.app`
6. If different, change it to match Firebase configuration

### 6. Enable Required Capabilities

In Xcode, under **Signing & Capabilities**:
- **Push Notifications** (for Firebase Cloud Messaging)
- **Background Modes** → Enable:
  - ✅ Remote notifications
  - ✅ Background fetch

### 7. Update Firebase App ID (if needed)

After adding the iOS app, Firebase will generate a new iOS App ID. Check if it matches `firebase_options.dart`:

- Current iOS App ID in code: `1:651351206557:ios:7565ff2e20876787e7c274`
- If Firebase generates a different one, update `lib/firebase_options.dart`:

```dart
static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_API_KEY',
  appId: 'YOUR_NEW_IOS_APP_ID',  // Update this
  messagingSenderId: '651351206557',
  projectId: 'linklly-9525b',
  storageBucket: 'linklly-9525b.firebasestorage.app',
  iosBundleId: 'com.vynco.app',
);
```

### 8. Enable Firebase Services for iOS

In Firebase Console, make sure these are enabled:

1. **Authentication**
   - Go to **Authentication** → **Sign-in method**
   - Enable: Email/Password, Google Sign-In
   - For Google Sign-In, add iOS client ID (get from Google Cloud Console)

2. **Cloud Firestore**
   - Go to **Firestore Database**
   - Rules should already be configured

3. **Cloud Storage**
   - Go to **Storage**
   - Rules should already be configured

4. **Cloud Messaging (FCM)**
   - Go to **Cloud Messaging**
   - Upload APNs Authentication Key (for push notifications)
   - Or use APNs Certificate (older method)

### 9. Configure APNs for Push Notifications (Required for FCM)

To enable push notifications on iOS:

1. **Get APNs Key from Apple Developer:**
   - Go to [Apple Developer Portal](https://developer.apple.com/account/)
   - Navigate to **Certificates, Identifiers & Profiles**
   - Go to **Keys** → Create new key
   - Enable **Apple Push Notifications service (APNs)**
   - Download the `.p8` key file
   - Note the **Key ID** and **Team ID**

2. **Upload to Firebase:**
   - Go to Firebase Console → **Project Settings** → **Cloud Messaging**
   - Under **Apple app configuration**, click **Upload**
   - Upload the `.p8` file
   - Enter **Key ID** and **Team ID**

### 10. Test iOS Build

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Build for iOS (simulator)
flutter build ios --simulator

# Or run on iOS device/simulator
flutter run -d ios
```

## What's Already Configured ✅

- ✅ Firebase options in `lib/firebase_options.dart`
- ✅ Firebase initialization in `lib/main.dart`
- ✅ iOS permissions in `ios/Runner/Info.plist` (just updated)
- ✅ AppDelegate configuration
- ✅ All Flutter dependencies support iOS

## Common Issues & Solutions

### Issue: "FirebaseApp.configure() failed"
**Solution**: Make sure `GoogleService-Info.plist` is in `ios/Runner/` and added to Xcode project

### Issue: "No Firebase App '[DEFAULT]' has been created"
**Solution**: Verify `firebase_options.dart` has correct iOS configuration

### Issue: Push notifications not working
**Solution**: 
- Upload APNs key to Firebase Console
- Enable Push Notifications capability in Xcode
- Verify background modes are enabled

### Issue: Google Sign-In not working
**Solution**:
- Add iOS client ID to Firebase Authentication → Sign-in method → Google
- Get client ID from Google Cloud Console

### Issue: Bundle ID mismatch
**Solution**: Ensure Xcode bundle identifier matches Firebase: `com.vynco.app`

## Next Steps

1. ✅ Add iOS app to Firebase Console
2. ✅ Download and add `GoogleService-Info.plist`
3. ✅ Configure APNs for push notifications
4. ✅ Test the app on iOS simulator/device

## Summary

**You need to configure Firebase Console, NOT change your code.** The Flutter code is already iOS-ready. Just add the iOS app in Firebase and download the configuration file.

