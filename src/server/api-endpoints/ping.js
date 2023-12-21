const db = require('../database/connection.js');

module.exports = async function ping(req, res) {

    const q = `SELECT * FROM accounts`;

    await db.query(q, '', (err,data) => {
        if (err) return res.status(500).json({success: "false", data: err});

        return res.status(200).json({success: "pong!", data: data});

    });
}