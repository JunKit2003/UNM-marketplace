import mysql from 'mysql2/promise';

export function createPool(db) {
  return mysql.createPool({
    ...db,
    connectionLimit: 10,
    multipleStatements: true,
    charset: 'utf8mb4',
    timezone: 'Z',
  });
}
