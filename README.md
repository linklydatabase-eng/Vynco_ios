# Vynco - Digital Business Card & Networking App

A comprehensive Flutter application for digital business cards and professional networking, built with Firebase backend.

## 🚀 Features

### Core Features
- **Digital Business Cards** - Create and customize your professional digital card
- **QR Code Networking** - Share profiles instantly via QR codes
- **Location-Based Discovery** - Find professionals nearby
- **Real-time Messaging** - Connect and communicate with your network
- **Status Stories** - Share updates with your professional network
- **Analytics Dashboard** - Track your networking activity

### Technical Features
- **Firebase Authentication** - Email/Password + Google Sign-in
- **Cloud Firestore** - Real-time database for all data
- **Firebase Storage** - Media file storage
- **Push Notifications** - Stay connected with FCM
- **Location Services** - GPS-based discovery
- **Camera Integration** - QR code scanning
- **Modern UI** - Material Design 3 with custom themes

## 📱 Screens Overview

### Core Screens (8 screens)
1. **Splash Screen** - App loading & branding
2. **Onboarding** - Welcome & feature introduction  
3. **Login/Register** - Authentication with email/Google
4. **Home Dashboard** - Main feed with status, stats, quick actions
5. **Profile Setup/Edit** - Digital business card creation
6. **Connections** - Manage your network
7. **Messages** - Chat with connections
8. **Settings** - App preferences & privacy

### Feature Screens (7 screens)
9. **QR Scanner** - Scan codes to connect
10. **People Around** - Location-based discovery
11. **Posts Feed** - Social networking posts
12. **Status Stories** - Instagram-like status updates
13. **Groups** - Organize connections
14. **Analytics** - Profile insights & stats
15. **Notifications** - Activity updates

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase project

### 1. Clone and Install Dependencies
```bash
git clone <repository-url>
cd linkly
flutter pub get
```

### 2. Firebase Setup

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project named "Vynco"
3. Enable Authentication, Firestore, Storage, and Cloud Messaging

#### Configure Firebase for Flutter
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
3. Run: `flutterfire configure`
4. Select your Firebase project and platforms (Android, iOS, Web)

#### Update Firebase Options
Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase configuration.

### 3. Platform-Specific Setup

#### Android Setup
1. Add Google Services plugin to `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

2. Add the plugin to `android/build.gradle`:
```gradle
classpath 'com.google.gms:google-services:4.3.15'
```

#### iOS Setup
1. Add GoogleService-Info.plist to `ios/Runner/`
2. Enable background modes in `ios/Runner/Info.plist`:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-fetch</string>
    <string>remote-notification</string>
</array>
```

### 4. Run the App
```bash
flutter run
```

## 🏗️ Project Structure

```
lib/
├── constants/          # App colors, themes, constants
├── models/            # Data models (User, Profile, Connection, etc.)
├── services/          # Firebase services (Auth, Firestore, Notifications)
├── screens/           # All app screens
│   ├── auth/         # Authentication screens
│   ├── home/         # Home dashboard
│   ├── profile/      # Profile management
│   ├── connections/  # Connections management
│   ├── messages/     # Messaging
│   ├── settings/    # Settings
│   └── ...          # Other feature screens
├── widgets/          # Reusable UI components
├── utils/            # Utility functions
└── main.dart         # App entry point
```

## 🔥 Firebase Services Used

### Authentication
- Email/Password authentication
- Google Sign-in integration
- User session management

### Firestore Database
- **Users Collection** - User profiles and settings
- **Profiles Collection** - Business card information
- **Connections Collection** - User connections
- **Messages Collection** - Chat messages
- **Posts Collection** - Social posts
- **Statuses Collection** - Status updates
- **Notifications Collection** - Push notifications

### Firebase Storage
- Profile images
- Post media files
- Status media
- QR code images

### Cloud Messaging
- Push notifications
- Real-time updates
- Background message handling

## 📦 Key Dependencies

```yaml
# Firebase
firebase_core: ^2.24.2
firebase_auth: ^4.15.3
cloud_firestore: ^4.13.6
firebase_storage: ^11.5.6
firebase_messaging: ^14.7.10

# UI & Navigation
go_router: ^12.1.3
provider: ^6.1.1

# Camera & Media
camera: ^0.10.5+5
image_picker: ^1.0.4
qr_code_scanner: ^1.0.1

# Location & Maps
geolocator: ^10.1.0
google_maps_flutter: ^2.5.0

# UI Components
cached_network_image: ^3.3.0
shimmer: ^3.0.0
lottie: ^2.7.0
```

## 🎨 Design System

### Color Palette
- **Primary**: Navy Blue (#1E3A8A)
- **Secondary**: Amber (#F59E0B)
- **Accent**: Emerald (#10B981)
- **Card Themes**: Navy, Platinum, Emerald, Amber, Rose, Indigo

### Typography
- **Font Family**: Inter
- **Weights**: Regular, Medium, SemiBold, Bold

### Components
- Custom text fields with validation
- Custom buttons with loading states
- Status stories bar (Instagram-like)
- Digital card preview
- Quick stats cards
- Recent connections list

## 🚀 Development Roadmap

### Phase 1 (Core MVP) ✅
- [x] Project setup and dependencies
- [x] Authentication system
- [x] Onboarding flow
- [x] Home dashboard
- [x] Basic navigation

### Phase 2 (Enhanced Features) 🔄
- [ ] Profile management
- [ ] Connections system
- [ ] Real-time messaging
- [ ] QR code scanner
- [ ] Location-based discovery

### Phase 3 (Advanced Features) 📋
- [ ] Social feed and posts
- [ ] Status stories
- [ ] Groups management
- [ ] Analytics dashboard
- [ ] Push notifications

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

---

**Built with ❤️ using Flutter & Firebase**