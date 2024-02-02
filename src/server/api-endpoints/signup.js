const db = require('../database/connection.js');
const bcrypt = require('bcrypt');
const saltRounds = 10;

module.exports = async function signup(req, res){
    console.log("IN register backend");
    const { first_name, last_name, username, email, password } = req.body;

    // Check if the username and email already exist in the database
    const usernameCheckQuery = 'SELECT username FROM accounts WHERE username = ?';
    const emailCheckQuery = 'SELECT email FROM accounts WHERE email = ?';

    try {
        const [usernameResult, emailResult] = await Promise.all([
            db.query(usernameCheckQuery, [username]),
            db.query(emailCheckQuery, [email])
        ]);

        if (usernameResult.length > 0) {
            // Username already exists
            return res.status(400).send({ message: 'Username already exists' });
        }

        if (emailResult.length > 0) {
            // Email already exists
            return res.status(400).send({ message: 'Email already exists' });
        }

        // Hash the password
        const hashedPassword = await bcrypt.hash(password, saltRounds);

        // Insert the new user into the database
        const insertQuery = 'INSERT INTO accounts (first_name, last_name, username, email, password) VALUES (?, ?, ?, ?, ?)';
        await db.query(insertQuery, [first_name, last_name, username, email, hashedPassword]);
        
        res.status(200).send({ message: 'User registered successfully' });
    } catch (error) {
        res.status(500).send({ message: 'Error in database operation', error: error });
    }
}
