import * as attemptService from '../services/attemptService.js';
function sendError(res,error){res.status(error.statusCode||500).json({error:error.message||'Internal server error'});}
export function startAttempt(req,res){try{const payload=attemptService.startAttempt({examId:req.params.examId,user:req.user}); res.status(201).json({attemptId:payload.attempt.id, examId:payload.attempt.examId, startedAt:payload.attempt.startedAt, endsAt:payload.attempt.endsAt, questions:payload.questions, attempt:payload.attempt});}catch(e){sendError(res,e)}}
export function getAttempt(req,res){try{res.json(attemptService.getAttempt({attemptId:req.params.attemptId,user:req.user}));}catch(e){sendError(res,e)}}
export function submitAttempt(req,res){try{res.json({result:attemptService.submitAttempt({attemptId:req.params.attemptId,user:req.user,answers:req.body.answers})});}catch(e){sendError(res,e)}}
export function getResult(req,res){try{res.json({result:attemptService.getResult({attemptId:req.params.attemptId,user:req.user})});}catch(e){sendError(res,e)}}
