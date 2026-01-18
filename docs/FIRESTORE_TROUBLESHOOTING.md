# Firestore Connection Troubleshooting Guide

## Error: UNAVAILABLE - Unable to resolve host firestore.googleapis.com

### What This Means
This error indicates that your device/emulator cannot reach Google's Firestore servers. This is typically a **network connectivity issue**, not a code problem.

---

## Quick Fixes (Try These First)

### 1. Check Internet Connection
**On Physical Device:**
- Open a web browser and try visiting google.com
- Check if WiFi/mobile data is enabled
- Try switching between WiFi and mobile data

**On Android Emulator:**
- The emulator should use your computer's internet connection
- Check if your computer has internet access
- Try restarting the emulator

### 2. Restart the App
```bash
# Stop the app
# In your terminal, press: Shift + F5 (or stop button)

# Then restart
flutter run
```

### 3. Hot Reload
```bash
# In your terminal where the app is running, press:
r
```

---

## Common Causes & Solutions

### Cause 1: Emulator Network Issues

**Symptoms:**
- Works on physical device but not emulator
- Error: "Unable to resolve host"

**Solution:**
```bash
# 1. Close the emulator
# 2. Open Android Studio
# 3. Tools → AVD Manager
# 4. Click Edit (pencil icon) on your emulator
# 5. Show Advanced Settings
# 6. Network section → Set to "Bridged"
# 7. Save and restart emulator
```

**Alternative:**
```bash
# Restart emulator with DNS settings
# In terminal:
emulator -avd YOUR_AVD_NAME -dns-server 8.8.8.8
```

### Cause 2: Firewall/Antivirus Blocking

**Symptoms:**
- Works on some networks but not others
- Corporate/school network

**Solution:**
1. Temporarily disable firewall/antivirus
2. Try running the app again
3. If it works, add exception for:
   - `firestore.googleapis.com`
   - `*.googleapis.com`

### Cause 3: VPN/Proxy Issues

**Symptoms:**
- Using VPN or proxy
- Works without VPN

**Solution:**
- Disable VPN temporarily
- Or configure VPN to allow Google services

### Cause 4: Firebase Not Initialized

**Symptoms:**
- Error on app startup
- No internet connection error

**Solution:**
Check `main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Make sure this is present
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}
```

### Cause 5: Firestore Rules Blocking Access

**Symptoms:**
- Error: "PERMISSION_DENIED"
- Different error than "UNAVAILABLE"

**Solution:**
1. Open Firebase Console
2. Go to Firestore Database
3. Click "Rules" tab
4. For testing, use:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

---

## Advanced Troubleshooting

### Check Firestore Status
Visit: https://status.firebase.google.com/
- Verify all services are operational
- Check for ongoing incidents

### Test Network Connectivity

**On Windows:**
```bash
# Test if you can reach Google's servers
ping firestore.googleapis.com

# Test DNS resolution
nslookup firestore.googleapis.com
```

**Expected Output:**
```
Non-authoritative answer:
Name:    firestore.googleapis.com
Addresses:  142.250.xxx.xxx
```

### Check Flutter Doctor
```bash
flutter doctor -v
```
Look for any network-related issues.

### Clear Flutter Cache
```bash
flutter clean
flutter pub get
```

### Rebuild the App
```bash
# Full rebuild
flutter clean
flutter pub get
flutter run
```

---

## Testing the Fix

### 1. Verify Error UI Appears
1. Turn off internet on your device
2. Open the app
3. You should see:
   ```
   ┌─────────────────────────────┐
   │         ⚠️                  │
   │ Failed to load dashboard    │
   │ stats                       │
   │ Error: [details]            │
   │      [🔄 Retry]             │
   └─────────────────────────────┘
   ```

### 2. Test Retry Functionality
1. Turn internet back on
2. Tap the "Retry" button
3. Stats should load successfully

### 3. Test Pull-to-Refresh
1. With internet on
2. Pull down on the dashboard
3. Stats should refresh

---

## For Physical Device Testing

### Android Device
1. Enable Developer Options:
   - Settings → About Phone
   - Tap "Build Number" 7 times
2. Enable USB Debugging:
   - Settings → Developer Options
   - Enable "USB Debugging"
3. Connect via USB
4. Run: `flutter devices`
5. Run: `flutter run`

### iOS Device (Mac only)
1. Connect iPhone via USB
2. Trust the computer
3. Run: `flutter devices`
4. Run: `flutter run`

---

## Still Not Working?

### Check These:

1. **Firebase Project Setup**
   - Is `google-services.json` in `android/app/`?
   - Is `GoogleService-Info.plist` in `ios/Runner/`?
   - Are they from the correct Firebase project?

2. **Package Versions**
   ```bash
   flutter pub outdated
   ```
   Update Firebase packages if needed:
   ```bash
   flutter pub upgrade
   ```

3. **Android Permissions**
   Check `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
   ```

4. **Logs**
   ```bash
   # View detailed logs
   flutter run -v
   
   # Or filter for Firebase
   flutter logs | grep -i firebase
   ```

---

## Expected Behavior After Fix

### ✅ With Internet Connection
- Dashboard loads within 5 seconds
- Shows actual stats or 0 if no data
- Pull-to-refresh works

### ✅ Without Internet Connection
- Shows error card within 5 seconds
- Clear error message
- Retry button visible
- Can retry when connection restored

### ✅ Intermittent Connection
- Gracefully handles timeouts
- Shows partial data if some queries succeed
- Provides helpful error messages

---

## Contact Support

If none of these solutions work:

1. **Check Firebase Console**
   - Verify project is active
   - Check billing status (if applicable)
   - Review Firestore usage

2. **Review Error Logs**
   ```bash
   flutter logs > error_log.txt
   ```
   Share the log file for debugging

3. **Verify App Configuration**
   - Ensure all Firebase services are enabled
   - Check API keys are valid
   - Verify package names match

---

**Last Updated**: December 18, 2024  
**Issue**: Firestore UNAVAILABLE error  
**Status**: Troubleshooting guide
