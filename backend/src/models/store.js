import * as dataStore from "../services/dataStore.js";

export async function canManageExam(user, exam) {
  return user?.role === "ADMIN" || String(exam.createdBy) === String(user?.id);
}

export async function getQuestion(id) {
  return dataStore.getQuestion(id);
}

export async function canManageExamResource(user, examId) {
  const exam = await dataStore.getExam(examId);
  return Boolean(exam && (await canManageExam(user, exam)));
}

export async function createExam(data) {
  return dataStore.createExam({
    title: data.title,
    durationMinutes: data.durationMinutes,
    isAvailable: data.isAvailable ?? true,
    createdBy: data.createdBy,
  });
}

export async function updateExam(id, data) {
  return dataStore.updateExam(id, data);
}

export async function deleteExam(id) {
  return dataStore.deleteExam(id);
}

export async function createQuestion(examId, data) {
  const exam = await dataStore.getExam(examId);
  if (!exam) return null;
  return dataStore.createQuestion(examId, {
    text: data.text,
    options: data.options,
    correctAnswer: data.correctAnswer,
    marks: data.marks ?? 1,
  });
}

export async function updateQuestion(id, data) {
  return dataStore.updateQuestion(id, data);
}

export async function deleteQuestion(id) {
  return dataStore.deleteQuestion(id);
}

export async function getExam(id) {
  return dataStore.getExam(id);
}

export async function listExams() {
  return dataStore.listExams();
}

export async function getQuestionsForExam(examId) {
  return dataStore.getQuestionsForExam(examId);
}

export function sanitizeQuestion(q) {
  return { id: q._id || q.id, text: q.text, options: q.options };
}

export async function sanitizeExam(exam) {
  const questions = await getQuestionsForExam(exam._id || exam.id);
  return {
    ...exam,
    id: exam._id || exam.id,
    questions: questions.map(sanitizeQuestion),
  };
}
