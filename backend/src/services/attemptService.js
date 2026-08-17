import { exams, questions, attempts, nextAttemptId } from '../data/store.js';

const REQUIRED_QUESTION_COUNT = 10;
const CLIENT_ROLES = new Set(['CLIENT', 'STUDENT']);
const IN_PROGRESS = 'IN_PROGRESS';
const SUBMITTED = 'SUBMITTED';
const EXPIRED = 'EXPIRED';

class AppError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.statusCode = statusCode;
  }
}

function requireClient(user) {
  if (!user || !CLIENT_ROLES.has(user.role)) {
    throw new AppError(403, 'Only authenticated clients or students can access attempts');
  }
}

function isExamAvailable(exam, now) {
  if (!exam || exam.isAvailable === false || exam.status === 'UNAVAILABLE') {
    return false;
  }
  if (exam.availableFrom && now < new Date(exam.availableFrom)) {
    return false;
  }
  if (exam.availableUntil && now > new Date(exam.availableUntil)) {
    return false;
  }
  return true;
}

function getExamQuestions(examId) {
  return Array.from(questions.values()).filter((question) => question.examId === examId);
}

function sanitizeQuestion(question) {
  return {
    id: question.id,
    text: question.text,
    options: question.options,
  };
}

function startAttempt({ examId, user, now = new Date() }) {
  requireClient(user);

  const exam = exams.get(examId);
  if (!exam) {
    throw new AppError(404, 'Exam not found');
  }
  if (!isExamAvailable(exam, now)) {
    throw new AppError(400, 'Exam is not available');
  }

  const selectedQuestions = getExamQuestions(examId).slice(0, REQUIRED_QUESTION_COUNT);
  if (selectedQuestions.length < REQUIRED_QUESTION_COUNT) {
    throw new AppError(400, 'At least 10 questions are required to start this exam');
  }

  const startedAt = now;
  const durationMinutes = Number(exam.durationMinutes || 0);
  const endsAt = new Date(startedAt.getTime() + durationMinutes * 60 * 1000);
  const attempt = {
    id: nextAttemptId(),
    examId,
    userId: user.id,
    questionIds: selectedQuestions.map((question) => question.id),
    startedAt: startedAt.toISOString(),
    endsAt: endsAt.toISOString(),
    status: IN_PROGRESS,
    result: null,
  };
  attempts.set(attempt.id, attempt);

  return {
    attempt: { ...attempt },
    questions: selectedQuestions.map(sanitizeQuestion),
  };
}

function getAttempt({ attemptId, user }) {
  requireClient(user);
  const attempt = attempts.get(attemptId);
  if (!attempt) {
    throw new AppError(404, 'Attempt not found');
  }
  if (attempt.userId !== user.id) {
    throw new AppError(403, 'Attempt does not belong to the logged-in user');
  }
  const attemptQuestions = attempt.questionIds.map((questionId) => sanitizeQuestion(questions.get(questionId)));
  return { ...attempt, questions: attemptQuestions };
}

function validateAnswer(answer, attemptQuestionIds) {
  if (!answer || !attemptQuestionIds.includes(answer.questionId)) {
    throw new AppError(400, 'Answer question IDs must belong to the attempt');
  }
  const question = questions.get(answer.questionId);
  if (!Number.isInteger((answer.answerIndex ?? answer.answer)) || (answer.answerIndex ?? answer.answer) < 0 || (answer.answerIndex ?? answer.answer) >= question.options.length) {
    throw new AppError(400, 'Answer indexes must match an available option');
  }
}

function submitAttempt({ attemptId, user, answers = [], now = new Date() }) {
  requireClient(user);
  const attempt = attempts.get(attemptId);
  if (!attempt) {
    throw new AppError(404, 'Attempt not found');
  }
  if (attempt.userId !== user.id) {
    throw new AppError(403, 'Attempt does not belong to the logged-in user');
  }
  if (attempt.status === SUBMITTED) {
    throw new AppError(409, 'Attempt has already been submitted');
  }
  if (attempt.status === EXPIRED || now > new Date(attempt.endsAt)) {
    attempt.status = EXPIRED;
    attempts.set(attempt.id, attempt);
    throw new AppError(409, 'Attempt deadline has expired');
  }
  if (!Array.isArray(answers)) {
    throw new AppError(400, 'Answers must be an array');
  }

  const attemptQuestionIds = attempt.questionIds;
  answers.forEach((answer) => validateAnswer(answer, attemptQuestionIds));
  const answerMap = new Map(answers.map((answer) => [answer.questionId, (answer.answerIndex ?? answer.answer)]));
  const totalQuestions = attemptQuestionIds.length;
  const correctAnswers = attemptQuestionIds.reduce((total, questionId) => {
    const question = questions.get(questionId);
    return total + (answerMap.get(questionId) === question.correctAnswer ? 1 : 0);
  }, 0);
  const incorrectAnswers = totalQuestions - correctAnswers;
  const score = correctAnswers;
  const percentage = Number(((correctAnswers / totalQuestions) * 100).toFixed(2));
  const result = {
    totalQuestions,
    correctAnswers,
    incorrectAnswers,
    score,
    percentage,
    submittedAt: now.toISOString(),
  };

  attempt.status = SUBMITTED;
  attempt.result = result;
  attempts.set(attempt.id, attempt);
  return result;
}

function getResult({ attemptId, user }) {
  requireClient(user);
  const attempt = attempts.get(attemptId);
  if (!attempt) {
    throw new AppError(404, 'Attempt not found');
  }
  if (attempt.userId !== user.id) {
    throw new AppError(403, 'Attempt does not belong to the logged-in user');
  }
  if (!attempt.result) {
    throw new AppError(404, 'Attempt result is not available');
  }
  return attempt.result;
}

export { AppError, startAttempt, getAttempt, submitAttempt, getResult };
