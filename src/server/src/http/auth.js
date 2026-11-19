import { HttpError } from './errors.js';

export function requireUser(req, res, next) {
  if (!req.session?.userId) return next(new HttpError(401, 'unauthenticated', 'Please log in first.'));
  next();
}

export function requireNonGuest(req, res, next) {
  if (!req.session?.userId) return next(new HttpError(401, 'unauthenticated', 'Please log in first.'));
  if (req.session.isGuest) return next(new HttpError(403, 'forbidden', "Guest accounts can't do that."));
  next();
}
