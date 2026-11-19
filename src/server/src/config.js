import { z } from 'zod';

const bool = z
  .enum(['true', 'false', '1', '0'])
  .transform((v) => v === 'true' || v === '1');

const schema = z
  .object({
    NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
    PORT: z.coerce.number().int().positive().default(3000),
    DB_HOST: z.string().default('127.0.0.1'),
    DB_PORT: z.coerce.number().int().positive().default(3306),
    DB_USER: z.string().default('unm'),
    DB_PASSWORD: z.string().default('unmpass'),
    DB_NAME: z.string().default('unm'),
    SESSION_SECRET: z.string().min(16).default('dev-only-secret-change-me-0123456789abcdef'),
    UPLOAD_DIR: z.string().default('/app/uploads'),
    SEED_DEMO: bool.default(true),
    DEMO_REPLY_DELAY_MS: z.coerce.number().int().min(0).default(1500),
    // Number of reverse proxies in front of the api (0 = none). Local compose: 1, VPS: 2.
    TRUST_PROXY: z.coerce.number().int().min(0).max(5).default(0),
    LOG_LEVEL: z.string().default('info'),
    BCRYPT_COST: z.coerce.number().int().min(4).max(15).default(12),
  })
  .superRefine((cfg, ctx) => {
    if (cfg.NODE_ENV === 'production' && cfg.SESSION_SECRET.length < 32) {
      ctx.addIssue({ code: 'custom', path: ['SESSION_SECRET'], message: 'must be at least 32 characters in production' });
    }
    if (cfg.NODE_ENV === 'production' && cfg.SESSION_SECRET.startsWith('dev-only')) {
      ctx.addIssue({ code: 'custom', path: ['SESSION_SECRET'], message: 'must be changed in production' });
    }
  });

/** Parse and validate environment variables. Throws with a readable message on bad config. */
export function loadConfig(env = process.env) {
  const parsed = schema.safeParse(env);
  if (!parsed.success) {
    const lines = parsed.error.issues.map((i) => `  ${i.path.join('.')}: ${i.message}`);
    throw new Error(`Invalid configuration:\n${lines.join('\n')}`);
  }
  const c = parsed.data;
  return {
    env: c.NODE_ENV,
    isProduction: c.NODE_ENV === 'production',
    port: c.PORT,
    db: { host: c.DB_HOST, port: c.DB_PORT, user: c.DB_USER, password: c.DB_PASSWORD, database: c.DB_NAME },
    sessionSecret: c.SESSION_SECRET,
    uploadDir: c.UPLOAD_DIR,
    seedDemo: c.SEED_DEMO,
    demoReplyDelayMs: c.DEMO_REPLY_DELAY_MS,
    trustProxy: c.TRUST_PROXY,
    logLevel: c.LOG_LEVEL,
    bcryptCost: c.BCRYPT_COST,
  };
}
