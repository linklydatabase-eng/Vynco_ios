@echo off
echo 🎨 Vynco App Icon Generator
echo.

echo 📱 Step 1: Opening logo generator...
echo Please follow these steps:
echo 1. Open the HTML file that just opened in your browser
echo 2. Right-click on the logo and save it as "vynco_logo.png"
echo 3. Place it in the assets/icons/ directory
echo 4. Press any key when ready to continue...
pause

echo.
echo 📱 Step 2: Generating app icons...
flutter pub run flutter_launcher_icons

echo.
echo ✅ App icons generated successfully!
echo.
echo 🔄 To see the changes:
echo    1. Stop your app if it's running
echo    2. Run: flutter clean
echo    3. Run: flutter pub get
echo    4. Run your app again
echo.
echo The Flutter logo should now be replaced with your Vynco logo!
echo.
pause
