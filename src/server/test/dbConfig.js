export function testDbConfig() {
  return {
    host: process.env.TEST_DB_HOST ?? '127.0.0.1',
    port: Number(process.env.TEST_DB_PORT ?? 3307),
    user: process.env.TEST_DB_USER ?? 'unm',
    password: process.env.TEST_DB_PASSWORD ?? 'unmpass',
    database: process.env.TEST_DB_NAME ?? 'unm_test',
  };
}
