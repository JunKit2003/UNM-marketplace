const db = require('../database/connection.js');
const bcrypt = require('bcrypt');
const saltRounds = 10;
const StreamChat = require('stream-chat').StreamChat;
const apiKey = 'adqmr32mfsg4';
const apiSecret = '5n8b3j2a7hvx867efezcsctfrpawagb2trdhb5bgvg236rvbveeyapgwj4kwtdng';
const serverClient = StreamChat.getInstance(apiKey, apiSecret);

module.exports = async function signup(req, res){
    console.log("IN register backend");
    const { first_name, last_name, username, email, phone_number, password } = req.body;

    // Check if the username contains spaces
    if (username.includes(' ')) {
        return res.status(400).send({ message: 'Username cannot contain spaces' });
    }

    // Check if the username, email, and phone number already exist in the database
    const usernameCheckQuery = 'SELECT username FROM accounts WHERE username = ?';
    const emailCheckQuery = 'SELECT email FROM accounts WHERE email = ?';
    const phoneCheckQuery = 'SELECT phone_number FROM accounts WHERE phone_number = ?';

    try {
        const [usernameResult, emailResult, phoneResult] = await Promise.all([
            db.query(usernameCheckQuery, [username]),
            db.query(emailCheckQuery, [email]),
            db.query(phoneCheckQuery, [phone_number])
        ]);

        if (usernameResult.length > 0) {
            // Username already exists
            return res.status(400).send({ message: 'Username already exists' });
        }

        if (emailResult.length > 0) {
            // Email already exists
            return res.status(400).send({ message: 'Email already exists' });
        }

        if (phoneResult.length > 0) {
            // Phone number already exists
            return res.status(400).send({ message: 'Phone number already exists' });
        }

        // Hash the password
        const hashedPassword = await bcrypt.hash(password, saltRounds);

        const profilePicture = "";

        // Create a Stream user
        const user = await serverClient.upsertUser({
            id: username,
            name: username,
        });

        console.log('User ID:', username);
        const streamToken = serverClient.createToken(String(username));

        // Insert the new user into the database
        const insertQuery = 'INSERT INTO accounts (ProfilePicture, first_name, last_name, username, email, phone_number, password, token) VALUES (?, ?, ?, ?, ?, ?, ?, ?)';
        await db.query(insertQuery, [profilePicture, first_name, last_name, username, email, phone_number, hashedPassword, streamToken]);
        
        res.status(200).send({ message: 'User registered successfully' });
    } catch (error) {
        res.status(500).send({ message: 'Error in database operation', error: error });
    }
}
