const express = require('express');
const multer = require('multer');
const path = require('path');
const db = require('../database/connection.js');
const images = require('../multer-config.js')



module.exports = async function uploadListingPhoto(req, res) {
  console.log("IN uploadListingPhoto backend");

  // Use multer to handle file upload
  images.single('listingPhoto')(req, res, async (err) => {
    if (err) {
      console.error('Error uploading file:', err);
      return res.status(500).send({ message: 'Error uploading file', error: err });
    }

    console.log('File uploaded successfully:', req.file);

    const listingPhoto = req.file.filename; // Get the path of the uploaded file

    console.log('Listing ID from request:', req.body.id);

    // Update the listing in the database with the image path
    const updateQuery = 'UPDATE listing SET ImageID = ? WHERE id = ?'; // Replace 'id' with your actual listing id field
    await db.query(updateQuery, [listingPhoto, req.body.id], (updateErr, updateResult) => { // Replace 'req.body.id' with your actual listing id
      if (updateErr) {
        console.error('Error in database operation:', updateErr);
        return res.status(500).send({ message: 'Error in database operation', error: updateErr });
      }
      console.log('Listing photo uploaded successfully');
      res.status(200).send({ message: 'Listing photo uploaded successfully' });
    });
  });
}
