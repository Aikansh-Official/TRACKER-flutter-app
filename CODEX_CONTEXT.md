# TRACKER — Codex Context Index

Read this file before changing the project. It is a compact map for a fresh
Codex task: it explains where the product lives, how its data moves, which
commands prove it works, and what work is currently unfinished.

## Identity and boundaries

- **Workspace:** `C:\Users\Aikan\Desktop\FlutterProjects\TRACKER`
- **Remote:** `https://github.com/Aikansh-Official/TRACKER-flutter-app`
- **Product:** a private, completely offline Android Flutter adaptation of the
  TRACKER React/MongoDB website at `C:\Users\Aikan\Desktop\WebstormProjects\Tracker`.
- **Storage:** local SQLite (`tracker_offline.db`) plus SharedPreferences. No
  backend, analytics, advertising, or Internet permission.
- **Design:** editorial graphite / paper / gold with violet accents; light and
  dark themes; touch-first Android UI; no seeded fake productivity data.
- **User preference:** explain material changes clearly, with theory and a
  relatable example when teaching; do not overstate verification.

## First commands for every new task

```powershell
cd C:\Users\Aikan\Desktop\FlutterProjects\TRACKER
git status -sb
git log -5 --oneline --decorate
flutter test
flutter analyze
```

For Android visual QA:

```powershell
flutter emulators --launch Pixel_8a
flutter build apk --debug
flutter run -d emulator-5554
```

Use `C:\Users\Aikan\AppData\Local\Android\Sdk\platform-tools\adb.exe`
for screenshots/logs when the emulator is available. Do not claim a visual or
notification result without verifying it on a device.

## Runtime architecture

```text
lib/main.dart
  → opens TrackerDatabase and NotificationService
  → initializes TrackerController
  → TrackerApp
      → AuthScreen when locked/onboarding
      → AppShell when unlocked
          → seven destination screens

TrackerController
  ↔ TrackerDatabase (SQLite rows/transactions)
  ↔ NotificationService (Android local notifications)
  ↔ all screens/widgets through ChangeNotifier
```

## Source map

| Location | Responsibility |
| --- | --- |
| `lib/main.dart` | App startup; database and notification initialization. |
| `lib/core/theme.dart` | Light/dark palette, typography, component themes, page padding. |
| `lib/data/tracker_database.dart` | SQLite schema, indexes, database wrappers. Tables: profile, routines, routine_records, tasks, subtasks, moods, daily_plans, focus_sessions, goals, milestones, weekly_reviews. |
| `lib/state/tracker_controller.dart` | Product rules and persistence: auth, daily preparation, tasks, recurrence, routines, mood, plans, focus, goals, exports, and notifications. This is the first place to inspect for behavior bugs. |
| `lib/services/notification_service.dart` | Explicit item reminders, smart morning/evening reminders, reboot recovery, permission handling. |
| `lib/ui/tracker_app.dart` | Theme selection plus startup/authenticated routing. |
| `lib/ui/app_shell.dart` | App bar, lock/export/reminder actions, global Quick Add, seven-destination navigation, route transition stage. |
| `lib/ui/auth_screen.dart` | Offline profile creation, validation, login/unlock, animated auth hero. |
| `lib/ui/widgets/common.dart` | Page intros, shared cards, metric grid/cards, responsive presentation widgets. |
| `lib/ui/widgets/quick_capture.dart` | Create/edit task and event bottom sheet: description, date/time, priorities, estimates, reminders, recurrence, and checklists. |
| `lib/ui/widgets/motion.dart` | Spring buttons, live indicator, deterministic CustomPainter confetti and fireworks, reduced-motion support. |
| `lib/ui/screens/overview_screen.dart` | Daily metrics, routes, pending/archive sheets. |
| `lib/ui/screens/plan_screen.dart` | Intention, capacity, priorities, focus timer, goals, weekly review. |
| `lib/ui/screens/today_screen.dart` | Live clock, daily score ring, task/routine completion, recovery day, celebration overlay. |
| `lib/ui/screens/routines_screen.dart` | Routine creation, schedules, archive/restore. |
| `lib/ui/screens/mood_screen.dart` | Mood check-in, sliders, emotions/factors, private note, trends. |
| `lib/ui/screens/calendar_screen.dart` | Month/agenda/week board, task editing and drag-to-reschedule. |
| `lib/ui/screens/insights_screen.dart` | Saved-data-only metrics, streaks, charts, heatmap, calibration. |
| `test/tracker_controller_test.dart` | SQLite persistence, auth hashing/migration, tasks, routines, recurrence, reminders, smart reminders, offline startup. |
| `test/widget_test.dart` | Theme, reduced motion, narrow/large-text layouts, keyboard safety, all destinations, charts, editing, auth UI. |
| `integration_test/celebration_performance_test.dart` | Profile-mode celebration performance benchmark. |
| `test_driver/integration_test.dart` | Driver for the integration performance test. |

