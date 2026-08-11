# TRACKER for Android

TRACKER is a private, completely offline Flutter adaptation of the TRACKER web workspace. It keeps the same editorial violet/gold/graphite identity and the same productivity loop—capture, plan, act, resolve, observe, and reflect—while using Android-native navigation, sheets, touch targets, notifications, sharing, and local storage.

## Privacy and storage

- No backend, MongoDB, account server, analytics SDK, advertising SDK, or cloud dependency.
- SQLite file: `tracker_offline.db`, stored in Android's private application data.
- The local profile password is stored as a SHA-256 digest and is only a device-local workspace lock. It is not a remote account credential.
- Theme and unlocked-session state use Android SharedPreferences.
- JSON and ICS files leave the private sandbox only after the user explicitly chooses Export/Share.
- Android notification permission is requested only from Reminder Center.
- Smart reminders are opt-in: a 9:00 AM plan summary and an approximately 7:00 PM unfinished-work summary are scheduled from real saved tasks and due routines. Completed, skipped, delegated, dropped, archived, and recovery items are excluded.

## Implemented product areas

- Offline profile creation, unlock, lock, persistent theme, and dark-field contrast.
- Seven-destination Android bottom navigation: Overview, Plan, Today, Routines, Mood, Calendar, Insights.
- Overview metrics and workspace routes, Pending decisions, Archive, restore, JSON export, and ICS calendar export.
- Quick Capture on every signed-in screen with task/event mode, date, all-day/timed scheduling, deadlines, estimates, reminders, checklists, daily/weekly/monthly recurrence, interval, weekday selection, and recurrence end date.
- Recurring occurrence materialization with a one-year default horizon and 120-occurrence safety cap.
- Today score, live clock, routine quantity controls (`−1` and `+1`), task completion, checklist steps, recovery days, skip/drop/archive outcomes, individual confetti, and full-day celebration.
- Routine library with binary/quantifiable/temporary types, life areas, daily/weekday/weekend/custom/weekly-target schedules, archive, and restore.
- Productivity Studio with daily intention, if–then implementation intention, capacity limits, three priorities, shutdown note, focus timer, distractions, honest abandonment, goals, milestones, and weekly review.
- Complex Mood Studio with mood orbit, mood/energy/stress/focus sliders, sleep in half-hour steps, emotions, influencing factors, private note, historical trends, recent reflections, and sparse-data language.
- Month calendar with selected-day agenda plus horizontally scrollable Monday-first week board and drag-to-reschedule task blocks.
- Insights using only saved evidence: average completion, current/best streak, completion arc, life-area comparison, 84-day heatmap, variance chart, routine table, focus minutes, and estimate calibration.
- Android local reminders with reboot restoration, explicit task alarms, morning plan summaries, five-hours-left unfinished-work summaries, responsive light/dark UI, accessible labels, honest empty states, pull-to-refresh, and local data portability.

No fake productivity history is seeded. A new installation is intentionally empty.

## Project map

```text
lib/
  core/theme.dart                    Shared light/dark design system
  data/tracker_database.dart         SQLite schema and storage helpers
  services/notification_service.dart Android local reminder integration
  state/tracker_controller.dart      Offline business rules and application state
  ui/auth_screen.dart                Offline profile onboarding and unlock
  ui/app_shell.dart                  App bar, seven-item dock, global actions
  ui/screens/                        Overview, Plan, Today, Routines, Mood,
                                     Calendar, and Insights
  ui/widgets/                        Shared cards and Quick Capture
test/widget_test.dart                Theme/contrast and palette checks
```

## Run

Requirements: Flutter 3.44.7 or compatible stable release, Dart 3.12+, Android SDK, and an Android emulator or phone.

```powershell
cd C:\Users\Aikan\Desktop\FlutterProjects\TRACKER
flutter pub get
flutter test
flutter analyze
flutter run
```

## Open in Android Studio

1. Start Android Studio and choose **File → Open**.
2. Select this project folder: `C:\Users\Aikan\Desktop\FlutterProjects\TRACKER`.
3. Start an Android device from **Device Manager**.
4. Choose the device from the toolbar and press **Run**.

The project is the source of truth. Do not open an APK as the project; Android Studio opens this folder and reads `pubspec.yaml`, `android/`, and `lib/` directly.

Build an installable debug APK:

```powershell
flutter build apk --debug
```

Output:

```text
build\app\outputs\flutter-apk\app-debug.apk
```

## Verification completed on 2026-08-12

- `dart format lib test`
- `flutter analyze` — no errors or warnings; style-only info notices remain.
- `flutter test` — all tests passed.
- `flutter build apk --debug` — succeeded.
- `flutter build apk --release` — succeeded; 54.2 MB installable APK.
- Installed and launched on Pixel 8a emulator, Android 17/API 37.
- First-run UI inspected at 1080×2400; no startup exception was logged.

## Deliberate Android UX adaptations

The web app's fixed desktop navigation becomes a seven-item bottom dock. Desktop drawers and modals become bottom sheets. Hover behavior becomes pressed/selected feedback. Browser notifications become Android local notifications. Browser downloads become Android Share actions. MongoDB becomes SQLite. The content model, vocabulary, honest scoring rules, palette, typography hierarchy, empty states, and feature set remain aligned with TRACKER.
