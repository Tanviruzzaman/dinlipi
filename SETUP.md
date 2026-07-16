# Journal App — Setup & Run Guide

This guide takes you from the current state to a running app. Do the steps in
order. Commands are for **PowerShell on Windows**.

> **Current state (checked automatically):**
> - ✅ App code for Steps 0–4 is written (theme, auth, entries CRUD, calendar, nav).
> - ⚠️ **Flutter SDK is not usable** — your PATH points at
>   `C:\Users\Admin\Flutter\flutter_windows_3.29.3-stable\...` which no longer exists.
> - ⚠️ **Firebase is NOT configured** — there is no `lib/firebase_options.dart`,
>   `android/app/google-services.json`, or `firebase.json`. The app will **not
>   compile** until you run `flutterfire configure` (Part 2).

---

## Part 1 — Fix the Flutter toolchain

You have FVM installed and a standalone Dart at `C:\tools\dart-sdk`, but no
working Flutter. Pick **one** option.

### Option A — Reinstall Flutter directly (simplest)
1. Download the latest **stable** Flutter SDK zip:
   https://docs.flutter.dev/get-started/install/windows
2. Extract it to, e.g. `C:\src\flutter` (avoid paths with spaces or `Program Files`).
3. Add `C:\src\flutter\bin` to your **PATH**, and **remove** the stale entry
   `C:\Users\Admin\Flutter\flutter_windows_3.29.3-stable\flutter\bin`:
   - Start → "Edit the system environment variables" → Environment Variables →
     edit `Path` under *User variables*.
4. Open a **new** terminal and verify:
   ```powershell
   flutter --version
   flutter doctor
   ```
   Fix anything `flutter doctor` flags (Android toolchain, licenses):
   ```powershell
   flutter doctor --android-licenses
   ```

### Option B — Use FVM (you already have it)
```powershell
fvm install stable
fvm use stable
# Then prefix flutter commands with `fvm`, e.g. `fvm flutter pub get`
```

> ⚠️ This project's `pubspec.yaml` requires Dart `^3.12.0`, so you need a
> **recent** stable Flutter — not the old 3.29.3 the stale PATH pointed to.

Once `flutter --version` works, install deps:
```powershell
cd c:\Users\Admin\StudioProjects\Dinlipi\journal_app
flutter pub get
```

> **If `flutter pub get` reports version conflicts** (possible, since I pinned
> package versions without a live resolver), let Flutter pick compatible
> versions itself:
> ```powershell
> flutter pub add firebase_core firebase_auth cloud_firestore google_sign_in flutter_riverpod google_fonts table_calendar intl
> ```

---

## Part 2 — Configure Firebase

### 2.1 Install the CLIs
```powershell
# Firebase CLI (needs Node.js installed: https://nodejs.org)
npm install -g firebase-tools

# FlutterFire CLI
dart pub global activate flutterfire_cli
```
Make sure `%USERPROFILE%\AppData\Local\Pub\Cache\bin` is on your PATH so
`flutterfire` is found. Then:
```powershell
firebase login
```

### 2.2 Create / prepare the Firebase project (console)
Go to https://console.firebase.google.com and, in **your** project:

1. **Authentication** → Get started → **Sign-in method**:
   - Enable **Email/Password**.
   - Enable **Google** (pick a support email).
2. **Firestore Database** → Create database → Start in **production mode** →
   choose a region close to you.
3. **Storage** → Get started (only needed later for the photos feature, but you
   can enable it now).

### 2.3 Generate `firebase_options.dart`
From the project root:
```powershell
flutterfire configure
```
- Select your Firebase project.
- Select platforms (at least **android**; add **ios**/**web** if you'll target them).

This creates:
- `lib/firebase_options.dart`  ← the file `main.dart` imports
- `android/app/google-services.json`
- (and the iOS plist if you selected iOS)

After this, the red import error in `main.dart` disappears.

### 2.4 Publish the Firestore security rules
The correct rules are in [`firestore.rules`](firestore.rules). Publish them
either by pasting into **Firestore → Rules** in the console, or via CLI:
```powershell
firebase deploy --only firestore:rules
```
(If deploying via CLI, run `firebase init firestore` once to link `firestore.rules`.)

---

## Part 3 — Android specifics (needed for it to build & for Google sign-in)

1. **Minimum SDK**: `firebase_auth` needs `minSdkVersion 23`. Open
   `android/app/build.gradle` (or `build.gradle.kts`) and ensure:
   ```gradle
   defaultConfig {
       minSdkVersion 23
   }
   ```
   (Recent Flutter templates use `flutter.minSdkVersion` — set it to 23 if lower.)

2. **Google Sign-In on Android needs a SHA-1/SHA-256 fingerprint.** Without it,
   email/password works but Google sign-in fails.
   ```powershell
   cd android
   .\gradlew signingReport
   ```
   Copy the **SHA1** and **SHA-256** from the `debug` variant → Firebase Console
   → Project settings → Your Android app → **Add fingerprint**. Then
   **re-download `google-services.json`** (or re-run `flutterfire configure`).

---

## Part 4 — Run & test

```powershell
flutter analyze        # should be clean
flutter test           # runs the util unit tests
flutter run            # launch on an emulator or connected device
```

### Manual test checklist (Steps 0–4)
- [ ] App opens to the **login screen**.
- [ ] **Sign up** with email/password → lands in the app (Home tab).
- [ ] **Sign out** (top-right icon on Home) → back to login.
- [ ] **Log back in** with the same credentials.
- [ ] (If SHA-1 added) **Continue with Google** signs in.
- [ ] Tap the center **+** → write a title/body, pick a mood → **Save** →
      entry appears on Home, grouped under "Today".
- [ ] Tap an entry → edit it → Save → changes show.
- [ ] **Swipe an entry left** → confirm dialog → it's deleted.
- [ ] **Calendar** tab shows a colored dot on days with entries; tapping a day
      lists that day's entries.

---

## Part 5 — Push to GitHub (after it runs)

`google-services.json`, `firebase_options.dart`, and other secrets: for a
bootcamp submission these are generally fine to commit (they're client config,
not admin secrets), but confirm your course's policy. The default `.gitignore`
already excludes build artifacts.

```powershell
cd c:\Users\Admin\StudioProjects\Dinlipi\journal_app
git init
git add .
git commit -m "Journal app: auth, entries CRUD, calendar (Steps 0-4)"
# create an empty repo on GitHub, then:
git remote add origin https://github.com/<you>/journal_app.git
git branch -M main
git push -u origin main
```

---

## What's next (Steps 5–10)
Not built yet, to keep the core clean and buildable: photos (Storage +
image_picker), app-lock (local_auth), reminders (notifications), insights
(fl_chart), search & tags. Ask me to build any of these once the core runs.
