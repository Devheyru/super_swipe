# 🔐 Firebase Configuration Setup

**IMPORTANT**: Firebase configuration files are **NOT** included in this repository for security reasons.

---

## 📋 Required Files

You need to obtain these files from the Firebase Console:

1. **iOS**: `ios/Runner/GoogleService-Info.plist`
2. **Android**: `android/app/google-services.json`
3. **Flutter**: `lib/firebase_options.dart` (generated)

---

## 🚀 Setup Instructions

### Step 1: Access Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **super_swipe** (or create a new one)

---

### Step 2: Download iOS Configuration

1. In Firebase Console, click ⚙️ Settings → Project Settings
2. Scroll to "Your apps" section
3. Select your **iOS app**
4. Click **"Download GoogleService-Info.plist"**
5. Place file at: `ios/Runner/GoogleService-Info.plist`

---

### Step 3: Download Android Configuration

1. In same project settings
2. Select your **Android app**
3. Click **"Download google-services.json"**
4. Place file at: `android/app/google-services.json`

---

### Step 4: Generate Firebase Options (Flutter)

Run the FlutterFire CLI to generate `firebase_options.dart`:

```bash
# Install FlutterFire CLI (if not installed)
dart pub global activate flutterfire_cli

# Generate config file
flutterfire configure
```

This creates: `lib/firebase_options.dart`

---

### Step 5: Verify Files Are In Place

Your project should now have:

```
super_swipe/
├── ios/
│   └── Runner/
│       └── GoogleService-Info.plist     ✅
├── android/
│   └── app/
│       └── google-services.json         ✅
└── lib/
    └── firebase_options.dart            ✅
```

---

### Step 6: Test

Run the app to verify Firebase connection:

```bash
flutter run
```

You should see in logs:
```
✅ Firebase initialized successfully
✅ Firestore connection established
```

---

## 🔒 Security Notes

**Why aren't these files in Git?**

These files contain:
- Firebase API keys
- Project IDs
- OAuth client IDs
- Other sensitive credentials

**Best Practices:**
- ✅ Keep configuration files out of version control
- ✅ Each developer downloads their own copy
- ✅ Use different Firebase projects for dev/staging/prod
- ✅ Never commit API keys or secrets

---

## 🆘 Troubleshooting

### "Firebase not configured" Error

**Solution**: Make sure all 3 files are in place:
```bash
# Check iOS
ls ios/Runner/GoogleService-Info.plist

# Check Android
ls android/app/google-services.json

# Check Flutter
ls lib/firebase_options.dart
```

### "Invalid GoogleService-Info.plist"

**Solution**: Re-download from Firebase Console - make sure it's for the correct app.

### FlutterFire configure fails

**Solution**:
```bash
# Update FlutterFire CLI
dart pub global activate flutterfire_cli

# Make sure you're logged into Firebase
firebase login
```

---

## 📞 Support

For Firebase access or configuration issues, contact the project admin.

---

**Last Updated**: December 15, 2024
