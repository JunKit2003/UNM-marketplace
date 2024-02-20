const express = require('express');
const db = require('../database/connection.js');

module.exports = async function editListing(req, res) {
  console.log("IN editListing backend");

  const { id, title, description, price, category, PostedBy } = req.body;

  console.log("Received data from the request:", { id, title, description, price, category, PostedBy });

  // Update the listing in the database
  const updateQuery = 'UPDATE listing SET title = ?, description = ?, price = ?, category = ?, PostedBy = ? WHERE id = ?';
  await db.query(updateQuery, [title, description, price, category, PostedBy, id], (updateErr, updateResult) => {
    if (updateErr) {
      console.error('Error in database operation:', updateErr);
      return res.status(500).send({ message: 'Error in database operation', error: updateErr });
    }
    
    console.log('Listing updated successfully');
    res.status(200).send({ message: 'Listing updated successfully' });
  });
}
