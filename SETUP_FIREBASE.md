# Firebase Setup Guide for Expensify

## Quick Setup (Recommended)

### Option 1: Using FlutterFire CLI (Easiest)

1. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. Run configuration:
   ```bash
   flutterfire configure
   ```
   
   This will:
   - Detect your Firebase projects
   - Generate `firebase_options.dart` automatically
   - Configure Android and iOS

### Option 2: Manual Setup

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `expensify` (or your choice)
4. Disable Google Analytics (optional)
5. Click **"Create project"**

## Step 2: Enable Authentication

1. In Firebase Console, click **"Authentication"** in left menu
2. Click **"Get started"**
3. Go to **"Sign-in method"** tab
4. Click **"Email/Password"**
5. Enable **"Email/Password"** and click **"Save"**

## Step 3: Register Android App

1. In Firebase Console, click the **Android icon** (or "Add app")
2. Register app:
   - **Android package name**: `com.expensify.expensify`
   - **App nickname**: Expensify Android (optional)
   - **Debug signing certificate**: Leave blank for now
3. Click **"Register app"**
4. Download `google-services.json`
5. Place it in: `android/app/google-services.json`

## Step 4: Register iOS App

1. In Firebase Console, click the **iOS icon** (or "Add app")
2. Register app:
   - **iOS bundle ID**: `com.expensify.expensify`
   - **App nickname**: Expensify iOS (optional)
3. Click **"Register app"**
4. Download `GoogleService-Info.plist`
5. Place it in: `ios/Runner/GoogleService-Info.plist`

## Step 5: Configure firebase_options.dart

1. In Firebase Console, go to **Project Settings** (gear icon)
2. Scroll to **"Your apps"** section
3. Copy the configuration values for each platform
4. Update `lib/firebase_options.dart` with your actual values

Or use FlutterFire CLI (recommended):
```bash
flutterfire configure
```

## Step 6: Install Dependencies

```bash
flutter pub get
```

## Step 7: Test Firebase

Run the app:
```bash
flutter run
```

Try signing up with a new account - it should create a user in Firebase Console under Authentication > Users.

## Troubleshooting

### Android Issues

- **Build error**: Make sure `google-services.json` is in `android/app/` folder
- **Plugin error**: Run `flutter clean` then `flutter pub get`

### iOS Issues

- **Missing file**: Make sure `GoogleService-Info.plist` is added to Xcode project
- **Build error**: Open `ios/Runner.xcworkspace` (not .xcodeproj) in Xcode

### Firebase Not Initializing

- Check console logs for specific errors
- Verify `firebase_options.dart` has correct values
- App will work with local auth if Firebase fails

## Notes

- The app gracefully handles Firebase initialization errors
- If Firebase is not configured, authentication uses SharedPreferences
- Once Firebase is set up, all auth data syncs to Firebase cloud
