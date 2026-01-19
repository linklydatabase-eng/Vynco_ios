@echo off
echo 🎨 Generating Vynco App Icons...
echo.

echo 📱 Step 1: Creating Vynco logo...
dart run scripts/create_linkly_logo.dart

echo.
echo 📱 Step 2: Installing dependencies...
flutter pub get

echo.
echo 📱 Step 3: Generating app icons for all platforms...
flutter pub run flutter_launcher_icons

echo.
echo ✅ App icons generated successfully!
echo 📱 Your Vynco logo is now set as the app icon for Android, iOS, and Web.
echo.
echo 🔄 To see the changes:
echo    1. Stop your app if it's running
echo    2. Run: flutter clean
echo    3. Run: flutter pub get
echo    4. Run your app again
echo.
pause
