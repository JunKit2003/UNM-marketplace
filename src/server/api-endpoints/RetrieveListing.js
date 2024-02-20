const express = require('express');
const db = require('../database/connection.js');

module.exports = async function retrieveListing(req, res) {
  console.log("IN retrieveListing backend");

  try {
    let listings;
    if (req.query.id) {
      // If ID is provided, retrieve details for that specific listing
      const selectQuery = 'SELECT * FROM marketplace.listing WHERE id = ?';
      listings = await db.query(selectQuery, [req.query.id]);
    } else {
      // If no ID provided, retrieve details for all listings
      const selectQuery = 'SELECT * FROM marketplace.listing';
      listings = await db.query(selectQuery);
    }

    // Convert local file paths to HTTP URLs for images
    const listingsWithHTTPURLs = listings.map(listing => {
      return {
        ...listing,
        // You can add more fields here to convert file paths to HTTP URLs if necessary
      };
    });

    console.log('Listings retrieved successfully:', listingsWithHTTPURLs);
    res.status(200).send({ listings: listingsWithHTTPURLs });
  } catch (error) {
    console.error('Error retrieving listings:', error);
    res.status(500).send({ message: 'Error retrieving listings', error: error });
  }
}
