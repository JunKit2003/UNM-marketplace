const express = require('express');
const db = require('../database/connection.js');
const fs = require('fs');
const path = require('path');

module.exports = async function deleteListing(req, res) {
  console.log("IN deleteListing backend");

  const { id } = req.body;

  console.log("Received ID from the request:", id);

  try {
    // Retrieve the filename of the listing photo from the database
    const selectQuery = 'SELECT ListingID FROM saved WHERE ListingID = ?';
    db.query(selectQuery, [id], async (selectErr, selectResult) => {
      if (selectErr) {
        console.error('Error in database operation:', selectErr);
        return res.status(500).send({ message: 'Error in database operation', error: selectErr });
      }

      // Check if there are listings associated with the provided ListingID in the saved table
      if (selectResult && selectResult.length > 0) {
        // Delete all listings associated with the ListingID from the saved table
        const deleteQuery = 'DELETE FROM saved WHERE ListingID = ?';
        await db.query(deleteQuery, [id], (deleteErr, deleteResult) => {
          if (deleteErr) {
            console.error('Error deleting listings from saved table:', deleteErr);
            return res.status(500).send({ message: 'Error in database operation', error: deleteErr });
          }

          console.log('Listings deleted successfully from saved table');
        });
      }

      try {
        // Delete the listing from the database
        const deleteListingQuery = 'DELETE FROM listing WHERE id = ?';
        await db.query(deleteListingQuery, [id], (deleteListingErr, deleteListingResult) => {
          if (deleteListingErr) {
            console.error('Error deleting listing from the database:', deleteListingErr);
            return res.status(500).send({ message: 'Error in database operation', error: deleteListingErr });
          }

          console.log('Listing deleted successfully');
          res.status(200).send({ message: 'Listing deleted successfully' });
        });
      } catch (deleteListingErr) {
        console.error('Error deleting listing from the database:', deleteListingErr);
        return res.status(500).send({ message: 'Error in database operation', error: deleteListingErr });
      }
    });
  } catch (error) {
    console.error('Error:', error);
    return res.status(500).send({ message: 'Internal server error', error });
  }
};
