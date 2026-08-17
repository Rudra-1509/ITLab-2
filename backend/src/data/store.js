import { hashPassword } from '../utils/password.js';

export const ROLES = Object.freeze({ ADMIN: 'ADMIN', EXAMINER: 'EXAMINER', CLIENT: 'CLIENT', STUDENT: 'STUDENT' });
export const exams = new Map();
export const questions = new Map();
export const attempts = new Map();
export const users = new Map();
let examSequence = 1, questionSequence = 1, attemptSequence = 1;

export function nextExamId() { return String(examSequence++); }
export function nextQuestionId() { return String(questionSequence++); }
export function nextAttemptId() { return String(attemptSequence++); }

export function resetStore() {
  exams.clear(); questions.clear(); attempts.clear(); users.clear();
  examSequence = 1; questionSequence = 1; attemptSequence = 1; seedUsers();
}

export function seedUsers() {
  if (users.size) return;
  // TODO(DB): Replace these development-only in-memory users with the database teammate's User model/repository.
  // Required fields: id, email or username, passwordHash, role, active/status.
  const defaults = [
    ['admin-1', 'admin@example.com', 'admin123', ROLES.ADMIN],
    ['examiner-1', 'examiner@example.com', 'examiner123', ROLES.EXAMINER],
    ['student-1', 'student@example.com', 'student123', ROLES.STUDENT],
    ['student-2', 'student2@example.com', 'student123', ROLES.STUDENT],
  ];
  for (const [id, email, password, role] of defaults) users.set(id, { id, email, username: email.split('@')[0], passwordHash: hashPassword(password, `salt-${id}`), role, active: true });
}
seedUsers();
