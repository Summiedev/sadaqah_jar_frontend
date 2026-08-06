# Mizan Frontend

Flutter mobile application for Mizan — a sadaqah and habit-tracking app with personal and family-focused modes. Built with Flutter and Riverpod, it connects to the Mizan FastAPI backend for all persistence and real-time features.

## Tech Stack

- **Language:** Dart
- **Framework:** Flutter (Material Design 3)
- **State Management:** Flutter Riverpod (v2)
- **Routing:** GoRouter (v14)
- **HTTP:** `http` package for REST API calls
- **Auth:** JWT via secure storage, Google Sign-In (`google_sign_in`)
- **Push Notifications:** Firebase (firebase_core, firebase_messaging, flutter_local_notifications)
- **Storage:** `flutter_secure_storage` (tokens), `shared_preferences` (settings)
- **Charts:** fl_chart (streak heatmap, progress)
- **QR:** qr_flutter (family invite codes)
- **WebSocket:** `web_socket_channel` (real-time family updates)
- **Testing:** `flutter_test` (built in), `flutter_lints` for linting

## Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management across the app |
| `go_router` | Declarative routing and navigation |
| `http` | REST API communication with backend |
| `flutter_secure_storage` | Secure JWT token persistence |
| `firebase_core` + `firebase_messaging` | Push notification setup and delivery |
| `flutter_local_notifications` | Local notification scheduling |
| `fl_chart` | Streak/heatmap visualization |
| `table_calendar` | Activity calendar view |
| `google_sign_in` | Google OAuth authentication |
| `qr_flutter` | Share family invite codes |
| `web_socket_channel` | Real-time WebSocket connection |
| `url_launcher` | Open external links (charities, evidence) |
| `shared_preferences` | App settings persistence |
| `email_validator` | Email format validation |

## Project Structure

```
sadaqah_jar_frontend/
├── lib/
│   ├── main.dart                      # App entry — Firebase init, routing
│   ├── firebase_options.dart          # Firebase config per platform
│   │
│   ├── core/                          # Shared infrastructure
│   │   ├── session_controller.dart    # Auth/session state (Provider)
│   │   ├── mode_provider.dart         # Personal/Family/Both mode toggle
│   │   ├── companion_provider.dart    # Selected companion mode
│   │   ├── refresh_helper.dart        # Pull-to-refresh logic
│   │   ├── route_transitions.dart     # Custom page transitions
│   │   ├── animations.dart            # Animation helpers
│   │   ├── act_store.dart             # Local sadaqah act caching
│   │   └── theme/
│   │       └── app_theme.dart         # Mizan theme, colors, typography
│   │
│   ├── services/
│   │   ├── backend_api.dart           # All REST API calls to backend
│   │   └── push_notification_service.dart  # Firebase push notification setup
│   │
│   ├── features/
│   │   ├── auth/                      # Login, register, verification screens
│   │   ├── splash/                    # Splash screen
│   │   ├── onboarding/                # Onboarding flow
│   │   ├── mode/                      # Mode selection (Personal / Family)
│   │   ├── home/
│   │   │   ├── home_screen.dart       # Personal jar/home dashboard
│   │   │   └── add_act_screen.dart    # Add sadaqah act bottom sheet
│   │   ├── journey/                   # Adhkar (morning/evening/travel/sleep)
│   │   │   ├── journey_screen.dart
│   │   │   ├── morning_adhkar_screen.dart
│   │   │   ├── evening_adhkar_screen.dart
│   │   │   ├── travel_adhkar_screen.dart
│   │   │   ├── sleep_adhkar_screen.dart
│   │   │   ├── after_salah_adhkar_screen.dart
│   │   │   ├── books_list_screen.dart
│   │   │   └── book_reader_screen.dart
│   │   ├── family/                    # Family jar features
│   │   │   ├── family_screen.dart     # Family list/home
│   │   │   ├── family_jar_screen.dart # Family jar detail (goals, activities)
│   │   │   ├── family_goals_screen.dart  # Shared goals management
│   │   │   ├── family_timeline_screen.dart  # Activity timeline
│   │   │   ├── family_prayers_screen.dart   # Prayer requests
│   │   │   ├── family_reflections_screen.dart # Shared reflections
│   │   │   ├── family_invitations_screen.dart # Invitations management
│   │   │   ├── family_settings_screen.dart   # Family settings
│   │   │   ├── member_profile_sheet.dart     # Member profile bottom sheet
│   │   │   ├── family_models.dart            # Family data models
│   │   │   └── family_theme.dart             # Family UI theme
│   │   ├── goals/                   # Goal onboarding, monthly review
│   │   ├── profile/                 # User profile/settings
│   │   └── shell/
│   │       └── app_shell.dart       # Bottom navigation + page controller
│   │
│   ├── screens/                     # Standalone screens (admin, auth, etc.)
│   │   ├── admin/                   # Admin panel screens
│   │   ├── settings_screen.dart
│   │   ├── help_screen.dart
│   │   ├── about_screen.dart
│   │   └── notification_center_screen.dart
│   │
│   └── widgets/                      # Reusable UI components
│       ├── live_jar_panel.dart      # Animated jar progress widget
│       ├── motion.dart              # Press/scale animation widget
│       └── notification_action_button.dart
│
├── android/                         # Android platform config
├── ios/                             # iOS platform config
├── linux/                           # Linux platform config
├── macos/                           # macOS platform config
├── windows/                         # Windows platform config
├── web/                             # Web config (index.html, manifest.json)
├── env/
│   └── app_config.example.json      # Example backend URL config
├── pubspec.yaml                     # Dependencies and Flutter config
└── README.md                        # This file
```

## Architecture

### State Management

The app uses **Flutter Riverpod** for state management:

