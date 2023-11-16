// Assuming you're using Express.js
const express = require('express');
const router = express.Router();
const db = require('../database/connection.js');


// POST endpoint for registering a new user
router.post('/register', (req, res) => {
    const { first_name, last_name, email, password } = req.body;

    console.log(first_name);

    // You should hash the password before storing it
    // For simplicity, this example stores it as-is

    const query = 'INSERT INTO accounts (first_name, last_name, email, password) VALUES (?, ?, ?, ?)';
    db.query(query, [first_name, last_name, email, password], (err, result) => {
        if (err) {
            res.status(500).send({ message: 'Error in database operation', error: err });
        } else {
            res.status(200).send({ message: 'User registered successfully' });
        }
    });
});

module.exports = router;
