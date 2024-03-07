const db = require('../database/connection.js');
const fs = require('fs');
const path = require('path');

module.exports = async function deleteListingPhoto(req, res) {
  console.log("IN deleteListingPhoto backend");

  const { id } = req.body;

  console.log("Received ID from the request:", id);

  // Retrieve the filename of the listing photo from the database
  const selectQuery = 'SELECT ImageID FROM listing WHERE id = ?';
  db.query(selectQuery, [id], async (selectErr, selectResult) => {
    if (selectErr) {
      console.error('Error in database operation:', selectErr);
      return res.status(500).send({ message: 'Error in database operation', error: selectErr });
    }

    // Check if there is a photo associated with the listing
    if (selectResult && selectResult.length > 0 && selectResult[0].ImageID) {
      const imageID = selectResult[0].ImageID;
      const imagePath = path.join(__dirname, '..', 'images', imageID);

      // Delete the photo file
      fs.unlink(imagePath, (unlinkErr) => {
        if (unlinkErr) {
          console.error('Error deleting photo:', unlinkErr);
          return res.status(500).send({ message: 'Error deleting photo', error: unlinkErr });
        }
        console.log('Listing photo deleted successfully');

        // Clear the ImageID column in the database
        const clearImageIDQuery = 'UPDATE listing SET ImageID = NULL WHERE id = ?';
        db.query(clearImageIDQuery, [id], (updateErr, updateResult) => {
          if (updateErr) {
            console.error('Error updating database:', updateErr);
            return res.status(500).send({ message: 'Error updating database', error: updateErr });
          }
          console.log('ImageID column cleared successfully');
          res.status(200).send({ message: 'Listing photo deleted successfully' });
        });
      });
    } else {
      console.log('No photo associated with the listing');
      res.status(200).send({ message: 'No photo associated with the listing' });
    }
  });
}
