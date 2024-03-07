const StreamChat = require('stream-chat').StreamChat;
const express = require('express');
const { createStreamUserAndGetToken, getStreamUserToken, revokeStreamUserToken } = require('../database/connection.js'); // Replace with the actual file path

const app = express();

// Use express routes for your functions
app.post('/createStreamUserAndGetToken', createStreamUserAndGetToken);
app.post('/getStreamUserToken', getStreamUserToken);
app.post('/revokeStreamUserToken', revokeStreamUserToken);

// Start the server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});


const serverClient = StreamChat.getInstance('adqmr32mfsg4', '5n8b3j2a7hvx867efezcsctfrpawagb2trdhb5bgvg236rvbveeyapgwj4kwtdng');

// When a user is deleted, their associated Stream account is also deleted.
app.post('/deleteStreamUser', async (req, res) => {
    try {
      const { userId } = req.body;
  
      if (!userId) {
        return res.status(400).json({ error: 'User ID is required in the request body' });
      }
  
      // Perform your logic to delete the Stream account associated with the user.
      await serverClient.deleteUser(userId);
  
      console.log(`Stream account for user ${userId} successfully deleted.`);
      return res.json({ success: true });
    } catch (error) {
      console.error('Error deleting Stream account:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  });

app.post('/createStreamUserAndGetToken', express.json(), async (req, res) => {
    try {
      const result = await createStreamUserAndGetToken(req.body, { auth: req.user }); // Modify as needed
      res.json(result);
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });
  
  app.post('/getStreamUserToken', express.json(), async (req, res) => {
    try {
      const result = await getStreamUserToken(req.body, { auth: req.user }); // Modify as needed
      res.json(result);
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });
  
  app.post('/revokeStreamUserToken', express.json(), async (req, res) => {
    try {
      const result = await revokeStreamUserToken(req.body, { auth: req.user }); // Modify as needed
      res.json(result);
    } catch (error) {
      console.error(error);
      res.status(500).json({ error: 'Internal server error' });
    }
  });
