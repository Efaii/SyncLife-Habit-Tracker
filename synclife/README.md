# SyncLife - Smart Habit Tracker

A Flutter Web/Mobile application utilizing Supabase and a local Naive Bayes algorithm to predict habit completion probability based on mood and busyness levels.

## Key Features

- **Google OAuth**: Secure and seamless authentication using Google Sign-In via Supabase.
- **Custom Profiles with Supabase Storage**: Personalized user profiles with custom avatars securely stored and fetched from Supabase Storage buckets.
- **Dynamic Theme Mode (Riverpod)**: A robust, hybrid state management system supporting 'Light', 'Dark', and 'System Default' themes persisted locally via `shared_preferences`.
- **Intelligent Statistical Analytics**: Advanced tracking including Weekly Consistency, Top Productive Days, Success Rates, and AI-driven Habit Success Predictions utilizing a local Naive Bayes model.

## Setup Instructions

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed (Version 3.10+ recommended)
- A configured [Supabase](https://supabase.com/) project (with Auth, Database, and Storage buckets configured).
- Chrome browser (for Flutter Web development).

### 1. Configure Supabase Constants
Navigate to `lib/core/constants/supabase_constants.dart` and insert your Supabase URL and Anon Key:
```dart
class SupabaseConstants {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
}
```

### 2. Install Dependencies
Open your terminal in the project root directory and run:
```bash
flutter pub get
```

### 3. Run the Application
To run the app on Flutter Web (Chrome), execute the following command:
```bash
flutter run -d chrome
```

Enjoy tracking your habits intelligently with SyncLife!
