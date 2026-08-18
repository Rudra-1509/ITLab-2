import User from "../models/User.js";
import Exam from "../models/Exam.js";
import Question from "../models/Question.js";
import Attempt from "../models/Attempt.js";

// ── User operations ──────────────────────────────────────────────────────────

export async function findUserForLogin(identifier) {
  return User.findOne({
    $or: [{ email: identifier }, { username: identifier }],
    active: true,
  });
}

export async function listUsersForAdmin(options = {}) {
  return User.find(options).select("-passwordHash").lean();
}

// ── Exam operations ──────────────────────────────────────────────────────────

export async function createExam(examInput) {
  const exam = await Exam.create(examInput);
  return exam.toObject();
}

export async function listExams(filters = {}) {
  return Exam.find(filters).lean();
}

export async function getExam(examId) {
  return Exam.findById(examId).lean();
}

export async function updateExam(examId, examUpdates) {
  return Exam.findByIdAndUpdate(examId, examUpdates, { new: true }).lean();
}

export async function deleteExam(examId) {
  const exam = await Exam.findByIdAndDelete(examId).lean();
  if (exam) {
    await Question.deleteMany({ examId });
  }
  return exam;
}

// ── Question operations ──────────────────────────────────────────────────────

export async function createQuestion(examId, questionInput) {
  const question = await Question.create({ ...questionInput, examId });
  return question.toObject();
}

export async function updateQuestion(questionId, questionUpdates) {
  return Question.findByIdAndUpdate(questionId, questionUpdates, {
    new: true,
  }).lean();
}

export async function deleteQuestion(questionId) {
  return Question.findByIdAndDelete(questionId).lean();
}

export async function getQuestion(questionId) {
  return Question.findById(questionId).lean();
}

export async function getQuestionsForExam(examId) {
  return Question.find({ examId }).lean();
}

export async function fetchTenQuestionsForExam(examId) {
  return Question.find({ examId }).limit(10).lean();
}

// ── Attempt operations ───────────────────────────────────────────────────────

export async function createExamAttempt(attemptInput) {
  const attempt = await Attempt.create(attemptInput);
  return attempt.toObject();
}

export async function fetchAttemptById(attemptId) {
  return Attempt.findById(attemptId).lean();
}

export async function saveSubmittedAnswers(attemptId, answers) {
  return Attempt.findByIdAndUpdate(
    attemptId,
    { answers },
    { new: true },
  ).lean();
}

export async function saveCalculatedResult(attemptId, resultInput) {
  return Attempt.findByIdAndUpdate(
    attemptId,
    { result: resultInput, status: "SUBMITTED" },
    { new: true },
  ).lean();
}

export async function updateAttemptStatus(attemptId, status) {
  return Attempt.findByIdAndUpdate(
    attemptId,
    { status },
    { new: true },
  ).lean();
}

export async function fetchResultByAttemptId(attemptId) {
  const attempt = await Attempt.findById(attemptId).lean();
  return attempt?.result || null;
}
