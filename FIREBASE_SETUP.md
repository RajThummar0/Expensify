# Firebase Setup Instructions

## 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or select an existing project
3. Follow the setup wizard

## 2. Enable Authentication

1. In Firebase Console, go to **Authentication**
2. Click **Get Started**
3. Enable **Email/Password** authentication
4. Click **Save**

## 3. Add Firebase to Flutter App

### Android Setup

1. In Firebase Console, click the Android icon
2. Register your app:
   - Package name: `com.expensify.expensify` (check `android/app/build.gradle` for actual package)
   - Download `google-services.json`
   - Place it in `android/app/google-services.json`
3. Update `android/build.gradle`:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```
4. Update `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

### iOS Setup

1. In Firebase Console, click the iOS icon
2. Register your app:
   - Bundle ID: `com.expensify.expensify` (check `ios/Runner.xcodeproj` for actual bundle)
   - Download `GoogleService-Info.plist`
   - Place it in `ios/Runner/GoogleService-Info.plist`
3. Open `ios/Runner.xcworkspace` in Xcode
4. Add `GoogleService-Info.plist` to Runner target

## 4. Install Dependencies

Run:
```bash
flutter pub get
```

## 5. Test Firebase Connection

The app will work even if Firebase is not configured (falls back to local auth).
To verify Firebase is working, check the console logs when signing up/logging in.

## Notes

- The app gracefully handles Firebase initialization errors
- If Firebase is not configured, authentication uses SharedPreferences (local only)
- Once Firebase is set up, all authentication will sync to Firebase
