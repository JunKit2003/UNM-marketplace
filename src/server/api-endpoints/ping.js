const db = require('../database/connection.js');

module.exports = async function ping(req, res) {
    try {
        const q = `SELECT * FROM accounts`;

        await db.query(q, '', (err, data) => {
            if (err) {
                return res.status(500).json({ success: false, data: err });
            }

            return res.status(200).json({ success: true, message: "pong!", data: data });
        });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).json({ success: false, message: 'Internal server error', error });
    }
};
