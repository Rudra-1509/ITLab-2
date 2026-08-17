import { attempts, users } from '../data/store.js';
import { listExams, sanitizeExam } from '../models/store.js';
export function getSummary(req,res){res.json({data:{users:users.size, exams:listExams().length, attempts:attempts.size}})}
export function getExams(req,res){res.json({data:listExams().map(sanitizeExam)})}
export function getUsers(req,res){res.json({data:Array.from(users.values()).map(({passwordHash,...u})=>u)})}
