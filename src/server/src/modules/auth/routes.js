import bcrypt from 'bcrypt';
import { z } from 'zod';
import { HttpError } from '../../http/errors.js';
import { requireUser } from '../../http/auth.js';
import { endSession, startSession } from '../../http/session.js';
import { validate } from '../../http/validate.js';
import { createGuest, findUserByEmail, findUserById, insertUser } from '../users/repo.js';
import { serializeUser } from '../users/serialize.js';

const BCRYPT_COST = 12;
const EMAIL_TAKEN = 'That email is already registered.';
const USERNAME_TAKEN = 'That username is taken.';
const WRONG_LOGIN = 'Email or password is wrong.';

const name = (label) => z.string().trim().min(1, `${label} is required.`).max(60);

export const signupSchema = z.object({
  firstName: name('First name'),
  lastName: z.string().trim().max(60).default(''),
  username: z
    .string()
    .trim()
    .toLowerCase()
    .regex(/^[a-z0-9._]{3,30}$/, 'Use 3–30 letters, numbers, dots or underscores.')
    .refine((u) => !u.startsWith('guest-'), 'That username is reserved.'),
  email: z.string().trim().toLowerCase().email('Enter a valid email address.').max(255),
  phone: z.string().trim().max(30).default(''),
  password: z.string().min(8, 'Use at least 8 characters.').max(200),
});

const loginSchema = z.object({
  email: z.string().trim().toLowerCase().min(1, 'Enter your email.'),
  password: z.string().min(1, 'Enter your password.'),
});

export function registerAuth(api, { pool, hooks, limits }) {
  api.post('/auth/signup', limits.signup, validate(signupSchema), async (req, res) => {
    const b = req.valid.body;
    if (await findUserByEmail(pool, b.email)) {
      throw new HttpError(409, 'conflict', EMAIL_TAKEN, { email: EMAIL_TAKEN });
    }
    let user;
    try {
      user = await insertUser(pool, { ...b, passwordHash: await bcrypt.hash(b.password, BCRYPT_COST) });
    } catch (err) {
      if (err.code !== 'ER_DUP_ENTRY') throw err;
      if (String(err.message).includes('uq_users_email')) throw new HttpError(409, 'conflict', EMAIL_TAKEN, { email: EMAIL_TAKEN });
      throw new HttpError(409, 'conflict', USERNAME_TAKEN, { username: USERNAME_TAKEN });
    }
    await startSession(req, user);
    res.status(201).json(serializeUser(user));
  });

  api.post('/auth/login', limits.login, validate(loginSchema), async (req, res) => {
    const { email, password } = req.valid.body;
    const user = await findUserByEmail(pool, email);
    const ok = user?.password_hash ? await bcrypt.compare(password, user.password_hash) : false;
    if (!ok) throw new HttpError(401, 'unauthenticated', WRONG_LOGIN);
    await startSession(req, user);
    res.json(serializeUser(user));
  });

  api.post('/auth/demo', limits.demo, async (req, res) => {
    const guest = await createGuest(pool);
    await hooks.onGuestCreated?.(guest);
    await startSession(req, guest);
    res.status(201).json(serializeUser(guest));
  });

  api.post('/auth/logout', async (req, res) => {
    await endSession(req);
    res.clearCookie('unm.sid');
    res.status(204).end();
  });

  api.get('/auth/me', requireUser, async (req, res) => {
    const user = await findUserById(pool, req.session.userId);
    if (!user) {
      await endSession(req);
      throw new HttpError(401, 'unauthenticated', 'Please log in first.');
    }
    res.json(serializeUser(user));
  });
}
