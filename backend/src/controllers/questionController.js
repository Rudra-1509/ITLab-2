import * as store from "../models/store.js";
function hasOwn(o, k) {
  return Object.prototype.hasOwnProperty.call(o, k);
}
export function validateQuestionPayload(body, partial = false) {
  const errors = [];
  if (!partial || hasOwn(body, "text")) {
    if (typeof body.text !== "string" || !body.text.trim())
      errors.push("question text is required");
  }
  if (!partial || hasOwn(body, "options")) {
    if (
      !Array.isArray(body.options) ||
      body.options.length !== 4 ||
      body.options.some((o) => typeof o !== "string" || !o.trim())
    )
      errors.push("options must contain exactly 4 non-empty choices");
  }
  const opts = Array.isArray(body.options) ? body.options : undefined;
  if (!partial || hasOwn(body, "correctAnswer")) {
    const max = opts ? opts.length - 1 : 3;
    if (
      !Number.isInteger(body.correctAnswer) ||
      body.correctAnswer < 0 ||
      body.correctAnswer > max
    )
      errors.push("correctAnswer must be a valid option index");
  }
  if (
    hasOwn(body, "marks") &&
    (typeof body.marks !== "number" ||
      !Number.isFinite(body.marks) ||
      body.marks <= 0)
  )
    errors.push("marks must be a positive number");
  return errors;
}
export async function createQuestion(req, res, next) {
  try {
    const exam = await store.getExam(req.params.examId);
    if (!exam) return res.status(404).json({ message: "Exam not found" });
    if (!(await store.canManageExamResource(req.user, exam._id || exam.id)))
      return res.status(403).json({
        message:
          "Only the owning examiner or an admin can add questions to this exam",
      });
    const errors = validateQuestionPayload(req.body);
    if (errors.length) return res.status(400).json({ errors });
    const q = await store.createQuestion(req.params.examId, {
      text: req.body.text.trim(),
      options: req.body.options,
      correctAnswer: req.body.correctAnswer,
      marks: req.body.marks ?? 1,
    });
    return res.status(201).json(q);
  } catch (e) {
    return next(e);
  }
}
export async function updateQuestion(req, res, next) {
  try {
    const existing = await store.getQuestion(req.params.questionId);
    if (!existing)
      return res.status(404).json({ message: "Question not found" });
    if (!(await store.canManageExamResource(req.user, existing.examId)))
      return res.status(403).json({
        message:
          "Only the owning examiner or an admin can modify this question",
      });
    const errors = validateQuestionPayload(req.body, true);
    if (errors.length) return res.status(400).json({ errors });
    const updates = {};
    if (hasOwn(req.body, "text")) updates.text = req.body.text.trim();
    if (hasOwn(req.body, "options")) updates.options = req.body.options;
    if (hasOwn(req.body, "correctAnswer"))
      updates.correctAnswer = req.body.correctAnswer;
    if (hasOwn(req.body, "marks")) updates.marks = req.body.marks;
    const q = await store.updateQuestion(req.params.questionId, updates);
    return res.json(q);
  } catch (e) {
    return next(e);
  }
}
export async function deleteQuestion(req, res, next) {
  try {
    const existing = await store.getQuestion(req.params.questionId);
    if (!existing)
      return res.status(404).json({ message: "Question not found" });
    if (!(await store.canManageExamResource(req.user, existing.examId)))
      return res.status(403).json({
        message:
          "Only the owning examiner or an admin can delete this question",
      });
    await store.deleteQuestion(req.params.questionId);
    return res.status(204).send();
  } catch (e) {
    return next(e);
  }
}
