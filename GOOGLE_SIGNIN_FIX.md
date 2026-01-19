# Google Sign-In Fix Guide

## Issues Identified

### 1. **App ID Mismatch** ❌
- **Code has**: `1:651351206557:android:7565ff2e20876787e7c274`
- **Firebase Console has**: `1:651351206557:android:e46d57c1eba53e05e7c274`
- **Your google-services.json has**: `1:651351206557:android:e46d57c1eba53e05e7c274` (correct)

### 2. **Missing Android OAuth Client** ❌
Your `google-services.json` shows that `com.vynco.app` only has a **Web client** (`client_type: 3`), but it's **missing the Android OAuth client** (`client_type: 1`) with SHA certificate hash.

The `com.example.linkly` app has the proper Android OAuth client, but that's the wrong package name.

### 3. **SHA Certificates Not Linked to OAuth** ❌
Your Firebase Console shows SHA-1 and SHA-256 certificates, but they're not properly linked to the Google Sign-In OAuth client for `com.vynco.app`.

## Step-by-Step Fix

### Step 1: Update App ID in Code

Update `lib/firebase_options.dart`:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSyDi5Z3g1Mpt1y7KsPLHowmWmWwW73pnn9k',
  appId: '1:651351206557:android:e46d57c1eba53e05e7c274', // FIXED: Use correct App ID
  messagingSenderId: '651351206557',
  projectId: 'linklly-9525b',
  storageBucket: 'linklly-9525b.firebasestorage.app',
);
```

### Step 2: Configure Google Sign-In in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **linklly-9525b**
3. Go to **Authentication** → **Sign-in method**
4. Click on **Google** provider
5. Make sure it's **Enabled**
6. Click **Save**

### Step 3: Configure OAuth Client in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select project: **linklly-9525b**
3. Go to **APIs & Services** → **Credentials**
4. Find **OAuth 2.0 Client IDs**
5. Look for clients with package name `com.vynco.app`
6. If missing, you need to add SHA certificates to Firebase first

### Step 4: Add SHA Certificates to Firebase (CRITICAL)

**For Debug Build:**
```bash
# Get debug keystore SHA-1
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Get debug keystore SHA-256
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA256
```

**For Release Build:**
```bash
# Get release keystore SHA-1 (use your actual keystore path)
keytool -list -v -keystore android/app/myapp.keystore -alias your-key-alias

# Get release keystore SHA-256
keytool -list -v -keystore android/app/myapp.keystore -alias your-key-alias | grep SHA256
```

**Add to Firebase:**
1. Go to Firebase Console → **Project Settings** → **Your apps**
2. Select **Vynco** Android app (`com.vynco.app`)
3. Scroll to **SHA certificate fingerprints**
4. Click **Add fingerprint**
5. Add both **SHA-1** and **SHA-256** from above commands
6. Click **Save**

### Step 5: Download New google-services.json

After adding SHA certificates:
1. Firebase will automatically generate OAuth clients
2. Go to **Project Settings** → **Your apps** → **Vynco** Android app
3. Click **google-services.json** to download
4. Replace `android/app/google-services.json` with the new file

### Step 6: Verify OAuth Client in google-services.json

The new `google-services.json` should have an entry like this for `com.vynco.app`:

```json
{
  "client_info": {
    "mobilesdk_app_id": "1:651351206557:android:e46d57c1eba53e05e7c274",
    "android_client_info": {
      "package_name": "com.vynco.app"
    }
  },
  "oauth_client": [
    {
      "client_id": "651351206557-XXXXX.apps.googleusercontent.com",
      "client_type": 1,  // ← This is the Android client (MUST EXIST)
      "android_info": {
        "package_name": "com.vynco.app",
        "certificate_hash": "YOUR_SHA1_HASH"  // ← Must match your SHA-1
      }
    },
    {
      "client_id": "651351206557-XXXXX.apps.googleusercontent.com",
      "client_type": 3  // Web client
    }
  ]
}
```

### Step 7: Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter build apk --debug  # Test with debug first
# or
flutter build appbundle --release
```

## Quick Fix Summary

1. ✅ Update App ID in `firebase_options.dart` to match Firebase Console
2. ✅ Add SHA-1 and SHA-256 certificates to Firebase Console for `com.vynco.app`
3. ✅ Download new `google-services.json` from Firebase
4. ✅ Verify OAuth client exists in `google-services.json` for Android
5. ✅ Clean and rebuild the app

## Common Error Messages

- **"sign_in_failed"**: Missing or incorrect SHA certificate
- **"10:"**: Missing OAuth client ID in google-services.json
- **"DEVELOPER_ERROR"**: Package name mismatch or missing SHA

## Verification Checklist

- [ ] App ID in code matches Firebase Console
- [ ] SHA-1 and SHA-256 added to Firebase Console
- [ ] `google-services.json` has Android OAuth client (`client_type: 1`) for `com.vynco.app`
- [ ] Google Sign-In enabled in Firebase Authentication
- [ ] Package name is `com.vynco.app` everywhere

