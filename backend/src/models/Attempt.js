import mongoose from "mongoose";

const answerSchema = new mongoose.Schema(
  {
    questionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Question",
      required: true,
    },
    answerIndex: {
      type: Number,
      required: true,
      min: 0,
    },
  },
  { _id: false },
);

const resultSchema = new mongoose.Schema(
  {
    totalQuestions: { type: Number, required: true },
    correctAnswers: { type: Number, required: true },
    incorrectAnswers: { type: Number, required: true },
    score: { type: Number, required: true },
    percentage: { type: Number, required: true },
    submittedAt: { type: Date, required: true },
  },
  { _id: false },
);

const attemptSchema = new mongoose.Schema(
  {
    examId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Exam",
      required: true,
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    questionIds: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Question",
      },
    ],
    startedAt: {
      type: Date,
      required: true,
    },
    endsAt: {
      type: Date,
      required: true,
    },
    status: {
      type: String,
      required: true,
      enum: ["IN_PROGRESS", "SUBMITTED", "EXPIRED"],
      default: "IN_PROGRESS",
    },
    answers: [answerSchema],
    result: {
      type: resultSchema,
      default: null,
    },
  },
  { timestamps: true },
);

attemptSchema.index({ userId: 1 });
attemptSchema.index({ examId: 1 });

const Attempt = mongoose.model("Attempt", attemptSchema);
export default Attempt;
