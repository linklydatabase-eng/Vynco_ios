# Play Store Release Guide for Linkly

This guide provides step-by-step instructions to prepare and release your Flutter app on Google Play Store, including how to create an .aab file and update versions in the future.

---

## 📋 Prerequisites

1. **Google Play Console Account** - You need a Google Play Developer account ($25 one-time fee)
2. **Flutter SDK** - Make sure Flutter is properly installed
3. **Java JDK** - Required for keystore creation (JDK 11 or later)
4. **Android Studio** (optional but recommended)

---

## 🔐 Step 1: Create a Release Keystore

You need to create a signing key to sign your app for release. **KEEP THIS KEY SAFE - YOU CANNOT RECOVER IT IF LOST!**

### 1.1 Create the Keystore File

Run this command in your terminal (replace the placeholders with your info):

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Windows PowerShell:**
```powershell
keytool -genkey -v -keystore %USERPROFILE%\upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**What you'll be asked:**
- **Password**: Choose a strong password (save it securely!)
- **First and last name**: Your name or company name
- **Organizational unit**: Your department (optional)
- **Organization**: Your company name (optional)
- **City**: Your city
- **State/Province**: Your state/province
- **Country code**: Two-letter country code (e.g., US, IN, GB)

**Important Notes:**
- Remember the keystore password and alias password
- Store the keystore file in a secure location
- You'll need this keystore for ALL future updates

---

## 📝 Step 2: Create key.properties File

Create a file named `key.properties` in the `android/` folder with the following content:

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=<path-to-your-keystore-file>
```

**Example for Windows:**
```properties
storePassword=YourStrongPassword123
keyPassword=YourStrongPassword123
keyAlias=upload
storeFile=C:\\Users\\YourUsername\\upload-keystore.jks
```

**Security Note:** 
- Add `key.properties` to `.gitignore` to prevent committing sensitive data
- Never commit the keystore file to version control

---

## ⚙️ Step 3: Configure Signing in build.gradle.kts

Update `android/app/build.gradle.kts` to use the keystore for release builds.

**Replace the `android { }` block** with:

