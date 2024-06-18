const express = require('express');
const db = require('../database/connection.js');

module.exports = async function retrieveListingImages(req, res) {
  console.log("IN retrieveListingImages backend");

  try {
    // Retrieve image IDs for all listings
    const selectQuery = 'SELECT ImageID FROM marketplace.listing';
    const listings = await db.query(selectQuery);

    // Extract image URLs from the query result
    const imageUrls = listings.map(listing => listing.ImageID);

    console.log('Listing images retrieved successfully:', imageUrls);
    res.status(200).send({ imageUrls });
  } catch (error) {
    console.error('Error retrieving listing images:', error);
    res.status(500).send({ message: 'Error retrieving listing images', error });
  }
}
