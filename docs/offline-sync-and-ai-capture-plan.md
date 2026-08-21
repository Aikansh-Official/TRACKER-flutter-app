# Offline sync and AI task capture plan

## What is fixed now

- The saved dark-mode choice now applies before login as well as after login. The lock screen, its fields, errors, and helper text use the active Material theme instead of light-only colours.
- An unfinished `TASK` from a previous date, including one already marked `PENDING`, is carried to the current date as `TODAY` with outcome `RESCHEDULED`.
- Historical `EVENT` items remain on their original date as `PENDING`; moving a missed event silently would change history.

## Current gap between the Android app and website

- Flutter is intentionally offline-only today: its SQLite database has local integer IDs and no account token, network client, change history, or sync queue.
- The website has MongoDB accounts and JWT authentication. It currently changes old `TODAY` and `SCHEDULED` items to `PENDING`; it does not carry old `PENDING` tasks forward.
- These are two different data authorities. Connecting them by calling the existing create/update endpoints would duplicate records, lose offline edits, and produce different rollover results.

## Recommended design: local-first sync

1. Keep SQLite as the phone's source of truth while offline. Every create, edit, complete, or delete succeeds locally first.
2. Give every syncable record a stable `sync_id` UUID, plus `revision`, `updated_at`, `deleted_at`, and `device_id`. Never match SQLite integer IDs to MongoDB `_id` values.
3. Add a local outbox table. Each offline change becomes an ordered mutation and stays there until the server confirms it.
4. Add versioned sync endpoints to the website instead of trying to synchronize through the existing screen endpoints:
   - `POST /api/sync/push` accepts a batch of mutations and returns accepted revisions/conflicts.
   - `POST /api/sync/pull` accepts a cursor and returns server changes and the next cursor.
   - MongoDB enforces unique `{userId, syncId}` and keeps soft-deleted tombstones until every active device has received them.
5. Let the user choose **Connect web account**. Store the website JWT only in secure device storage, never in SQLite or source control. The local profile password remains local; it must not be converted between Flutter's PBKDF2 hash and the website's bcrypt hash.
6. On first connection, show a clear choice: upload this phone, download the cloud copy, or merge after a preview. Do not silently upload private local history.
7. Sync on an explicit Sync action, app resume, and a connectivity restoration event. A failed sync must leave the app fully usable offline and retain the outbox.

## Conflict and rollover contract

- Completed/resolved items are terminal unless the user explicitly reopens them.
- For ordinary non-terminal edits, use revision-based last-write-wins only when the server can safely order them. If two devices change a title, date, or deadline from the same revision, return a conflict for a small review screen instead of discarding either edit.
- Use one shared rule on phone and server: old unfinished `TASK` rows, including `PENDING`, move to today as `TODAY` and `RESCHEDULED`; old `EVENT` rows stay historical as `PENDING`.
- Add the same JSON fixture cases to Flutter and the website before enabling sync. This prevents a laptop and phone from disagreeing the next morning.

## Delivery phases

1. **Policy alignment:** change the website daily-state service to the shared rollover rule and add server tests matching the Flutter cases.
2. **Identity and migration:** add the sync fields/outbox to SQLite with a versioned migration; add MongoDB sync indexes and non-destructive schema migration.
3. **Authenticated sync:** deploy the website API over HTTPS, configure Android network access and CORS, add secure token storage, initial-sync choice, outbox retry, pull/push, and a visible sync status.
4. **Conflict UX and reliability:** offline/online integration tests, interrupted sync tests, delete propagation tests, and a user-facing conflict resolver.
5. **AI capture:** build only after sync is reliable, so an AI-created task is still saved locally if the network disappears.

## AI task capture: practical options

### Recommended first experience: Share into TRACKER

1. In ChatGPT mobile, share a response or selected text to TRACKER.
2. TRACKER receives the text through an Android share target or deep link.
3. The app extracts a suggested title and date, then always shows a confirmation sheet with title, deadline, time, priority, and timezone before saving locally.

This is private, works without giving an app access to ChatGPT conversation history, and can save a task even when offline. It is the closest natural workflow to “I told ChatGPT about a task.”

### AI-assisted parsing in TRACKER

1. Add a **Capture with AI** box in TRACKER for text such as: “Submit the placement form next Friday by 5 PM.”
2. Send only that capture text to a website endpoint such as `POST /api/ai/parse-task`; the OpenAI key stays on the server, never inside the Android APK.
3. Request structured JSON: `title`, `scheduledDate`, `deadline`, `allDay`, `startTime`, `priority`, `estimatedMinutes`, `confidence`, and `clarifyingQuestion`.
4. Validate dates against the selected timezone, show a preview, require confirmation, then save locally and enqueue sync.
5. When offline, offer normal manual capture and retry AI parsing only if the user asks after connectivity returns.

### Sending directly from a custom ChatGPT integration

This is possible through a custom ChatGPT app/action that calls a secured website endpoint, then the phone receives it on the next sync. It requires a deployed HTTPS API, per-user authorization, rate limiting, audit logs, and an explicit confirmation response. A normal ChatGPT conversation cannot be passively read and pushed by an installed app.

## Privacy, cost, and decisions needed before implementation

- Do not put an OpenAI key or website JWT secret in Flutter, Git, or screenshots.
- Ask consent before sending task text to AI; never send mood notes, journal text, or the entire local database for task parsing.
- Add rate limits, server-side validation, and an audit log for AI-created tasks.
- Choose the deployed website API URL, MongoDB deployment, sign-in ownership, first-sync merge policy, and a budget for AI requests before the cloud phases begin.
