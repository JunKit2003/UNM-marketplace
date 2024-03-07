const db = require('../database/connection.js'); // Adjust path as needed


module.exports = async function getUsername(req, res) {
    // Check if the user session exists
    if (req.session && req.session.user) {
        // Send back the username from the session
        res.status(200).send({ username: req.session.user.username });
    } else {
        // If no user is logged in, send an appropriate response
        res.status(401).send({ message: 'User not logged in' });
    }
};
