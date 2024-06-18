const express = require('express');
const db = require('../database/connection.js');
const fs = require('fs');
const path = require('path');

module.exports = async function deleteListing(req, res) {
  console.log("IN deleteListing backend");

  const { id } = req.body;

  console.log("Received ID from the request:", id);

  try {
    // Get the filename of the photo associated with the listing
    const selectPhotoQuery = 'SELECT ImageID FROM listing WHERE id = ?';
    db.query(selectPhotoQuery, [id], async (selectPhotoErr, selectPhotoResult) => {
      if (selectPhotoErr) {
        console.error('Error retrieving photo filename:', selectPhotoErr);
        return res.status(500).send({ message: 'Error in database operation', error: selectPhotoErr });
      }

      // Extract the filename from the query result
      const photoFilename = selectPhotoResult[0].ImageID;

      // Construct the path to the photo file on the server
      const photoPath = path.join(__dirname, '..', 'images', 'Listing', photoFilename);

      // Delete the photo file from the server
      fs.unlink(photoPath, (unlinkErr) => {
        if (unlinkErr) {
          console.error('Error deleting photo file:', unlinkErr);
          return res.status(500).send({ message: 'Error deleting photo file', error: unlinkErr });
        }

        console.log('Photo file deleted successfully');

        // Delete listings associated with the ListingID from the "saved" table
        const deleteSavedQuery = 'DELETE FROM saved WHERE ListingID = ?';
        db.query(deleteSavedQuery, [id], async (deleteSavedErr, deleteSavedResult) => {
          if (deleteSavedErr) {
            console.error('Error deleting listings from saved table:', deleteSavedErr);
            return res.status(500).send({ message: 'Error in database operation', error: deleteSavedErr });
          }

          console.log('Listings deleted successfully from saved table');

          // Delete the listing from the "listing" table
          const deleteListingQuery = 'DELETE FROM listing WHERE id = ?';
          db.query(deleteListingQuery, [id], (deleteListingErr, deleteListingResult) => {
            if (deleteListingErr) {
              console.error('Error deleting listing from the database:', deleteListingErr);
              return res.status(500).send({ message: 'Error in database operation', error: deleteListingErr });
            }

            console.log('Listing deleted successfully');
            res.status(200).send({ message: 'Listing deleted successfully' });
          });
        });
      });
    });
  } catch (error) {
    console.error('Error:', error);
    return res.status(500).send({ message: 'Internal server error', error });
  }
};
