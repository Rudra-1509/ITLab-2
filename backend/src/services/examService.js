export { createExam, updateExam, deleteExam, listExams, getExam, getQuestionsForExam, sanitizeExam, sanitizeQuestion } from '../models/store.js';
export function getAdminSummary() { return { message: 'Use /api/admin/summary for current summary data.' }; }
