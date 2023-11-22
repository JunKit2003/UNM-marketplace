const express = require('express');
const router = express.Router();
const db = require('../database/connection.js');
const bcrypt = require('bcrypt');
const saltRounds = 10; 

router.post('/register', async (req, res) => {
    const { first_name, last_name, email, password } = req.body;

    try {
        // Hash the password before storing it
        const hashedPassword = await bcrypt.hash(password, saltRounds);

        const query = 'INSERT INTO accounts (first_name, last_name, email, password) VALUES (?, ?, ?, ?)';
        db.query(query, [first_name, last_name, email, hashedPassword], (err, result) => {
            if (err) {
                res.status(500).send({ message: 'Error in database operation', error: err });
            } else {
                res.status(200).send({ message: 'User registered successfully' });
            }
        });
    } catch (err) {
        res.status(500).send({ message: 'Error hashing password', error: err });
    }
});

module.exports = router;
