# Pet Owner App (Flutter + SQLite)

This repository contains a minimal Flutter app that manages pet owners and their pets using SQLite (sqflite).

## Structure

```
lib/
  main.dart
  models/
    owner.dart
    pet.dart
    document.dart
  db/
    database_helper.dart
  screens/
    login_screen.dart
    register_screen.dart
    owner_profile_screen.dart
    pet_list_screen.dart
    add_pet_screen.dart
    document_screen.dart
    settings_screen.dart
  widgets/
    pet_card.dart
    custom_textfield.dart
```

## Setup

1. Install Flutter SDK: https://flutter.dev/docs/get-started/install
2. From project root run:
   ```bash
   flutter pub get
   flutter run
   ```

## Permissions

If you use image picker on Android, add these to `android/app/src/main/AndroidManifest.xml` inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

For Android 13+ consider adding `READ_MEDIA_IMAGES` as needed.

## Notes

- Passwords are stored in plaintext in this demo. **Do not** use in production. Replace with hashed passwords (e.g. using crypto / bcrypt).
- This is a single-user-local demo (no remote sync).
