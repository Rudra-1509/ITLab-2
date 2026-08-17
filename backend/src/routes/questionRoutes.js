import express from 'express';
import { updateQuestion, deleteQuestion } from '../controllers/questionController.js';
import { authenticate, requireExaminer } from '../middleware/authMiddleware.js';
const router=express.Router(); router.put('/:questionId', authenticate, requireExaminer, updateQuestion); router.delete('/:questionId', authenticate, requireExaminer, deleteQuestion); export default router;
