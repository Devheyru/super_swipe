# Super Swipe

Super Swipe is a Flutter-based mobile application designed to make meal planning fun and easy. It features a "Tinder-like" swipe interface for discovering recipes based on your pantry ingredients and energy levels.

## 📱 Project Overview

This project is built using **Flutter** and follows a feature-first architecture. It integrates with **Firebase** for authentication and backend services.

### 🛠 Tech Stack

- **Framework:** Flutter (Dart)
- **State Management:** Flutter Riverpod (2.x)
- **Navigation:** GoRouter
- **Backend:** Firebase (Auth, Firestore)
- **UI Components:** Appinio Swiper, Google Fonts, Cached Network Image
- **Environment Management:** flutter_dotenv

## 📂 Project Structure

The project follows a clean, feature-based directory structure:

```
lib/
├── core/                   # Core functionality shared across the app
│   ├── models/             # Data models (Recipe, PantryItem, etc.)
│   ├── providers/          # Global providers (AppState, etc.)
│   ├── router/             # GoRouter configuration
│   └── theme/              # App theme and styling
├── features/               # Feature modules
│   ├── auth/               # Authentication (Login, Signup, Services)
│   ├── home/               # Home dashboard
│   ├── onboarding/         # Welcome/Onboarding screens
│   ├── pantry/             # Pantry management
│   ├── profile/            # User profile settings
│   ├── recipes/            # Recipe details and saved recipes
│   ├── scan/               # Ingredient scanning (Placeholder)
│   ├── shell/              # Bottom navigation wrapper
│   └── swipe/              # Core swipe interface for recipes
├── main.dart               # Application entry point
└── firebase_options.dart   # Firebase configuration
```

## ✨ Current Features

1.  **Authentication:**

    - Email/Password Login and Signup.
    - Firebase Auth integration.
    - User profile management.

2.  **Onboarding:**

    - Introductory screens for new users.

3.  **Swipe Interface (Core):**

    - Interactive card swiping to "Like" or "Pass" on recipes.
    - Filter by "Energy Level" (Low, Okay, High).
    - Mock data currently used for demonstration.

4.  **Navigation:**

    - Bottom navigation bar for easy access to Home, Swipe, Pantry, etc.
    - Protected routes (redirects to login if not authenticated).

5.  **Theming:**
    - Custom "Cute & Friendly" aesthetic with soft colors and rounded UI.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.10.3 or higher)
- Firebase Project (configured for Android/iOS)

### Environment Setup

1.  Create a `.env` file in the root directory.
2.  Add your Firebase configuration keys:

```env
ANDROID_API_KEY=...
ANDROID_APP_ID=...
ANDROID_MESSAGING_SENDER_ID=...
ANDROID_PROJECT_ID=...
ANDROID_STORAGE_BUCKET=...

IOS_API_KEY=...
IOS_APP_ID=...
IOS_MESSAGING_SENDER_ID=...
IOS_PROJECT_ID=...
IOS_STORAGE_BUCKET=...
IOS_BUNDLE_ID=...
```

### Running the App

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run
```

## 📝 Next Steps

- Connect Swipe interface to real Firestore data.
- Implement Pantry ingredient management.
- Build out the Recipe details view.
- Implement the Scanning feature.
