import * as dataStore from "./dataStore.js";

const REQUIRED_QUESTION_COUNT = 10;
const CLIENT_ROLES = new Set(["CLIENT", "STUDENT"]);
const IN_PROGRESS = "IN_PROGRESS";
const SUBMITTED = "SUBMITTED";
const EXPIRED = "EXPIRED";

class AppError extends Error {
  constructor(statusCode, message) {
    super(message);
    this.statusCode = statusCode;
  }
}

function requireClient(user) {
  if (!user || !CLIENT_ROLES.has(user.role)) {
    throw new AppError(
      403,
      "Only authenticated clients or students can access attempts",
    );
  }
}

function isExamAvailable(exam, now) {
  if (!exam || exam.isAvailable === false || exam.status === "UNAVAILABLE") {
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

function sanitizeQuestion(question) {
  return {
    id: question._id || question.id,
    text: question.text,
    options: question.options,
  };
}

async function startAttempt({ examId, user, now = new Date() }) {
  requireClient(user);

  const exam = await dataStore.getExam(examId);
  if (!exam) {
    throw new AppError(404, "Exam not found");
  }
  if (!isExamAvailable(exam, now)) {
    throw new AppError(400, "Exam is not available");
  }

  const selectedQuestions = await dataStore.fetchTenQuestionsForExam(examId);
  if (selectedQuestions.length < REQUIRED_QUESTION_COUNT) {
    throw new AppError(
      400,
      "At least 10 questions are required to start this exam",
    );
  }

  const startedAt = now;
  const durationMinutes = Number(exam.durationMinutes || 0);
  const endsAt = new Date(startedAt.getTime() + durationMinutes * 60 * 1000);

  const attempt = await dataStore.createExamAttempt({
    examId: exam._id || exam.id,
    userId: user.id,
    questionIds: selectedQuestions.map((q) => q._id || q.id),
    startedAt: startedAt.toISOString(),
    endsAt: endsAt.toISOString(),
    status: IN_PROGRESS,
    result: null,
  });

  return {
    attempt: { ...attempt, id: attempt._id || attempt.id },
    questions: selectedQuestions.map(sanitizeQuestion),
  };
}

async function getAttempt({ attemptId, user }) {
  requireClient(user);
  const attempt = await dataStore.fetchAttemptById(attemptId);
  if (!attempt) {
    throw new AppError(404, "Attempt not found");
  }
  if (String(attempt.userId) !== String(user.id)) {
    throw new AppError(403, "Attempt does not belong to the logged-in user");
  }

  // Fetch the questions for this attempt
  const questionPromises = attempt.questionIds.map((qId) =>
    dataStore.getQuestion(qId),
  );
  const attemptQuestions = (await Promise.all(questionPromises))
    .filter(Boolean)
    .map(sanitizeQuestion);

  return {
    ...attempt,
    id: attempt._id || attempt.id,
    questions: attemptQuestions,
  };
}

function validateAnswer(answer, attemptQuestionIds) {
  const qIds = attemptQuestionIds.map(String);
  if (!answer || !qIds.includes(String(answer.questionId))) {
    throw new AppError(400, "Answer question IDs must belong to the attempt");
  }
}

async function submitAttempt({
  attemptId,
  user,
  answers = [],
  now = new Date(),
}) {
  requireClient(user);
  const attempt = await dataStore.fetchAttemptById(attemptId);
  if (!attempt) {
    throw new AppError(404, "Attempt not found");
  }
  if (String(attempt.userId) !== String(user.id)) {
    throw new AppError(403, "Attempt does not belong to the logged-in user");
  }
  if (attempt.status === SUBMITTED) {
    throw new AppError(409, "Attempt has already been submitted");
  }
  if (attempt.status === EXPIRED || now > new Date(attempt.endsAt)) {
    await dataStore.updateAttemptStatus(attemptId, EXPIRED);
    throw new AppError(409, "Attempt deadline has expired");
  }
  if (!Array.isArray(answers)) {
    throw new AppError(400, "Answers must be an array");
  }

  const attemptQuestionIds = attempt.questionIds;
  answers.forEach((answer) => validateAnswer(answer, attemptQuestionIds));

  // Save the submitted answers
  const answerDocs = answers.map((a) => ({
    questionId: a.questionId,
    answerIndex: a.answerIndex ?? a.answer,
  }));
  await dataStore.saveSubmittedAnswers(attemptId, answerDocs);

  // Calculate score
  const answerMap = new Map(
    answers.map((answer) => [
      String(answer.questionId),
      answer.answerIndex ?? answer.answer,
    ]),
  );

  const totalQuestions = attemptQuestionIds.length;
  let correctAnswers = 0;
  for (const questionId of attemptQuestionIds) {
    const question = await dataStore.getQuestion(questionId);
    if (question && answerMap.get(String(questionId)) === question.correctAnswer) {
      correctAnswers++;
    }
  }

  const incorrectAnswers = totalQuestions - correctAnswers;
  const score = correctAnswers;
  const percentage = Number(
    ((correctAnswers / totalQuestions) * 100).toFixed(2),
  );
  const result = {
    totalQuestions,
    correctAnswers,
    incorrectAnswers,
    score,
    percentage,
    submittedAt: now.toISOString(),
  };

  await dataStore.saveCalculatedResult(attemptId, result);
  return result;
}

async function getResult({ attemptId, user }) {
  requireClient(user);
  const attempt = await dataStore.fetchAttemptById(attemptId);
  if (!attempt) {
    throw new AppError(404, "Attempt not found");
  }
  if (String(attempt.userId) !== String(user.id)) {
    throw new AppError(403, "Attempt does not belong to the logged-in user");
  }
  if (!attempt.result) {
    throw new AppError(404, "Attempt result is not available");
  }
  return attempt.result;
}

export { AppError, startAttempt, getAttempt, submitAttempt, getResult };
