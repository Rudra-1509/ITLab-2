import express from 'express';
import * as attemptController from '../controllers/attemptController.js';
import { authenticate, requireClient } from '../middleware/authMiddleware.js';
const router=express.Router();
router.post('/exams/:examId/start', authenticate, requireClient, attemptController.startAttempt);
router.get('/attempts/:attemptId', authenticate, requireClient, attemptController.getAttempt);
router.post('/attempts/:attemptId/submit', authenticate, requireClient, attemptController.submitAttempt);
router.get('/attempts/:attemptId/result', authenticate, requireClient, attemptController.getResult);
export default router;
