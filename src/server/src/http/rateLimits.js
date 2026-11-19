import { rateLimit } from 'express-rate-limit';
import { HttpError } from './errors.js';

const limiter = (opts) =>
  rateLimit({
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    handler: (req, res, next) =>
      next(new HttpError(429, 'rate_limited', opts.message ?? 'Too many attempts. Please wait a bit and try again.')),
    ...opts,
  });

/** Fresh limiter instances per app, so each test app starts with clean counters. */
export function createRateLimits() {
  return {
    login: limiter({ windowMs: 15 * 60_000, limit: 10, skipSuccessfulRequests: true }),
    signup: limiter({ windowMs: 60 * 60_000, limit: 5 }),
    demo: limiter({ windowMs: 60 * 60_000, limit: 10 }),
    createListing: limiter({ windowMs: 24 * 60 * 60_000, limit: 20, message: "You've posted a lot today. Try again tomorrow." }),
    uploads: limiter({ windowMs: 60_000, limit: 30 }),
    messages: limiter({ windowMs: 60_000, limit: 60, message: "You're sending messages too fast." }),
  };
}
