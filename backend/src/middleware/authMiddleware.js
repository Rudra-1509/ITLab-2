import { verifyToken } from '../utils/token.js';

export function authenticate(req, res, next) {
  const [scheme, token] = (req.headers.authorization || '').split(' ');
  if (scheme !== 'Bearer' || !token) return res.status(401).json({ message: 'Authentication token is required' });
  try { req.user = verifyToken(token); return next(); }
  catch { return res.status(401).json({ message: 'Invalid or expired authentication token' }); }
}
export const requireAuth = authenticate;
export function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user) return res.status(401).json({ message: 'Authentication is required' });
    if (!roles.includes(req.user.role)) return res.status(403).json({ message: 'Insufficient permissions' });
    return next();
  };
}
export const requireAdmin = requireRole('ADMIN');
export const requireExaminer = requireRole('ADMIN', 'EXAMINER');
export const requireClient = requireRole('CLIENT', 'STUDENT');
