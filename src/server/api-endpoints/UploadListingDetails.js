const express = require('express');
const db = require('../database/connection.js');

module.exports = async function uploadListingDetails(req, res) {
  console.log("IN uploadListingDetails backend");

  const { title, description, price, category, ContactDescription, PostedBy } = req.body;

  console.log("Received data from the request:", { title, description, price, category, ContactDescription, PostedBy });

  // Insert the new listing into the database
  const insertQuery = 'INSERT INTO listing (title, description, price, category, ContactDescription, PostedBy) VALUES (?, ?, ?, ?, ?, ?)';
  await db.query(insertQuery, [title, description, price, category, ContactDescription, PostedBy], (insertErr, insertResult) => {
    if (insertErr) {
      console.error('Error in database operation:', insertErr);
      return res.status(500).send({ message: 'Error in database operation', error: insertErr });
    }
    
    const insertedId = insertResult.insertId; // Get the ID of the inserted row

    console.log('Listing details uploaded successfully');
    res.status(200).send({ message: 'Listing details uploaded successfully', id: insertedId });
  });
}
