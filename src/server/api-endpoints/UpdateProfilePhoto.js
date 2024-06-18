const express = require('express');
const multer = require('multer');
const path = require('path');
const db = require('../database/connection.js');
const images = require('../multer-config.js');
const fs = require('fs');

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const destinationDir = path.join(__dirname, '..', 'images', 'ProfilePhoto');
    cb(null, destinationDir);
  },
  filename: (req, file, cb) => {
    // Preserve the original file extension
    const fileExtension = path.extname(file.originalname);
    // Generate a unique filename for the uploaded image
    const uniqueFilename = `${Date.now()}${fileExtension}`;
    cb(null, uniqueFilename);
  },
});

const upload = multer({ storage: storage });

module.exports = async function uploadProfilePhoto(req, res) {
  console.log("IN uploadProfilePhoto backend");

  try {
    // Use multer to handle file upload using the configured images middleware
    upload.single('profilePhoto')(req, res, async (err) => {
      if (err) {
        console.error('Error uploading file:', err);
        return res.status(500).send({ message: 'Error uploading file', error: err });
      }

      console.log('File uploaded successfully:', req.file);

      const profilePhotoPath = req.file.filename; // Get the filename of the uploaded file
      const username = req.body.username; // Get the username from the request body

      // Query to fetch the current profile picture of the user
      const selectQuery = 'SELECT ProfilePicture FROM accounts WHERE username = ?';
      await db.query(selectQuery, [username], async (selectErr, selectResult) => {
        if (selectErr) {
          console.error('Error in database operation:', selectErr);
          return res.status(500).send({ message: 'Error in database operation', error: selectErr });
        }

        // If there is a profile picture associated with the user, delete it
        if (selectResult && selectResult.length > 0 && selectResult[0].ProfilePicture) {
          const existingProfilePicturePath = path.join(__dirname, '..', 'images', 'ProfilePhoto', selectResult[0].ProfilePicture);
          // Delete the existing profile picture
          try {
            fs.unlinkSync(existingProfilePicturePath);
            console.log('Existing profile photo deleted successfully');
          } catch (deleteErr) {
            console.error('Error deleting existing profile photo:', deleteErr);
          }
        }

        // Update the user in the database with the new image path
        const updateQuery = 'UPDATE accounts SET ProfilePicture = ? WHERE username = ?'; // Adjust table and column names as per your database schema
        await db.query(updateQuery, [profilePhotoPath, username], (updateErr, updateResult) => {
          if (updateErr) {
            console.error('Error in database operation:', updateErr);
            return res.status(500).send({ message: 'Error in database operation', error: updateErr });
          }
          console.log('Profile photo uploaded successfully');
          res.status(200).send({ message: 'Profile photo uploaded successfully' });
        });
      });
    });
  } catch (error) {
    console.error('Error uploading profile photo:', error);
    res.status(500).send({ message: 'Internal server error', error });
  }
};
