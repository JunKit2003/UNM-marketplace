const express = require('express');
const db = require('../database/connection.js');

module.exports = async function deleteSavedListing(req, res) {
  console.log("IN deleteSavedListing backend");

  try {
    const { username, listingId } = req.body;

    console.log("Received data from the request:", { username, listingId });

    // Delete the saved listing from the database
    const deleteQuery = 'DELETE FROM saved WHERE SavedBy = ? AND ListingID = ?';
    await db.query(deleteQuery, [username, listingId], (deleteErr, deleteResult) => {
      if (deleteErr) {
        console.error('Error in database operation:', deleteErr);
        return res.status(500).send({ message: 'Error in database operation', error: deleteErr });
      }
      
      console.log('Saved listing deleted successfully');
      res.status(200).send({ message: 'Saved listing deleted successfully' });
    });
  } catch (error) {
    console.error('Error deleting saved listing:', error);
    res.status(500).send({ message: 'Internal server error', error });
  }
};
