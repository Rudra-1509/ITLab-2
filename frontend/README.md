# 📱 MCQ Examination App (Frontend)

Cross-platform mobile and web client for the Online Multiple-Choice Question (MCQ) Examination Platform, built with **Flutter**, **Riverpod**, and **GoRouter**.

---

## 🚀 Features

- **Role-Based Portals**:
  - **Student View**: Browse active exams, review countdown timers, take synchronized exams, and view score breakdowns with persistent local history.
  - **Admin / Examiner View**: Monitor live metrics (total users, exams, attempts, pass rates), create & configure exams, build question banks, and audit test submissions.
- **Synchronized Exam Room**:
  - Live countdown timer tied to server-enforced deadline (`endsAt`).
  - Interactive question grid / palette for rapid navigation.
  - Auto-submits on time expiration.
- **Fast Evaluation & Testing**:
  - One-tap quick login buttons for all roles (`Admin`, `Examiner`, `Student 1`, `Student 2`).
  - Dynamic Server Base URL switcher (easily switch between Render production, `localhost:5000`, and `10.0.2.2:5000` for Android emulators).
- **Persistent Local Cache**:
  - Uses `SharedPreferences` to cache past exam attempt results for offline viewing.

---

## 🛠 Tech Stack & Architecture

- **Framework**: Flutter 3.12+ (Dart 3.x)
- **State Management**: [Riverpod](https://pub.dev/packages/flutter_riverpod) (`flutter_riverpod: ^3.4.2`)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router) (`go_router: ^17.5.0`) with authenticated route guards
- **HTTP Client**: [Dio](https://pub.dev/packages/dio) (`dio: ^5.11.0`) with auth token & dynamic base URL interceptors
- **Local Storage**: [SharedPreferences](https://pub.dev/packages/shared_preferences) (`shared_preferences: ^2.5.5`)
- **Date Formatting**: [intl](https://pub.dev/packages/intl) (`intl: ^0.20.3`)

### Directory Structure

```text
frontend/lib/
├── core/
│   ├── network/            # Dio HTTP client, auth bearer interceptor, error transformer
│   ├── router/             # GoRouter routes, role-based redirection (/login, /student, /admin)
│   ├── storage/            # SharedPreferences service (JWT token, user role, base URL)
│   └── theme/              # Custom Material 3 AppTheme, color palette, typography
│
├── features/
│   ├── admin/              # Admin dashboard, exam editor, question creator
│   │   ├── models/         # AdminSummary models
│   │   └── presentation/   # AdminDashboard, ExamManagementScreen, AddEditQuestionScreen
│   ├── attempt/            # Attempt lifecycle, history service, and results
│   │   ├── models/         # Attempt, AttemptRecord, Result models
│   │   ├── providers/      # Riverpod attempt providers
│   │   └── services/       # Local attempt history persistence
│   ├── auth/               # Authentication feature
│   │   ├── models/         # User model (roles: ADMIN, EXAMINER, STUDENT, CLIENT)
│   │   ├── presentation/   # LoginScreen with fast demo logins and server URL dialog
│   │   └── providers/      # AuthStateNotifier and session management
│   ├── exam/               # Exams and questions
│   │   ├── models/         # Exam, Question models
│   │   └── providers/      # ExamRepository and exam lists providers
│   └── student/            # Student features
│       └── presentation/   # StudentDashboard, ActiveExamScreen, ResultScreen
│
└── main.dart               # App entrypoint (ProviderScope initialization)
```

---

## 🏁 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed and added to your `PATH`.
- Chrome, Android Studio, or VS Code with Flutter extension.

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App

- **Run in Google Chrome (Web)**:
  ```bash
  flutter run -d chrome
  ```

- **Run on Android Emulator**:
  ```bash
  flutter run -d emulator
  ```

- **Run on Windows Desktop**:
  ```bash
  flutter run -d windows
  ```

---

## 🌐 Connecting to the Backend

By default, the client points to the hosted Render backend:
```
https://itlab-2.onrender.com
```

If you are running the backend locally on port `5000`:
1. Tap the **Server / Settings icon** on the top right of the Login screen.
2. Enter your host address:
   - **Web / Desktop**: `http://localhost:5000`
   - **Android Emulator**: `http://10.0.2.2:5000`
   - **Physical Device**: `http://<YOUR_LOCAL_IP>:5000` (e.g. `http://192.168.1.100:5000`)
3. Tap **Save & Connect**.

---

## 🧪 Running Tests

Run Flutter unit and widget tests:
```bash
flutter test
```

Tests cover:
- User role parsing (`ADMIN`, `EXAMINER`, `STUDENT`)
- Question model validation (4-option requirement)
- Exam 10-question eligibility logic
- Result score and percentage calculation
