const db = require('../database/connection'); // Adjust path as needed
const bcrypt = require('bcrypt');

module.exports = async function login (req, res){
    const { email, password } = req.body;

    // Query to find user by email
    const query = 'SELECT * FROM accounts WHERE email = ?';
    await db.query(query, [email], async (err, result) => {
        if (err) {
            res.status(500).send({ message: 'Error in database operation', error: err });
        } else {
            if (result.length > 0) {
                const match = await bcrypt.compare(password, result[0].password);
                if (match) {
                    // Create a session and store user details
                    req.session.user = {
                        id: result[0].id, 
                        firstName: result[0].first_name,
                        lastName: result[0].last_name,
                        username: result[0].username,
                        email: result[0].email,
                        token: result[0].token
                    };
                    console.log(req.session);
                    req.session.save();
                    res.status(200).send({ message: 'Login successful' });
                } else {
                    res.status(401).send({ message: 'Invalid credentials' });
                }
            } else {
                res.status(401).send({ message: 'User not found' });
            }
        }
    });
}



