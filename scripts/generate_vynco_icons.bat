@echo off
echo 🎨 Generating Vynco Logo and App Icons...
echo.

echo 📱 Step 1: Generating logo images...
dart run scripts/generate_vynco_logo.dart

echo.
echo 📱 Step 2: Generating app icons...
flutter pub run flutter_launcher_icons

echo.
echo ✅ Vynco logo and app icons generated successfully!
echo.
echo 📝 Next steps:
echo    1. The logo has been generated in assets/icons/
echo    2. App icons have been generated for Android and iOS
echo    3. Rebuild your app to see the new logo
echo.

pause

