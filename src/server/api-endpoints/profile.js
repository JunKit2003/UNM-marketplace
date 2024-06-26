const db = require('../database/connection'); // Adjust path as needed

module.exports = async function profile(req, res) {
    try {
        const { username } = req.body;
        // Query to find user by username
        const query = 'SELECT first_name, last_name, email, phone_number, ProfilePicture FROM accounts WHERE username = ?';
        await db.query(query, [username], (err, result) => {
            if (err) {
                res.status(500).send({ message: 'Error in database operation', error: err });
            } else {
                if (result.length > 0) {
                    // User found, return the relevant details
                    const { first_name, last_name, email, phone_number, ProfilePicture } = result[0];
                    res.status(200).send({ firstName: first_name, lastName: last_name, username, email, phone_number, ProfilePicture });
                } else {
                    // No user found with the given username
                    res.status(404).send({ message: 'User not found' });
                }
            }
        });
    } catch (error) {
        console.error('Error:', error);
        res.status(500).send({ message: 'Internal server error', error });
    }
};
