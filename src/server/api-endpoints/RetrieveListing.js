const express = require('express');
const db = require('../database/connection.js');

module.exports = async function retrieveListing(req, res) {
  console.log("IN retrieveListing backend");

  try {
    // Retrieve listings from the database
    const selectQuery = 'SELECT * FROM marketplace.listing';
    const listings = await db.query(selectQuery);

    // Convert local file paths to HTTP URLs for images
    const listingsWithHTTPURLs = listings.map(listing => {
      return {
        ...listing,
      };
    });

    console.log('Listings retrieved successfully:', listingsWithHTTPURLs);
    res.status(200).send({ listings: listingsWithHTTPURLs });
  } catch (error) {
    console.error('Error retrieving listings:', error);
    res.status(500).send({ message: 'Error retrieving listings', error: error });
  }
}
