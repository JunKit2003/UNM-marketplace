const multer = require('multer');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

// Configure Multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, '.', 'images'));
  },
  filename: (req, file, cb) => {
    const fileExtension = path.extname(file.originalname);
    const currentDate = new Date();
    const timestamp = `${currentDate.getFullYear()}-${(currentDate.getMonth() + 1).toString().padStart(2, '0')}-${currentDate.getDate().toString().padStart(2, '0')}-${currentDate.getHours().toString().padStart(2, '0')}-${currentDate.getMinutes().toString().padStart(2, '0')}-${currentDate.getSeconds().toString().padStart(2, '0')}`;
    const randomFilename = `${timestamp}-${uuidv4()}${fileExtension}`;
    cb(null, randomFilename);
  },
});

const images = multer({ storage: storage });

module.exports = images;