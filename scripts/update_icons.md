# How to Replace Flutter Logo with Vynco Logo

## Current Situation
The app currently uses the default Flutter logo as the app icon. You want to replace it with the Vynco logo design that appears in the splash screen.

## Vynco Logo Design (from splash screen)
- **Background**: White rounded rectangle with shadow
- **Icon**: Link icon (Icons.link) in primary blue color
- **Primary Color**: #0175C2

## Steps to Replace Icons

### Option 1: Using Flutter Icon Generator (Recommended)

1. **Install flutter_launcher_icons package:**
   ```bash
   flutter pub add flutter_launcher_icons
   ```

2. **Create icon configuration in pubspec.yaml:**
   ```yaml
   flutter_launcher_icons:
     android: "launcher_icon"
     ios: true
     image_path: "assets/icons/vynco_logo.png"
     min_sdk_android: 21
     web:
       generate: true
       image_path: "assets/icons/vynco_logo.png"
       background_color: "#0175C2"
       theme_color: "#0175C2"
   ```

3. **Generate the icons:**
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

### Option 2: Manual Icon Creation

1. **Create the Vynco logo image:**
   - Use the same design as splash screen
   - White background with rounded corners
   - Blue link icon in the center
   - Save as PNG with transparent background

2. **Generate different sizes:**
   - 48x48, 72x72, 96x96, 144x144, 192x192 for Android
   - 192x192, 512x512 for Web
   - 1024x1024 for iOS

3. **Replace existing icon files:**
   - Android: `android/app/src/main/res/mipmap-*/ic_launcher.png`
   - Web: `web/icons/Icon-*.png`
   - iOS: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Option 3: Use Online Icon Generator

1. Create your Vynco logo design
2. Use online tools like:
   - https://appicon.co/
   - https://icon.kitchen/
   - https://makeappicon.com/

## Quick Implementation

If you want to use the existing splash screen design as the app icon, you can:

1. Take a screenshot of the splash screen logo
2. Crop it to a square
3. Use an online icon generator to create all required sizes
4. Replace the existing icon files

## Files to Update

- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`
- `web/icons/Icon-maskable-192.png`
- `web/icons/Icon-maskable-512.png`
