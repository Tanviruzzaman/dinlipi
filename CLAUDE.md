# Journal App

A personal journal app built with Flutter + Firebase.

## What it does
Personal journaling with mood tracking, photos, calendar view, and insights.

## Stack
- **Flutter** (Material 3)
- **Riverpod** (`flutter_riverpod`) for state management
- **cloud_firestore** for the database
- **firebase_auth** (+ `google_sign_in`) for authentication
- **firebase_storage** for photos (added when the photos feature is built)
- **google_fonts** (Inter) for typography
- **table_calendar** for the calendar view

## Data model
Firestore path: `users/{uid}/entries/{entryId}`

| Field       | Type            | Notes                     |
|-------------|-----------------|---------------------------|
| `title`     | string          |                           |
| `body`      | string          |                           |
| `mood`      | int (1–5)       | 1 = awful … 5 = great     |
| `tags`      | list<string>    |                           |
| `photoUrls` | list<string>    | Storage download URLs     |
| `createdAt` | timestamp       | server timestamp on write |
| `updatedAt` | timestamp       | server timestamp on write |

## Folder structure (feature-first)
```
lib/
  core/
    theme/       app_theme.dart
    constants/
    utils/       mood.dart, date_group.dart
    widgets/     app_shell.dart, shared UI
  features/
    auth/        data/ · providers/ · screens/
    entries/     data/ · providers/ · screens/
    calendar/    screens/
    insights/    (later)
    settings/    (later)
```

## Rules / conventions
- Use **Riverpod** for all state. UI widgets are `ConsumerWidget` / `ConsumerStatefulWidget`.
- Read Firestore through **StreamProvider** (`entriesStreamProvider`), not `StreamBuilder` in widgets.
- **Material 3**, `ColorScheme.fromSeed` with a deep-purple seed, light + dark themes, 16px card radius.
- **google_fonts (Inter)** for UI text; a serif font for the journal body.
- **No business logic inside widgets** — put it in repositories (`*_repository.dart`) and providers.
- Repositories are pure Dart classes that take the Firebase SDK instances; providers wire them up.

## Build status
Steps 0–4 are implemented: theme, auth, entries CRUD, calendar + bottom nav.
Photos, app-lock, reminders, insights, and search are planned (Steps 5–10).

## Commands
- `flutter pub get` — install deps
- `flutter analyze` — lint
- `flutter run` — run on a device/emulator
- `flutter build apk --release` — release build

> Firebase must be configured first: run `flutterfire configure` to generate
> `lib/firebase_options.dart`. The app will not compile until that file exists.