## User-visible product behavior

1. **Overview** — daily score, routines, mood, pending, workspace links.
2. **Plan** — daily intention and capacity; three priorities; focus timer;
   goals and weekly reflection.
3. **Today** — tasks/events, routines with `+1`/`−1`, recovery, individual
   completion celebration, full-day fireworks/confetti.
4. **Routines** — binary/quantity schedules: daily, weekdays, weekends,
   custom, and weekly-target.
5. **Mood** — rating + context is stored locally, not interpreted as a
   productivity score.
6. **Calendar** — dated tasks/events, agenda, weekly board, rescheduling.
7. **Insights** — uses saved evidence only; empty states must remain honest.
8. **Quick Add / Edit** — shared bottom sheet available everywhere.
9. **Reminder Center** — explicit task alarms and optional smart summaries;
   permission is requested only after user intent.
10. **Exports** — JSON and ICS share only after a user action.

## Data and rules that are easy to break

- Task `status` values include `SCHEDULED`, `TODAY`, `PENDING`, `COMPLETED`,
  `SKIPPED`, `DROPPED`, `DELEGATED`, and `ARCHIVED`.
- `original_date` preserves the first plan date; `scheduled_date` is the active
  calendar date. Do not destroy either silently.
- Recurrence materializes dated task rows with a one-year / 120-occurrence cap.
- Completed, skipped, dropped, delegated, archived, and recovery work must not
  generate smart reminders or inflate daily scores.
- Password records use PBKDF2-HMAC-SHA256 with a 60,000 iteration salted
  format; legacy hashes migrate after a successful login.
- Task reminder scheduling must target only newly created or edited IDs; do not
  reschedule every task as a side effect of one edit.
- Animation must respect `MediaQuery.disableAnimationsOf(context)` and use the
  painter-based celebration system rather than a widget per confetti particle.

## Validation record before this handoff

- Commit `0dac070` was pushed to `main` on 2026-08-15 after task editing,
  reminder reliability, persistence, responsive UI, and release verification.
- The previous completed gate was **17 tests passing** and `flutter analyze`
  with no issues.
- A release APK was built and installed on a Pixel 8a emulator; its previous
  SHA-256 was `85D0011B7ABFB36CFB04C2259A752604C24007BA83C1076BDC67895BBC3B8B65`.
- Performance driver results must be reported honestly: the latest 359-frame
  run had 357 frames within 60 Hz, 90th-percentile raster 6.064 ms, and two
  raster outliers. Do not claim perfect 120 Hz.

## Current verified milestone

**Branch:** `red/daily-rollover-and-layout`

This branch fixes two user-reported defects and has completed its verification
gate:

- Missed unfinished `TASK` rows automatically carry forward to the current day
  as `TODAY` / `RESCHEDULED`; past `EVENT` rows remain historical `PENDING`
  items. An injectable clock, resume refresh, and minute timer cover apps left
  open across midnight.
- The Today score card reflows vertically for narrow or large-text layouts.
  Its painted progress indicator now fills the intended 92 dp canvas, while the
  fixed-scale label remains centered inside the ring. Shared page intros also
  account for text scale when choosing their compact layout.
- The rollover test compares stable SQLite row IDs rather than Dart map
  identity. The score test measures the actual painted ring and label bounds at
  200% text scale.

Latest verified gate on 2026-08-21:

- `dart format --output=none --set-exit-if-changed lib test integration_test test_driver`
- `flutter test`: **19 tests passing**
- `flutter analyze`: **No issues found**
- Debug APK built, installed, and exercised on the Pixel 8a emulator.
- Clean Today screenshots: `build/qa-today-0-verified.png` and
  `build/qa-today-100-verified-clean.png`.
- Device semantics reported `0%` and `100%`; logcat showed no RenderFlex,
  Flutter error, or fatal exception during the tested flow.

## Git rules

- Never reset or overwrite unrelated user changes.
- Stage explicit source/test/context files only.
- Commit author: `Aikansh <aikanshkatiyar@gmail.com>`.
- Commit subject format requested by the user: date, time, and feature only.
- Verify `git status -sb`, the commit parent, and the remote state before
  pushing.

## Recommended first prompt in a new Codex task

> Read `C:\\Users\\Aikan\\Desktop\\FlutterProjects\\TRACKER\\CODEX_CONTEXT.md`
> completely. Preserve the uncommitted WIP on
> `red/daily-rollover-and-layout`. Continue the normal-user QA pass: first fix
> the documented 200%-text overflow and rollover test assertion, then run the
> full verification gate before looking for more bugs.
