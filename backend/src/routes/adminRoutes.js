import express from 'express';
import { getSummary, getExams, getUsers } from '../controllers/adminController.js';
import { authenticate, requireAdmin } from '../middleware/authMiddleware.js';
const router=express.Router(); router.get('/summary', authenticate, requireAdmin, getSummary); router.get('/exams', authenticate, requireAdmin, getExams); router.get('/users', authenticate, requireAdmin, getUsers); export default router;
