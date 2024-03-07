const { config } = require('dotenv');
const { parsed } = config();
const mysql = require('mysql');
const util = require('util');

const db = mysql.createConnection({

    host: `${parsed.HOST}`,
    user: `${parsed.DATABASE_USERNAME}`,
    password: `${parsed.DATABASE_PASSWORD}`,
    database: `${parsed.DATABASE}`
});

// To use db.query with the async / await style.
db.query = util.promisify(db.query); 

module.exports = db;