```kotlin
android {
    namespace = "com.example.linkly"
    compileSdk = 36
    ndkVersion = "27.0.12077973"
    
    // Load keystore properties
    val keystorePropertiesFile = rootProject.file("key.properties")
    val keystoreProperties = java.util.Properties()
    if (keystorePropertiesFile.exists()) {
        keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Update applicationId to your desired package name
        applicationId = "com.example.linkly"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

---

## 📦 Step 4: Update Application ID (Important!)

Change the `applicationId` in `build.gradle.kts` from `com.example.linkly` to your unique package name.

**Recommended format:** `com.yourcompany.linkly` or `com.yourname.linkly`

Example:
```kotlin
applicationId = "com.linkly.app"
```

**Note:** Once published, you CANNOT change the application ID. Choose wisely!

---

## 🏷️ Step 5: Configure App Information

### 5.1 Update App Name and Icon

- **App Name**: Update in `android/app/src/main/AndroidManifest.xml`:
  ```xml
  android:label="Vynco"
  ```

- **App Icon**: Make sure your app icon is properly configured (already set in pubspec.yaml)

### 5.2 Update Version Information

In `pubspec.yaml`, the version format is: `version: <version-name>+<version-code>`

- **version-name**: User-visible version (e.g., 1.0.0)
- **version-code**: Integer that must increase with each release (e.g., 1, 2, 3...)

**Current:** `version: 1.0.0+1`

**For future updates:**
- Minor update: `1.0.1+2`
- Major update: `1.1.0+3`
- Breaking change: `2.0.0+4`

---

## 🏗️ Step 6: Build the Release .aab File

Build the Android App Bundle (.aab) file using Flutter:

```bash
flutter build appbundle --release
```

**Windows PowerShell:**
```powershell
flutter build appbundle --release
```

**Output Location:**
The .aab file will be generated at:
```
build/app/outputs/bundle/release/app-release.aab
```

**Build Time:** This may take 5-10 minutes for the first build.

---

## 📤 Step 7: Upload to Google Play Console

### 7.1 Create App in Play Console

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **"Create app"**
3. Fill in:
   - **App name**: Linkly
   - **Default language**: Your language
   - **App or game**: App
   - **Free or paid**: Choose appropriate
   - **Privacy policy**: Required URL
4. Accept terms and create

### 7.2 Set Up App Content

1. Navigate to **"Production"** (or **"Internal testing"** for testing first)
2. Complete required sections:
   - **App access**: All or restricted
   - **Ads**: Yes/No
   - **Content rating**: Complete questionnaire
   - **Target audience**: Select appropriate age group
   - **Data safety**: Fill privacy practices

### 7.3 Upload AAB File

1. Go to **"Production"** → **"Create new release"**
2. Upload your `app-release.aab` file
3. Fill in **Release name** (e.g., "1.0.0") and **Release notes**
4. Click **"Save"** and then **"Review release"**

### 7.4 Review and Publish

1. Review all information
2. Click **"Start rollout to Production"**
3. Wait for Google review (typically 1-7 days for new apps)

---

## 🔄 Future Version Updates

### Step 1: Update Version Numbers

**In `pubspec.yaml`:**

```yaml
version: 1.0.1+2  # Increment version name and version code
```

**Version Code Rules:**
- Must be an integer
- Must be greater than the previous version
- Cannot decrease
- Each update needs a new version code (even minor fixes)

**Version Name Rules:**
- Can be any string (typically semantic versioning: X.Y.Z)
- Should increase for new features or fixes

### Step 2: Build New AAB

```bash
flutter build appbundle --release
```

### Step 3: Upload to Play Console

1. Go to **Production** → **Create new release**
2. Upload the new `app-release.aab`
3. Add **Release notes** describing changes
4. Save and review
5. Rollout to Production

**Important:** Always increment the version code in `pubspec.yaml` before building!

---

## ✅ Checklist Before Release

- [ ] Keystore created and securely stored
- [ ] `key.properties` file created (and added to `.gitignore`)
- [ ] Signing configured in `build.gradle.kts`
- [ ] Application ID updated (unique package name)
- [ ] App name updated in AndroidManifest.xml
- [ ] Version numbers set correctly in `pubspec.yaml`
- [ ] App icon properly configured
- [ ] All permissions declared in AndroidManifest.xml
- [ ] Privacy policy URL ready (required by Google)
- [ ] Tested app thoroughly on real devices
- [ ] AAB file built successfully
- [ ] All Play Console sections completed

---

## 🛠️ Troubleshooting

### Build Errors

**Error: "key.properties not found"**
- Make sure `key.properties` is in the `android/` folder
- Check file path in `key.properties` is correct

**Error: "Keystore was tampered with, or password was incorrect"**
- Double-check passwords in `key.properties`
- Verify keystore file path is correct

**Error: "versionCode must be greater than previous version"**
- Increment the version code in `pubspec.yaml`

### Upload Errors

**Error: "You uploaded an APK/AAB that is signed with a different certificate"**
- You must use the same keystore for all updates
- Never lose or recreate the keystore

---

## 📚 Additional Resources

- [Flutter Build and Release Documentation](https://docs.flutter.dev/deployment/android)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer/)
- [App Signing Best Practices](https://developer.android.com/studio/publish/app-signing)

---

## 🔒 Security Best Practices

1. **Never commit `key.properties` or keystore files to Git**
2. **Add to `.gitignore`:**
   ```
   android/key.properties
   *.jks
   *.keystore
   ```
3. **Store keystore backup in secure location** (encrypted cloud storage, safe deposit box)
4. **Document keystore location and passwords** (store separately from code)
5. **Consider using Google Play App Signing** (allows key recovery)

---

## 📝 Version Update Examples

### Bug Fix Release
```yaml
# Before: version: 1.0.0+1
version: 1.0.1+2
```

### Feature Update
```yaml
# Before: version: 1.0.1+2
version: 1.1.0+3
```

### Major Release
```yaml
# Before: version: 1.5.0+10
version: 2.0.0+11
```

### Emergency Hotfix
```yaml
# Before: version: 1.0.0+1
version: 1.0.1+2  # Even small fixes need version code increment
```

---

**Good luck with your Play Store release! 🚀**

