# Firebase Setup Guide for Vynco

This guide will help you set up Firebase for the Vynco Flutter application.

## 🔥 Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Enter project name: `linkly-app`
4. Enable Google Analytics (optional)
5. Choose your analytics account
6. Click "Create project"

## 🔧 Step 2: Configure Authentication

1. In Firebase Console, go to **Authentication**
2. Click "Get started"
3. Go to **Sign-in method** tab
4. Enable the following providers:
   - **Email/Password**: Enable
   - **Google**: Enable and configure

### Google Sign-in Setup:
1. Click on Google provider
2. Enable it
3. Add your project's support email
4. Save the configuration

## 🗄️ Step 3: Set up Firestore Database

1. Go to **Firestore Database**
2. Click "Create database"
3. Choose "Start in test mode" (for development)
4. Select a location close to your users
5. Click "Done"

### Firestore Security Rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Profiles are readable by authenticated users
    match /profiles/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Connections are readable by the user who owns them
    match /connections/{connectionId} {
      allow read, write: if request.auth != null && 
        (resource.data.userId == request.auth.uid || 
         request.auth.uid == resource.data.userId);
    }
    
    // Messages are readable by sender and receiver
    match /messages/{messageId} {
      allow read, write: if request.auth != null && 
        (resource.data.senderId == request.auth.uid || 
         resource.data.receiverId == request.auth.uid);
    }
  }
}
```

## 📁 Step 4: Set up Storage

1. Go to **Storage**
2. Click "Get started"
3. Choose "Start in test mode"
4. Select a location
5. Click "Done"

### Storage Security Rules:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## 📱 Step 5: Configure Cloud Messaging

1. Go to **Cloud Messaging**
2. No additional setup needed for basic functionality
3. For advanced features, configure:
   - Server key (in Project Settings > Cloud Messaging)
   - Sender ID

## 🔧 Step 6: Flutter Configuration

### Install FlutterFire CLI:
```bash
dart pub global activate flutterfire_cli
```

### Configure Firebase for your project:
```bash
flutterfire configure
```

This will:
1. Ask you to select your Firebase project
2. Choose platforms (Android, iOS, Web)
3. Generate `firebase_options.dart` file
4. Update platform-specific configuration files

### Manual Configuration (if needed):

#### Android Setup:
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/`
3. Add to `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

#### iOS Setup:
1. Download `GoogleService-Info.plist` from Firebase Console
2. Add to `ios/Runner/` in Xcode
3. Add to `ios/Runner.xcodeproj`

## 🧪 Step 7: Test Configuration

### Test Authentication:
```dart
// In your Flutter app
import 'package:firebase_auth/firebase_auth.dart';

// Test sign in
FirebaseAuth.instance.signInAnonymously();
```

### Test Firestore:
```dart
// In your Flutter app
import 'package:cloud_firestore/cloud_firestore.dart';

// Test write
FirebaseFirestore.instance.collection('test').add({'message': 'Hello World'});
```

## 🔒 Step 8: Security Configuration

### Update Firestore Rules (Production):
Replace test mode rules with production rules that include proper authentication checks.

### Update Storage Rules (Production):
Implement proper access controls for file uploads.

### Enable App Check (Optional):
1. Go to **App Check** in Firebase Console
2. Register your apps
3. Configure verification providers

## 📊 Step 9: Analytics Setup (Optional)

1. Go to **Analytics** in Firebase Console
2. Configure events you want to track
3. Set up conversion tracking
4. Configure audience definitions

## 🚀 Step 10: Deploy and Test

1. Run your Flutter app: `flutter run`
2. Test authentication flows
3. Test database operations
4. Test file uploads
5. Test push notifications

## 🔧 Troubleshooting

### Common Issues:

1. **Authentication not working**:
   - Check if providers are enabled in Firebase Console
   - Verify SHA-1 fingerprints for Android
   - Check bundle ID for iOS

2. **Firestore permission denied**:
   - Check security rules
   - Verify user authentication status
   - Check collection/document paths

3. **Storage upload failed**:
   - Check storage rules
   - Verify file size limits
   - Check network connectivity

4. **Push notifications not working**:
   - Check FCM configuration
   - Verify device token generation
   - Check notification permissions

## 📚 Additional Resources

- [Firebase Flutter Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)

---

**Note**: Remember to replace placeholder values in `firebase_options.dart` with your actual Firebase configuration after running `flutterfire configure`.
