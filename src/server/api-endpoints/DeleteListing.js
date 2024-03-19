const express = require('express');
const db = require('../database/connection.js');
const fs = require('fs');
const path = require('path');

module.exports = async function deleteListing(req, res) {
  console.log("IN deleteListing backend");

  const { id } = req.body;

  console.log("Received ID from the request:", id);

  // Retrieve the filename of the listing photo from the database
  const selectQuery = 'SELECT ImageID FROM listing WHERE id = ?';
  db.query(selectQuery, [id], async (selectErr, selectResult) => {
    if (selectErr) {
      console.error('Error in database operation:', selectErr);
      return res.status(500).send({ message: 'Error in database operation', error: selectErr });
    }

    // Check if there is a photo associated with the listing
    if (selectResult && selectResult.length > 0 && selectResult[0].ImageID) {
      const imageID = selectResult[0].ImageID;
      const imagePath = path.join(__dirname, '..', 'images', 'Listing', imageID);

      // Delete the photo file
      fs.unlink(imagePath, (unlinkErr) => {
        if (unlinkErr) {
          console.error('Error deleting photo:', unlinkErr);
        }
        console.log('Listing photo deleted successfully');
      });
    }

    // Delete the listing from the database
    const deleteQuery = 'DELETE FROM listing WHERE id = ?';
    await db.query(deleteQuery, [id], (deleteErr, deleteResult) => {
      if (deleteErr) {
        console.error('Error in database operation:', deleteErr);
        return res.status(500).send({ message: 'Error in database operation', error: deleteErr });
      }

      console.log('Listing deleted successfully');
      res.status(200).send({ message: 'Listing deleted successfully' });
    });
  });
}
