# Exam System Backend (MCQ)

Express backend for the college MCQ Exam System. Application code now uses native ES Modules (`type: module`). The database teammate still owns the final persistent schema; until that is connected, the backend uses an in-memory store with `TODO(DB)` markers.

## Run

```bash
cd backend
npm install
cp .env.example .env
npm run dev
```

Required env vars: `PORT`, `CORS_ORIGIN`, `JWT_SECRET`, `JWT_EXPIRES_IN_SECONDS`, and the future `DATABASE_URL` from the database teammate.

## Development users (in-memory only)

- ADMIN: `admin@example.com` / `admin123`
- EXAMINER: `examiner@example.com` / `examiner123`
- STUDENT: `student@example.com` / `student123`
- STUDENT: `student2@example.com` / `student123`

These exist only to allow frontend/backend integration before the database arrives.

## API endpoints

All protected endpoints use `Authorization: Bearer <token>`.

| Method | Endpoint | Role | Body | Notes |
| --- | --- | --- | --- | --- |
| GET | `/health` | Public | none | Health check. |
| POST | `/api/auth/login` | Public | `{ "email" or "username", "password" }` | Returns `{ token, accessToken, user }`. Role is loaded server-side. |
| GET | `/api/exams` | Any authenticated | none | Lists exams with sanitized questions only. |
| GET | `/api/exams/:examId` | Any authenticated | none | Exam detail; never exposes `correctAnswer` or `marks`. |
| POST | `/api/exams` | ADMIN, EXAMINER | `{ "title", "durationMinutes", "isAvailable"? }` | Creates an exam. |
| PUT | `/api/exams/:examId` | ADMIN, EXAMINER | partial exam fields | Updates an exam. |
| DELETE | `/api/exams/:examId` | ADMIN, EXAMINER | none | Deletes an exam and its questions. |
| POST | `/api/exams/:examId/questions` | ADMIN, EXAMINER | `{ "text", "options":[4 strings], "correctAnswer":0-3, "marks"? }` | Adds MCQ. Correct answer is only returned to examiner/admin mutation responses. |
| PUT | `/api/questions/:questionId` | ADMIN, EXAMINER | partial question fields | Updates MCQ. |
| DELETE | `/api/questions/:questionId` | ADMIN, EXAMINER | none | Deletes MCQ. |
| POST | `/api/exams/:examId/start` | CLIENT/STUDENT | none | Creates attempt, enforces at least 10 questions, returns exactly 10 sanitized questions plus server `startedAt`/`endsAt`. |
| GET | `/api/attempts/:attemptId` | Owning CLIENT/STUDENT | none | Returns own active attempt only. |
| POST | `/api/attempts/:attemptId/submit` | Owning CLIENT/STUDENT | `{ "answers":[{"questionId":"1","answer":2}] }` | Backend validates ownership, timing, duplicates, answers, and computes score. |
| GET | `/api/attempts/:attemptId/result` | Owning CLIENT/STUDENT | none | Returns own result only after submission. |
| GET | `/api/admin/summary` | ADMIN | none | Counts users, exams, attempts. |
| GET | `/api/admin/users` | ADMIN | none | Lists users without password hashes. |
| GET | `/api/admin/exams` | ADMIN | none | Admin exam list. |

## Exam flow, scoring, and timing

An examiner/admin creates an exam and adds at least 10 MCQs. A student starts the exam through `/api/exams/:examId/start`; the backend chooses exactly 10 questions, records server start/end timestamps, and omits answer keys. Submission is accepted only once before `endsAt`. Score, correct/incorrect counts, and percentage are calculated on the backend, ignoring any frontend score fields.

## WHAT THE FRONTEND TEAMMATE NEEDS

Use `/api/auth/login`, store the returned bearer token, call `/api/exams` to list available exams, call `/api/exams/:examId/start` to receive exactly 10 safe questions, submit `{ answers: [{ questionId, answer }] }`, and read `/api/attempts/:attemptId/result`. Do not send role, timing, score, or correct answers; the backend ignores or rejects untrusted values.

## WHAT THE DATABASE TEAMMATE NEEDS

Provide real repositories/models for users, exams, questions, attempts, submitted answers, and results. Required fields are documented in `src/data/store.js` and `src/services/dataStore.js` with `TODO(DB)` comments. The backend needs user lookup by email/username with password hash and role; exam CRUD; question CRUD including correct answer for server scoring; attempt persistence with owner/start/end/status; answer persistence; and result persistence/lookup.
