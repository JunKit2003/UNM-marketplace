const multer = require('multer');
const { v4: uuidv4 } = require('uuid');

// Configure Multer for file uploads with memory storage
const storage = multer.memoryStorage();

const images = multer({ storage: storage });

module.exports = images;
