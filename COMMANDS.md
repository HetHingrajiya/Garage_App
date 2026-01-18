# 💻 AutoCare Pro - Command Reference Cheat Sheet

This file contains a list of common commands used for developing, testing, and deploying the AutoCare Pro application.

---

## 🚀 **Core Flutter Commands**

### **Run the App**
```bash
# Debug Mode (fastest, with Hot Reload)
flutter run

# Profile Mode (for performance testing, no Hot Reload)
flutter run --profile

# Release Mode (optimized, for final testing)
flutter run --release
```

### **Run on Specific Device**
```bash
# List available devices
flutter devices

# Run on specific device ID
flutter run -d <device_id>

# Run on Android Emulator
flutter run -d android

# Run on Chrome
flutter run -d chrome
```

---

## 🧹 **Maintenance & Cleanup**

### **Clean Build Cache**
*When in doubt, run this! Fixes most "weird" build errors.*
```bash
flutter clean
flutter pub get
```

### **Update Dependencies**
```bash
# Update all packages to latest compatible versions
flutter pub upgrade

# View outdated packages
flutter pub outdated
```

---

## 🧪 **Testing & Quality Assurance**

### **Run Tests**
```bash
# Run all unit and widget tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart
```

### **Static Code Analysis**
```bash
# Analyze code for errors and warnings
flutter analyze

# Analyze without checking pubspec setup
flutter analyze --no-pub
```

### **Fix Linting Issues**
```bash
# Automatically fix simple linting issues
dart fix --apply
```

---

## 🔥 **Firebase Commands**
*(Requires [Firebase CLI](https://firebase.google.com/docs/cli) installed)*

### **Login & Project Setup**
```bash
# Login to Firebase
firebase login

# List projects
firebase projects:list
```

### **Configure FlutterFire**
```bash
# Link your Flutter app to Firebase project
flutterfire configure
```

### **Deploy Firestore Rules**
```bash
# Deploy only security rules
firebase deploy --only firestore:rules
```

---

## 📦 **Building for Production**

### **Android (APK & Bundle)**
```bash
# Build APK (for direct installation)
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

### **iOS (IPA)**
```bash
# Build iOS archive (Mac only)
flutter build ios --release
```

### **Web**
```bash
# Build for web hosting
flutter build web --release
```

---

## 🛠️ **Troubleshooting Generator**
If you change models or Riverpod providers, you might need to re-run the code generator (build_runner):

```bash
# One-time build
dart run build_runner build --delete-conflicting-outputs

# Watch for changes (auto-rebuild)
dart run build_runner watch --delete-conflicting-outputs
```

---
*Keep this file handy for quick reference!* 🚀
