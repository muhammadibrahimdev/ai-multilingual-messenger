# AI Multilingual Messenger

Android chat app (Flutter) with automatic English ⇄ Urdu translation.
Backend: Supabase (auth, Postgres, realtime, storage). AI (Phase 2+): Groq.

## Status

| Phase | Scope | State |
| --- | --- | --- |
| 1 | Auth, language choice, chat list, user search, realtime text chat | Done |
| 2 | `send-message` Edge Function + Groq translation | Next |
| 3 | Voice messages (record, Whisper, translate) | Planned |
| 4 | Testing, polish, release APK | Planned |

## Setup

1. **Create the platform folders** (only once, in your project folder):

   ```bash
   flutter create --org edu.smiu --project-name ai_multilingual_messenger --platforms android .
   ```

2. **Copy this project's files over yours:** `lib/`, `test/`, `supabase/`,
   `pubspec.yaml`, `analysis_options.yaml`, `dart_defines.example.json`,
   `.vscode/`. Delete the generated `test/widget_test.dart` (it references the
   default counter app).

3. **Install packages:**

   ```bash
   flutter pub get
   ```

4. **Database:** in the Supabase SQL Editor run `supabase/01_schema.sql`, then
   `supabase/02_chat_list.sql`.

5. **Supabase auth setting (for fast testing):** Authentication → Providers →
   Email → turn off "Confirm email".

6. **Credentials:**

   ```bash
   cp dart_defines.example.json dart_defines.json
   echo dart_defines.json >> .gitignore
   ```

   Put your Project URL and publishable (or anon) key in `dart_defines.json`.
   Never put the Groq key or the `service_role` key in the app.

7. **Run:**

   ```bash
   flutter run --dart-define-from-file=dart_defines.json
   ```

   In VS Code use the "AI Messenger (debug)" launch configuration.

8. **Before building the release APK**, add this line inside `<manifest>` of
   `android/app/src/main/AndroidManifest.xml` (Flutter only adds it for debug):

   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   ```

## Project structure

Feature-first layers: `domain` (models) → `data` (Supabase repositories) →
`presentation` (Riverpod providers/controllers, screens, widgets).

```
lib/
├── main.dart, app.dart
├── core/
│   ├── config/        compile-time config, missing-config screen
│   ├── constants/     AppLanguage (en / ur)
│   ├── providers/     Supabase client provider
│   ├── router/        go_router + auth redirect
│   ├── theme/         Supabase-style colors and ThemeData
│   ├── utils/         validators, date/text helpers, AppException
│   └── widgets/       shared UI (button, text field, avatar, ...)
└── features/
    ├── auth/          login, signup, auth repository
    ├── profile/       profile model, settings, user search
    └── chat/          chat list, new chat, realtime chat screen
```

## Notes

- User search is by **username or display name**. Email search is
  deliberately not offered: emails live in `auth.users`, and exposing them to
  every signed-in user would be a privacy leak.
- Text messages are inserted directly in Phase 1 (`original_text` only). Phase 2
  swaps `ChatRepository.sendTextMessage` for the `send-message` Edge Function,
  which fills `translated_text`; the UI already renders both versions.

## Commands

```bash
flutter analyze
flutter test
flutter build apk --release --dart-define-from-file=dart_defines.json
```
