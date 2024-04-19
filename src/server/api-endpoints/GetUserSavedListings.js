const express = require('express');
const db = require('../database/connection.js');

module.exports = async function getUserSavedListings(req, res) {
  console.log("IN getUserSavedListings backend");

  try {
    const { username } = req.query;

    console.log("Received username from the request:", username);

    // Fetch the saved listings of the user from the database
    const selectQuery = 'SELECT ListingID FROM saved WHERE SavedBy = ?';
    await db.query(selectQuery, [username], (selectErr, selectResult) => {
      if (selectErr) {
        console.error('Error in database operation:', selectErr);
        return res.status(500).send({ message: 'Error in database operation', error: selectErr });
      }
      
      const savedListingIds = selectResult.map(row => row.ListingID);

      console.log('User saved listings fetched successfully');
      res.status(200).send({ message: 'User saved listings fetched successfully', savedListingIds });
    });
  } catch (error) {
    console.error('Error fetching user saved listings:', error);
    res.status(500).send({ message: 'Internal server error', error });
  }
};
