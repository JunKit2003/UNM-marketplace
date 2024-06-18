const bcrypt = require('bcrypt');
const db = require('../database/connection.js');
const saltRounds = 10;

module.exports = async function changePassword(req, res) {
    console.log("In change password backend");
    
    const { username, currentPassword, newPassword } = req.body;

    try {
        // Check if the user exists in the database
        const userQuery = 'SELECT * FROM accounts WHERE username = ?';
        const userResult = await db.query(userQuery, [username]);

        if (userResult.length === 0) {
            return res.status(404).send({ message: 'User not found' });
        }

        const user = userResult[0];

        // Check if the current password provided matches the stored hashed password
        const isPasswordMatch = await bcrypt.compare(currentPassword, user.password);

        if (!isPasswordMatch) {
            return res.status(401).send({ message: 'Current password is incorrect' });
        }

        // Hash the new password
        const hashedNewPassword = await bcrypt.hash(newPassword, saltRounds);

        // Update the password in the database
        const updateQuery = 'UPDATE accounts SET password = ? WHERE username = ?';
        await db.query(updateQuery, [hashedNewPassword, username]);

        res.status(200).send({ message: 'Password updated successfully' });
    } catch (error) {
        console.error("Error in database operation:", error);
        res.status(500).send({ message: 'Error in database operation', error: error });
    }
}