- `sessionProvider` (`SessionController`) — Authentication state, user info, onboarding/goal setup flags
- `modeProvider` (`ModeNotifier`) — Current mode: Personal (0), Family (1), or Both (2)
- `companionModeProvider` — Selected companion mode, shared across onboarding/profile
- `actStoreProvider` — Local caching of sadaqah acts for quick UI updates
- `isScrolledProvider` — Tracks scroll state for bottom navbar color changes

### Navigation

**GoRouter** handles all routing with a nested `ShellRoute` for the bottom navigation:

- `/splash` — Loading screen
- `/onboarding` — First-time setup
- `/mode` — Choose Personal or Family mode
- `/goal-onboarding` — Goal setup flow
- `/auth` — Login/register
- `/home` — Personal jar dashboard (tab 0)
- `/journey` — Adhkar and journey screens (tab 1)
- `/family` — Family jar list and detail (tab 2)
- `/profile` — User profile (tab 3)
- `/family/jar/:id` — Family jar detail
- `/family/goals/:id` — Shared goals
- `/family/prayers/:id` — Prayer requests
- `/family/reflections/:id` — Reflections
- `/family/invitations` — Family invitations
- `/family/settings/:id` — Family settings
- `/admin/*` — Admin panel routes

### Bottom Navigation

The `AppShell` uses a `BottomAppBar` with `CircularNotchedRectangle` shape. The navigation adapts to the selected mode:

- **Personal mode:** Sanctuary (Home), Journey, Profile
- **Family mode:** Family, Journey, Profile
- **Default (Both):** Home, Journey, Family, Profile

The "Add sadaqah" action is placed as a `_DockedAddButton` within the bottom navbar rather than as a floating action button, keeping all actions within the docked bar.

### Backend API

All network calls go through `BackendApi` (singleton) in `lib/services/backend_api.dart`. The base URL is compiled in via `--dart-define-from-file` at build time (set in `env/app_config.json`). Key endpoints:

- `/auth/` — Authentication
- `/sadaqah/` — Personal sadaqah acts, jar stats, streaks
- `/family/` — Family creation, joining, goals, prayers, reflections, activities
- `/dashboard/` — Stats and leaderboards
- `/books/` — Book catalog
- `/notifications/` — Push notification templates
- `/admin/` — Admin endpoints

## Prerequisites

- **Flutter SDK:** ^3.7 (matching `sdk: ^3.7.2` in pubspec.yaml)
- **Dart:** >= 3.7
- **Android SDK:** For Android builds
- **Xcode:** For iOS builds (macOS only)
- **Visual Studio:** For Windows builds (Windows only)
- **Backend running:** The Mizan backend must be accessible at the configured URL

## Installation

```bash
# Clone the repository
cd sadaqah_jar_frontend

# Get dependencies
flutter pub get

# Configure the backend URL
cp env/app_config.example.json env/app_config.json
# Edit env/app_config.json — set API_BASE_URL to your running backend

# For development (default backend is the production URL):
# API_BASE_URL = "https://api.sad-aqah.app/api/v1"

# For local development, point to your local backend:
# API_BASE_URL = "http://192.168.1.x:8000/api/v1"
```

## Environment Configuration

The backend URL is set at compile time via `--dart-define-from-file`:

```bash
flutter run --dart-define-from-file=env/app_config.json
```

`env/app_config.json` example:

```json
{
  "API_BASE_URL": "http://192.168.1.20:8000/api/v1"
}
```

The `env/app_config.example.json` is committed; `env/app_config.json` is gitignored and should never contain secrets.

## Running the Project

### Development

```bash
# Run on connected device or emulator
flutter run

# Run on a specific device
flutter run -d <device_id>

# Run with debug mode (default)
flutter run --debug
```

### Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release

# macOS
flutter build macos --release
```

### Linting

```bash
# Run the analyzer
flutter analyze
```

The project uses `flutter_lints` (configured via `analysis_options.yaml`).

## Testing

```bash
# Run all tests
flutter test

# Run a specific test file
flutter test test/widget_test.dart

# Run with coverage
flutter test --coverage
```

Tests are located in `test/` directory at the project root.

## Firebase / Push Notifications

Push notifications are configured via Firebase:

1. `lib/firebase_options.dart` — Contains Firebase config per platform
2. `lib/services/push_notification_service.dart` — Handles FCM token registration, notification channels, and foreground/background handling
3. `push_notification_service.dart` reads the `FIREBASE_*` configuration from the Firebase options file generated by the FlutterFire CLI

For push notifications to work in production:
- Firebase project must be configured for each platform
- The backend must have `FCM_SERVICE_ACCOUNT_PATH` set in its `.env`
- Device push tokens must be registered via the app (handled automatically)

## Known Limitations

- **Book reading progress** is UI-only — the backend seeds book catalog data but has no per-user reading progress table. The "Continue reading" feature does not persist across sessions.
- **Backend URL is compile-time** — changing the backend host requires rebuilding the app (`flutter run`), not just restarting it.
- **Family act counting** relies on the backend's `POST /family/{id}/add-act` endpoint to increment the shared goal's `acts_done`. The personal jar (`/sadaqah/jar/add-star`) operates independently.
- **Pull-to-refresh** is implemented via `refresh_helper.dart` but the refresh behavior depends on the backend returning updated data.

## Contributing

The project follows a feature-first file organization. When adding new screens or features:

1. Add the screen under `lib/features/<domain>/`
2. Register the route in `lib/main.dart` inside the `GoRouter` config
3. Add any new API methods to `lib/services/backend_api.dart`
4. Use Riverpod for state management (`ref.watch`/`ref.read`)
5. Follow the existing widget patterns (MizanButton, SoftCard, ProgressTrack, MizanAvatar, etc.)
6. Run `flutter analyze` and `flutter test` before committing