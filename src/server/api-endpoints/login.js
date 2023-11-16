const express = require('express');
const router = express.Router();
const db = require('../database/connection'); // Adjust path as needed

router.post('/login', (req, res) => {
    const { email, password } = req.body;

    // Query to check if a user exists with the provided email and password
    const query = 'SELECT * FROM accounts WHERE email = ? AND password = ?'; // Consider hashing the password

    db.query(query, [email, password], (err, result) => {
        if (err) {
            // If there's an error with the query
            res.status(500).send({ message: 'Error in database operation', error: err });
        } else {
            if (result.length > 0) {
                // User found
                res.status(200).send({ message: 'Login successful' });
            } else {
                // User not found
                res.status(401).send({ message: 'Login failed: Invalid credentials' });
            }
        }
    });
});

module.exports = router;
