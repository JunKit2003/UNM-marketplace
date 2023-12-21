const db = require('../database/connection.js');
const bcrypt = require('bcrypt');
const saltRounds = 10;

module.exports = async function signup(req, res){
    console.log("IN register backend");
    const { first_name, last_name, username, email, password } = req.body;

    // Check if the email already exists in the database
    const emailCheckQuery = 'SELECT email FROM accounts WHERE email = ?';
    await db.query(emailCheckQuery, [email], async (emailErr, emailResult) => {
        if (emailErr) {
            return res.status(500).send({ message: 'Error checking email', error: emailErr });
        }

        if (emailResult.length > 0) {
            // Email already exists
            return res.status(400).send({ message: 'Email already registered' });
        }

        try {
            // Hash the password
            const hashedPassword = await bcrypt.hash(password, saltRounds);

            // Insert the new user into the database
            const insertQuery = 'INSERT INTO accounts (first_name, last_name, username, email, password) VALUES (?, ?, ?, ?, ?)';
            await db.query(insertQuery, [first_name, last_name, username, email, hashedPassword], (insertErr, insertResult) => {
                if (insertErr) {
                    return res.status(500).send({ message: 'Error in database operation', error: insertErr });
                }
                res.status(200).send({ message: 'User registered successfully' });
            });
        } catch (hashErr) {
            res.status(500).send({ message: 'Error hashing password', error: hashErr });
        }
    });
}