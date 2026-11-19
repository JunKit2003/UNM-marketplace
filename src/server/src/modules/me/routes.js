import bcrypt from 'bcrypt';
import { z } from 'zod';
import { badRequest, HttpError } from '../../http/errors.js';
import { requireNonGuest, requireUser } from '../../http/auth.js';
import { validate } from '../../http/validate.js';
import { deleteUpload, imageUpload, PHOTO_ERROR, processImage, saveUpload } from '../../images/process.js';
import { findUserById, updateUser } from '../users/repo.js';
import { serializeUser } from '../users/serialize.js';

const profileSchema = z.object({
  firstName: z.string().trim().min(1, 'First name is required.').max(60).optional(),
  lastName: z.string().trim().max(60).optional(),
  phone: z.string().trim().max(30).optional(),
});

const passwordSchema = z.object({
  currentPassword: z.string().min(1, 'Enter your current password.'),
  newPassword: z.string().min(8, 'Use at least 8 characters.').max(200),
});

export function registerMe(api, { pool, config, limits }) {
  api.patch('/me', requireUser, validate(profileSchema), async (req, res) => {
    const user = await updateUser(pool, req.session.userId, req.valid.body);
    res.json(serializeUser(user));
  });

  api.put('/me/password', requireNonGuest, validate(passwordSchema), async (req, res) => {
    const { currentPassword, newPassword } = req.valid.body;
    const user = await findUserById(pool, req.session.userId);
    if (!user?.password_hash) throw new HttpError(403, 'forbidden', "Guest accounts can't set a password.");
    if (!(await bcrypt.compare(currentPassword, user.password_hash))) {
      throw badRequest('Your current password is wrong.', { currentPassword: 'Your current password is wrong.' });
    }
    await updateUser(pool, user.id, { passwordHash: await bcrypt.hash(newPassword, 12) });
    res.status(204).end();
  });

  api.put('/me/photo', requireUser, limits.uploads, imageUpload.single('photo'), async (req, res) => {
    if (!req.file) throw badRequest(PHOTO_ERROR);
    const webp = await processImage(req.file.buffer, { maxSize: 512 });
    const before = await findUserById(pool, req.session.userId);
    const rel = await saveUpload(config.uploadDir, webp, 'avatars');
    const user = await updateUser(pool, before.id, { avatarPath: rel });
    await deleteUpload(config.uploadDir, before.avatar_path);
    res.json(serializeUser(user));
  });
}
