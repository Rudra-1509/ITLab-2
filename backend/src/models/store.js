import { exams, questions, nextExamId, nextQuestionId } from '../data/store.js';

export function createExam(data) {
  const id = nextExamId();
  const exam = { id, title: data.title, durationMinutes: data.durationMinutes, isAvailable: data.isAvailable ?? true, createdBy: data.createdBy, questions: [] };
  exams.set(id, exam); return exam;
}
export function updateExam(id, data) { const exam = exams.get(id); if (!exam) return null; const updated = { ...exam, ...data, id }; exams.set(id, updated); return updated; }
export function deleteExam(id) { const exam = exams.get(id); if (!exam) return null; for (const q of exam.questions) questions.delete(q); exams.delete(id); return exam; }
export function createQuestion(examId, data) { const exam = exams.get(examId); if (!exam) return null; const id = nextQuestionId(); const question = { id, examId, text: data.text, options: data.options, correctAnswer: data.correctAnswer, marks: data.marks ?? 1 }; questions.set(id, question); exam.questions.push(id); return question; }
export function updateQuestion(id, data) { const q = questions.get(id); if (!q) return null; const updated = { ...q, ...data, id, examId: q.examId }; questions.set(id, updated); return updated; }
export function deleteQuestion(id) { const q = questions.get(id); if (!q) return null; const exam = exams.get(q.examId); if (exam) exam.questions = exam.questions.filter((qid) => qid !== id); questions.delete(id); return q; }
export function getExam(id) { return exams.get(id) || null; }
export function listExams() { return Array.from(exams.values()); }
export function getQuestionsForExam(examId) { return Array.from(questions.values()).filter((q) => q.examId === examId); }
export function sanitizeQuestion(q) { return { id: q.id, text: q.text, options: q.options }; }
export function sanitizeExam(exam) { return { ...exam, questions: getQuestionsForExam(exam.id).map(sanitizeQuestion) }; }
