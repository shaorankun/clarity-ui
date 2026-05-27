# Clarity — Focus & Study Room

**Clarity** is a productivity app built for people who want to focus better — alone or together. It combines a Pomodoro-style focus timer with collaborative study rooms, task tracking, and personal statistics, all wrapped in a clean dark-themed UI.

> Built with Flutter · Tested on Android  
> Backend: [clarity-api](https://github.com/shaorankun/clarity-api) · Live API: [clarity-api-2dpy.onrender.com](https://clarity-api-2dpy.onrender.com)

---

## What You Can Do

### 🎯 Focus Timer
Start a 25-minute focus session, take short or long breaks, and optionally link each session to a task. Lofi music plays in the background to help you stay in the zone — you can toggle it on/off and adjust the volume anytime. When a session ends, you'll get a local notification so you never have to keep the screen on.

### ✅ Task Management
Create tasks with optional labels, check them off as you go, and pick any active task to attach to your next focus session. Clarity tracks which tasks you've completed each day as part of your stats.

### 📊 Statistics
See how you've been spending your focus time — today's sessions, weekly breakdown by day, total focused minutes, and your current focus streak. Streaks reset if you miss a day, so there's a real reason to keep showing up.

### 🏠 Study Rooms
Sometimes focusing alone isn't enough. Study Rooms let you create or join a shared space where everyone focuses together in real time. The room owner controls the timer — when they start a session, everyone's countdown syncs automatically via WebSocket. Rooms support both public (discoverable) and private (invite-only via a 6-character code) modes. When the last person leaves, the room disappears on its own.

---

## Tech Stack

| | |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Provider |
| HTTP Client | Dio |
| Real-time | WebSocket via STOMP (`stomp_dart_client`) |
| Secure Storage | `flutter_secure_storage` |
| Navigation | Go Router |
| Audio | `just_audio` + `just_audio_background` |
| Notifications | `flutter_local_notifications` |
| Fonts & Icons | Google Fonts, Iconsax |

---

## Project Structure

```
lib/
├── core/
│   ├── network/          # Dio client, app router
│   ├── storage/          # Token storage (flutter_secure_storage)
│   ├── theme/            # Colors, dark theme
│   └── notification_service.dart
├── features/
│   ├── auth/             # Login, register, profile
│   ├── timer/            # Focus timer + lofi music
│   ├── tasks/            # Task CRUD
│   ├── stats/            # Streak + weekly stats
│   └── rooms/            # Study rooms (REST + WebSocket)
├── shared/
│   └── widgets/          # Reusable UI components
└── main.dart
```

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.11.1`
- Android device or emulator

### Run

```bash
flutter pub get
flutter run
```

The app connects to the live backend at `https://clarity-api-2dpy.onrender.com` by default. No extra configuration needed.

> Note: The backend is hosted on Render's free tier — the first request may take a moment to wake up.

---

## Screenshots

*Coming soon.*

---

## Backend

The backend is a separate Spring Boot project. See the [clarity-api repository](https://github.com/shaorankun/clarity-api) for full API documentation, database schema, and deployment details.

---

## Team

Made with ☕ by the **Clarity Team**  
[Anh Tuan](https://github.com/shaorankun) · [Hai Trieu](https://github.com/HaiTriu301)
