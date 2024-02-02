const express = require('express');
const multer = require('multer');
const path = require('path');
const images = require('../multer-config.js');
const db = require('../database/connection.js');

module.exports = async function uploadProfilePhoto(req, res) {
  console.log("IN uploadProfilePhoto backend");

  // Use multer to handle file upload using the configured images middleware
  images.single('profilePhoto')(req, res, async (err) => {
    if (err) {
      console.error('Error uploading file:', err);
      return res.status(500).send({ message: 'Error uploading file', error: err });
    }

    console.log('File uploaded successfully:', req.file);

    const profilePhotoPath = req.file.filename; // Assuming the Multer configuration returns the filename
    const username = req.body.username; // Assuming username is sent in the request body

    // Update the user in the database with the image path
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
}
