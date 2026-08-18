import * as store from "../models/store.js";
function hasOwn(o, k) {
  return Object.prototype.hasOwnProperty.call(o, k);
}
export function validateExamPayload(body, partial = false) {
  const errors = [];
  if (!partial || hasOwn(body, "title")) {
    if (typeof body.title !== "string" || !body.title.trim())
      errors.push("title is required");
  }
  if (!partial || hasOwn(body, "durationMinutes")) {
    if (
      typeof body.durationMinutes !== "number" ||
      !Number.isFinite(body.durationMinutes) ||
      body.durationMinutes <= 0
    )
      errors.push("durationMinutes must be a positive number");
  }
  return errors;
}
export async function createExam(req, res, next) {
  try {
    const errors = validateExamPayload(req.body);
    if (errors.length) return res.status(400).json({ errors });
    const exam = await store.createExam({
      title: req.body.title.trim(),
      durationMinutes: req.body.durationMinutes,
      isAvailable: req.body.isAvailable,
      createdBy: req.user?.id,
    });
    return res.status(201).json(exam);
  } catch (e) {
    return next(e);
  }
}
export async function listExams(req, res, next) {
  try {
    const exams = await store.listExams();
    const sanitized = await Promise.all(exams.map(store.sanitizeExam));
    return res.json({ data: sanitized });
  } catch (e) {
    return next(e);
  }
}
export async function getExam(req, res, next) {
  try {
    const exam = await store.getExam(req.params.examId);
    if (!exam) return res.status(404).json({ message: "Exam not found" });
    const sanitized = await store.sanitizeExam(exam);
    return res.json(sanitized);
  } catch (e) {
    return next(e);
  }
}
export async function updateExam(req, res, next) {
  try {
    const existing = await store.getExam(req.params.examId);
    if (!existing) return res.status(404).json({ message: "Exam not found" });
    if (!(await store.canManageExamResource(req.user, existing._id || existing.id)))
      return res.status(403).json({
        message: "Only the owning examiner or an admin can modify this exam",
      });
    const errors = validateExamPayload(req.body, true);
    if (errors.length) return res.status(400).json({ errors });
    const updates = {};
    if (hasOwn(req.body, "title")) updates.title = req.body.title.trim();
    if (hasOwn(req.body, "durationMinutes"))
      updates.durationMinutes = req.body.durationMinutes;
    if (hasOwn(req.body, "isAvailable"))
      updates.isAvailable = Boolean(req.body.isAvailable);
    const exam = await store.updateExam(req.params.examId, updates);
    return res.json(exam);
  } catch (e) {
    return next(e);
  }
}
export async function deleteExam(req, res, next) {
  try {
    const existing = await store.getExam(req.params.examId);
    if (!existing) return res.status(404).json({ message: "Exam not found" });
    if (!(await store.canManageExamResource(req.user, existing._id || existing.id)))
      return res.status(403).json({
        message: "Only the owning examiner or an admin can delete this exam",
      });
    await store.deleteExam(req.params.examId);
    return res.status(204).send();
  } catch (e) {
    return next(e);
  }
}
