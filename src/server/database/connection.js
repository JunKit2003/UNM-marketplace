const { config } = require('dotenv');
const { parsed } = config();
const mysql = require('mysql');

const db = mysql.createConnection({

    host: `${parsed.HOST}`,
    user: `${parsed.DATABASE_USERNAME}`,
    password: `${parsed.DATABASE_PASSWORD}`,
    database: `${parsed.DATABASE}`
});

module.exports = db;