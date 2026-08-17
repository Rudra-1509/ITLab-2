function notImplemented(operation) { throw new Error(`TODO(DB): ${operation} has not been implemented yet.`); }
export async function findUserForLogin(identifier) { void identifier; return notImplemented('find user by username/email for login'); }
export async function listUsersForAdmin(options = {}) { void options; return notImplemented('list users for admin'); }
export async function createExam(examInput) { void examInput; return notImplemented('create exam'); }
export async function listExams(filters = {}) { void filters; return notImplemented('list exams'); }
export async function updateExam(examId, examUpdates) { void examId; void examUpdates; return notImplemented('update exam'); }
export async function deleteExam(examId) { void examId; return notImplemented('delete exam'); }
export async function createQuestion(examId, questionInput) { void examId; void questionInput; return notImplemented('create question'); }
export async function updateQuestion(questionId, questionUpdates) { void questionId; void questionUpdates; return notImplemented('update question'); }
export async function deleteQuestion(questionId) { void questionId; return notImplemented('delete question'); }
export async function fetchTenQuestionsForExam(examId) { void examId; return notImplemented('fetch exactly 10 questions for an exam'); }
export async function createExamAttempt(attemptInput) { void attemptInput; return notImplemented('create exam attempt'); }
export async function fetchAttemptById(attemptId) { void attemptId; return notImplemented('fetch attempt by ID'); }
export async function saveSubmittedAnswers(attemptId, answers) { void attemptId; void answers; return notImplemented('save submitted answers'); }
export async function saveCalculatedResult(attemptId, resultInput) { void attemptId; void resultInput; return notImplemented('save calculated result'); }
export async function fetchResultByAttemptId(attemptId) { void attemptId; return notImplemented('fetch result by attempt ID'); }
