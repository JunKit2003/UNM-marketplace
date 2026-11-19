import { badRequest } from './errors.js';

/** Validate req[source] against a zod schema; replaces it with the parsed value (stored on req.valid). */
export function validate(schema, source = 'body') {
  return (req, res, next) => {
    const result = schema.safeParse(req[source] ?? {});
    if (!result.success) {
      const fields = {};
      for (const issue of result.error.issues) {
        const key = issue.path.join('.') || '_';
        fields[key] ??= issue.message;
      }
      const first = Object.values(fields)[0];
      return next(badRequest(first ?? 'Some fields are not valid.', fields));
    }
    req.valid = { ...(req.valid ?? {}), [source]: result.data };
    next();
  };
}
