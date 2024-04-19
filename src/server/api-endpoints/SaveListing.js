const express = require('express');
const db = require('../database/connection.js');

module.exports = async function saveListing(req, res) {
  console.log("IN saveListing backend");

  try {
    const { username, listingId } = req.body;

    console.log("Received data from the request:", { username, listingId });

    // Insert the saved listing into the database
    const insertQuery = 'INSERT INTO saved (SavedBy, ListingID) VALUES (?, ?)';
    await db.query(insertQuery, [username, listingId], (insertErr, insertResult) => {
      if (insertErr) {
        console.error('Error in database operation:', insertErr);
        return res.status(500).send({ message: 'Error in database operation', error: insertErr });
      }
      
      console.log('Listing saved successfully');
      res.status(200).send({ message: 'Listing saved successfully' });
    });
  } catch (error) {
    console.error('Error saving listing:', error);
    res.status(500).send({ message: 'Internal server error', error });
  }
};
