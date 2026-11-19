import multer from 'multer';
import { logger } from '../logger.js';

export class HttpError extends Error {
  constructor(status, code, message, fields) {
    super(message);
    this.status = status;
    this.code = code;
    this.fields = fields;
  }
}

export const notFound = (message = 'Not found.') => new HttpError(404, 'not_found', message);
export const forbidden = (message = "You can't do that.") => new HttpError(403, 'forbidden', message);
export const badRequest = (message, fields) => new HttpError(400, 'validation', message, fields);

export function notFoundHandler(req, res, next) {
  next(notFound());
}

// eslint-disable-next-line no-unused-vars
export function errorHandler(err, req, res, next) {
  let e = err;
  if (err instanceof multer.MulterError) {
    e = err.code === 'LIMIT_FILE_SIZE'
      ? new HttpError(400, 'validation', 'Photos must be JPEG, PNG or WebP, up to 5 MB.')
      : new HttpError(400, 'validation', err.code === 'LIMIT_FILE_COUNT' || err.code === 'LIMIT_UNEXPECTED_FILE'
        ? 'A listing can have up to 6 photos.'
        : 'That upload could not be read.');
  } else if (err?.type === 'entity.parse.failed') {
    e = badRequest('The request body is not valid JSON.');
  } else if (err?.type === 'entity.too.large') {
    e = new HttpError(413, 'too_large', 'That request is too large.');
  } else if (!(err instanceof HttpError)) {
    logger.error({ err }, 'unhandled error');
    e = new HttpError(500, 'internal', 'Something went wrong. Please try again.');
  }
  const body = { error: { code: e.code, message: e.message } };
  if (e.fields) body.error.fields = e.fields;
  res.status(e.status).json(body);
}
