const StreamChat = require('stream-chat').StreamChat;
const db = require('../database/connection.js');

// Stream Chat client initialization
const apiKey = 'adqmr32mfsg4';
const apiSecret = '5n8b3j2a7hvx867efezcsctfrpawagb2trdhb5bgvg236rvbveeyapgwj4kwtdng';
const serverClient = StreamChat.getInstance(apiKey, apiSecret);

module.exports = async function createStreamUserAndToken (req, res) {
  try {
    const { username } = req.body;

    // Create a Stream user
    const user = await serverClient.upsertUser({
      id: username,
      name: username,
    });

    // Generate a token for the user
    const token = serverClient.createToken(user.id);

    // Return the user and token
    res.json({
      user,
      token,
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
