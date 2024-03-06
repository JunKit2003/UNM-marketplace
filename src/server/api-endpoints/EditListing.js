const express = require('express');
const db = require('../database/connection.js');

module.exports = function editListing(req, res) {
  console.log("IN editListing backend");

  const { id, title, condition, description, price, category, ContactDescription, PostedBy } = req.body;

  console.log("Received data from the request:", { id, title, condition, description, price, category, ContactDescription, PostedBy });

  // Update the listing in the database
  const updateQuery = 'UPDATE listing SET title = ?, `condition` = ?, description = ?, price = ?, category = ?, ContactDescription = ?, PostedBy = ? WHERE id = ?';
  db.query(updateQuery, [title, condition, description, price, category, ContactDescription, PostedBy, id], (updateErr, updateResult) => {
    if (updateErr) {
      console.error('Error in database operation:', updateErr);
      return res.status(500).send({ message: 'Error in database operation', error: updateErr });
    }
    
    console.log('Listing updated successfully');
    res.status(200).send({ message: 'Listing updated successfully' });
  });
}
