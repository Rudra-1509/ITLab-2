import User from "../models/User.js";
import Exam from "../models/Exam.js";
import Attempt from "../models/Attempt.js";
import * as store from "../models/store.js";

export async function getSummary(req, res, next) {
  try {
    const [userCount, examCount, attemptCount] = await Promise.all([
      User.countDocuments(),
      Exam.countDocuments(),
      Attempt.countDocuments(),
    ]);
    res.json({
      data: {
        users: userCount,
        exams: examCount,
        attempts: attemptCount,
      },
    });
  } catch (e) {
    next(e);
  }
}

export async function getExams(req, res, next) {
  try {
    const exams = await store.listExams();
    const sanitized = await Promise.all(exams.map(store.sanitizeExam));
    res.json({ data: sanitized });
  } catch (e) {
    next(e);
  }
}

export async function getUsers(req, res, next) {
  try {
    const users = await User.find().select("-passwordHash").lean();
    res.json({
      data: users.map((u) => ({ ...u, id: u._id })),
    });
  } catch (e) {
    next(e);
  }
}
