# Run Expensify on Real Android Device (USB)

## Prerequisites
- Flutter SDK installed
- Android device with **USB debugging enabled**
- USB cable connected
- ADB drivers (Windows) if needed

## Step 1: Enable USB Debugging
1. On your Android phone: **Settings → About phone** → Tap "Build number" 7 times
2. Go to **Settings → Developer options** → Enable **USB debugging**
3. Connect phone via USB
4. Accept "Allow USB debugging?" prompt on the phone

## Step 2: Verify Device
```bash
flutter devices
```
Confirm your Android device is listed.

## Step 3: Run on Device
```bash
# Debug build (faster iteration)
flutter run

# Release build (recommended for real-world testing)
flutter run --release
```

## Step 4: Grant Permissions When Prompted
- **Contacts** – Required when adding an expense and picking contacts to split with
- **Storage** – Required when exporting PDF to Downloads folder

If permission dialogs don't appear:
1. Go to **Settings → Apps → Expensify → Permissions**
2. Enable **Contacts** and **Storage** (or **Files and media** on newer Android)

## Troubleshooting

### "MissingPluginException" or app crashes
- Run `flutter clean && flutter pub get`
- Rebuild: `flutter run --release`

### Permissions not triggering
- Uninstall the app, then reinstall
- Check `android/app/src/main/AndroidManifest.xml` has READ_CONTACTS, WRITE_EXTERNAL_STORAGE, etc.

### PDF won't save
- Grant Storage permission when asked
- On Android 11+, you may need to allow "Manage all files" if saving to Downloads fails (fallback uses app documents folder)

### Contacts empty
- Grant Contacts permission
- Use **Open Settings** if permission was denied, then re-enable

## Key Files
- `android/app/src/main/AndroidManifest.xml` – Permissions
- `lib/services/permission_service.dart` – Runtime permission handling
- `lib/services/contact_service.dart` – Device contacts (mobile only)
- `lib/services/pdf_export_service.dart` – PDF save (mobile/desktop, not web)
