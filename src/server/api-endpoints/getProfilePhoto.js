const db = require('../database/connection'); // Adjust path as needed

module.exports = async function getProfilePhoto(req, res) {
    const { username } = req.body;

    try {
        // Query to find user's profile photo URL by username
        const query = 'SELECT ProfilePicture FROM accounts WHERE username = ?';

        await db.query(query, [username], (err, result) => {
            if (err) {
                res.status(500).send({ message: 'Error in database operation', error: err });
            } else {
                if (result.length > 0) {
                    // User found, return the profile photo URL
                    const profilePhoto = result[0].ProfilePicture;
                    console.log(profilePhoto);
                    res.status(200).send({ profilePhotoUrl: profilePhoto });
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
