import ApiError from '../utils/apiError.js';
import env from '../config/env.js';
export function notFound(req, res, next) { next(new ApiError(404, `Route not found: ${req.method} ${req.originalUrl}`)); }
export function errorHandler(err, req, res, next) { // eslint-disable-line no-unused-vars
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({ error: { message: err.message || 'Internal server error', details: err.details || undefined, stack: env.nodeEnv === 'development' ? err.stack : undefined } });
}
