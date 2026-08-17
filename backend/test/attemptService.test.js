import assert from 'node:assert/strict';
import test from 'node:test';
import { exams, questions, attempts, resetStore } from '../src/data/store.js';
import { startAttempt, submitAttempt, getResult } from '../src/services/attemptService.js';

function seedExam(questionCount = 10) {
  resetStore();
  exams.set('exam-1', { id: 'exam-1', isAvailable: true, durationMinutes: 30, questions: [] });
  for (let index = 0; index < questionCount; index += 1) {
    const id = `q-${index}`;
    questions.set(id, { id, examId: 'exam-1', text: `Question ${index}`, options: ['A', 'B', 'C', 'D'], correctAnswer: index % 4, marks: 5 });
    exams.get('exam-1').questions.push(id);
  }
}

test('starts an available exam with exactly ten sanitized questions', () => {
  seedExam(12);
  const response = startAttempt({ examId: 'exam-1', user: { id: 'student-1', role: 'STUDENT' }, now: new Date('2026-08-17T12:00:00.000Z') });
  assert.equal(response.questions.length, 10);
  assert.equal(response.attempt.status, 'IN_PROGRESS');
  assert.equal(response.attempt.startedAt, '2026-08-17T12:00:00.000Z');
  assert.equal(response.attempt.endsAt, '2026-08-17T12:30:00.000Z');
  response.questions.forEach((question) => { assert.deepEqual(Object.keys(question), ['id', 'text', 'options']); assert.equal(question.correctAnswer, undefined); assert.equal(question.marks, undefined); });
});

test('rejects starts with fewer than ten questions', () => { seedExam(9); assert.throws(() => startAttempt({ examId: 'exam-1', user: { id: 'student-1', role: 'CLIENT' } }), /At least 10 questions/); });

test('submits server-scored answers and ignores frontend scoring data', () => {
  seedExam(10);
  const { attempt } = startAttempt({ examId: 'exam-1', user: { id: 'student-1', role: 'STUDENT' }, now: new Date('2026-08-17T12:00:00.000Z') });
  const answers = attempt.questionIds.map((questionId, index) => ({ questionId, answer: index < 7 ? questions.get(questionId).correctAnswer : 0, correctAnswer: 999, score: 999 }));
  const result = submitAttempt({ attemptId: attempt.id, user: { id: 'student-1', role: 'STUDENT' }, answers, now: new Date('2026-08-17T12:10:00.000Z') });
  assert.deepEqual(result, { totalQuestions: 10, correctAnswers: 8, incorrectAnswers: 2, score: 8, percentage: 80, submittedAt: '2026-08-17T12:10:00.000Z' });
  assert.deepEqual(getResult({ attemptId: attempt.id, user: { id: 'student-1', role: 'STUDENT' } }), result);
});

test('rejects duplicate, foreign, invalid, and late submissions', () => {
  seedExam(10);
  const { attempt } = startAttempt({ examId: 'exam-1', user: { id: 'student-1', role: 'STUDENT' }, now: new Date('2026-08-17T12:00:00.000Z') });
  assert.throws(() => submitAttempt({ attemptId: attempt.id, user: { id: 'student-2', role: 'STUDENT' }, answers: [], now: new Date('2026-08-17T12:10:00.000Z') }), /does not belong/);
  assert.throws(() => submitAttempt({ attemptId: attempt.id, user: { id: 'student-1', role: 'STUDENT' }, answers: [{ questionId: 'not-in-attempt', answer: 0 }], now: new Date('2026-08-17T12:10:00.000Z') }), /belong to the attempt/);
  assert.throws(() => submitAttempt({ attemptId: attempt.id, user: { id: 'student-1', role: 'STUDENT' }, answers: [{ questionId: attempt.questionIds[0], answer: 99 }], now: new Date('2026-08-17T12:10:00.000Z') }), /available option/);
  submitAttempt({ attemptId: attempt.id, user: { id: 'student-1', role: 'STUDENT' }, answers: [], now: new Date('2026-08-17T12:10:00.000Z') });
  assert.throws(() => submitAttempt({ attemptId: attempt.id, user: { id: 'student-1', role: 'STUDENT' }, answers: [], now: new Date('2026-08-17T12:10:00.000Z') }), /already been submitted/);
  seedExam(10);
  const { attempt: lateAttempt } = startAttempt({ examId: 'exam-1', user: { id: 'student-1', role: 'STUDENT' }, now: new Date('2026-08-17T12:00:00.000Z') });
  assert.throws(() => submitAttempt({ attemptId: lateAttempt.id, user: { id: 'student-1', role: 'STUDENT' }, answers: [], now: new Date('2026-08-17T12:31:00.000Z') }), /deadline has expired/);
  assert.equal(attempts.get(lateAttempt.id).status, 'EXPIRED');
});
