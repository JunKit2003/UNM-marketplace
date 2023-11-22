const express = require('express');
const router = express.Router();
const db = require('../database/connection'); // Adjust path as needed
const bcrypt = require('bcrypt');

router.post('/login', (req, res) => {
    const { email, password } = req.body;

    // Query to find user by email
    const query = 'SELECT * FROM accounts WHERE email = ?';
    db.query(query, [email], async (err, result) => {
        if (err) {
            res.status(500).send({ message: 'Error in database operation', error: err });
        } else {
            if (result.length > 0) {
                // User found, now compare hashed password
                const match = await bcrypt.compare(password, result[0].password);
                if (match) {
                    res.status(200).send({ message: 'Login successful' });
                } else {
                    res.status(401).send({ message: 'Login failed: Invalid credentials' });
                }
            } else {
                // User not found
                res.status(401).send({ message: 'Login failed: Invalid credentials' });
            }
        }
    });
});

module.exports = router;
