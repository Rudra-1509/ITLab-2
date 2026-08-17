import crypto from 'node:crypto';
import env from '../config/env.js';

function b64url(value) { return Buffer.from(JSON.stringify(value)).toString('base64url'); }
function sign(data) { return crypto.createHmac('sha256', env.jwtSecret).update(data).digest('base64url'); }

export function createToken(payload) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const body = { ...payload, iat: now, exp: now + env.jwtExpiresInSeconds };
  const unsigned = `${b64url(header)}.${b64url(body)}`;
  return `${unsigned}.${sign(unsigned)}`;
}

export function verifyToken(token) {
  const [header, payload, signature] = token.split('.');
  if (!header || !payload || !signature) throw new Error('Invalid token');
  const unsigned = `${header}.${payload}`;
  if (sign(unsigned) !== signature) throw new Error('Invalid token');
  const decoded = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8'));
  if (decoded.exp && decoded.exp < Math.floor(Date.now() / 1000)) throw new Error('Expired token');
  return decoded;
}
