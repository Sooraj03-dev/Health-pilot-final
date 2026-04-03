# health_pilot/

> Flutter health app · Supabase · Gemini AI · Riverpod · GoRouter

---

## Sprints

| Sprint | Focus | Key Files |
|--------|-------|-----------|
| S1 | Auth & Navigation | `auth_service`, `router`, `login_page`, `signup_page` |
| S2 | Vitals & SOS | `watch_service`, `sos_service`, `vitals_screen`, `sos_screen` |
| S3 | AI & Medical Records | `gemini_service`, `storage_service`, `ai_assistant_screen` |
| S4 | Doctor-Patient Chat | `chat_service`, `chat_room_screen`, `patient_chat_screen` |

---

## Setup

### 1. Clone & install
```bash
git clone <repo-url>
cd health_pilot
flutter pub get
```

### 2. Environment variables
Copy `.env.example` to `.env` and fill in your keys:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
GEMINI_KEY=your-gemini-api-key
```

### 3. Scaffold (first-time only)
```bash
chmod +x setup_health_pilot.sh
./setup_health_pilot.sh
```

### 4. Run
```bash
flutter run
```

---

## Project Structure

```
lib/
├── main.dart                   # App entry, Supabase.init
├── router.dart                 # GoRouter + auth guards
├── core/
│   ├── constants.dart
│   ├── supabase_client.dart    # Singleton Supabase client
│   └── theme.dart
├── models/
│   ├── user_model.dart         # S1
│   ├── health_metric.dart      # S2
│   ├── sos_alert.dart          # S2
│   ├── message.dart            # S4
│   └── medical_record.dart     # S3
├── services/
│   ├── auth_service.dart       # S1 · login, signup, logout
│   ├── profile_service.dart    # S1 · role + is_verified
│   ├── watch_service.dart      # S2 · Health Connect bg sync
│   ├── sos_service.dart        # S2 · GPS + sos_alerts insert
│   ├── notification_service.dart # S2 · local push on SOS
│   ├── gemini_service.dart     # S3 · Gemini API calls
│   ├── storage_service.dart    # S3 · medical-docs bucket
│   └── chat_service.dart       # S4 · StreamBuilder on messages
├── providers/
│   ├── auth_provider.dart      # S1
│   ├── health_provider.dart    # S2
│   └── chat_provider.dart      # S4
├── screens/
│   ├── auth/
│   ├── dashboards/
│   ├── vitals/
│   ├── ai/
│   ├── records/
│   └── chat/
└── widgets/
    ├── app_shell.dart          # Nav scaffold
    ├── vitals_card.dart
    ├── sos_button.dart         # Animated SOS
    ├── message_bubble.dart
    └── loading_shimmer.dart
```

---

## Developer Ownership

| Dev | Sprint | Files |
|-----|--------|-------|
| D1 | S1 Auth UI | `login_page`, `signup_page`, `auth_service`, `auth_provider` |
| D1 | S2 Vitals | `watch_service`, `health_metric` |
| D1 | S3 AI | `ai_assistant_screen` |
| D1 | S4 Chat | `chat_service`, `chat_provider`, `message` |
| D2 | S1 Profile | `profile_service`, `user_model` |
| D2 | S2 SOS | `sos_service`, `sos_alert`, `sos_screen`, `sos_button` |
| D2 | S3 AI API | `gemini_service` |
| D2 | S4 Chat | `message_bubble`, `patient_chat_screen` |
| D3 | S1 Routing | `router`, `patient_dashboard`, `doctor_dashboard` |
| D3 | S2 Notifications | `notification_service` |
| D3 | S3 Storage | `storage_service`, `records_screen`, `medical_record` |
| D3 | S4 Doctor | `doctor_inbox_screen`, `chat_room_screen` |
| D4 | S1 Shell | `app_shell`, `pending_verification`, `main` |
| D4 | S2 Vitals UI | `vitals_screen`, `vitals_card`, `health_provider` |
| D4 | S3 Records | `records_viewer` |
| D4 | S4 Caregiver | `caregiver_screen`, `loading_shimmer` |

---

## Tech Stack

- **Flutter** — cross-platform mobile
- **Supabase** — auth, database, realtime, storage
- **Google Gemini** — AI assistant
- **Riverpod** — state management
- **GoRouter** — navigation + auth guards
- **Health Connect** — Android vitals sync

---

## Android Permissions (Health Connect)

Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.health.READ_HEART_RATE"/>
<uses-permission android:name="android.permission.health.READ_STEPS"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
```

---

ANTIGRAVITY · health_pilot · Architecture v1.0
