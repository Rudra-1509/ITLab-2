import { users } from '../data/store.js';
import { verifyPassword } from '../utils/password.js';
import { createToken } from '../utils/token.js';
function publicUser(user) { return { id: user.id, email: user.email, username: user.username, role: user.role }; }
export async function login(req, res, next) {
  try {
    const { email, username, password } = req.body || {}; const identifier = email || username;
    if (!identifier || !password) return res.status(400).json({ message: 'Email or username and password are required' });
    // TODO(DB): Replace users Map lookup with database teammate's trusted User repository lookup by email/username.
    const user = Array.from(users.values()).find((u) => (u.email === identifier || u.username === identifier) && u.active !== false);
    if (!user || !verifyPassword(password, user.passwordHash)) return res.status(401).json({ message: 'Invalid credentials' });
    const token = createToken({ sub: user.id, id: user.id, role: user.role, email: user.email, username: user.username });
    return res.json({ token, accessToken: token, user: publicUser(user) });
  } catch (e) { return next(e); }
}
