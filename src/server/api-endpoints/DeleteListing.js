const express = require('express');
const db = require('../database/connection.js');

const router = express.Router();

router.delete('/deleteListing/:id', async (req, res) => {
  const { id } = req.params;

  try {
    // Check if the listing exists
    const selectQuery = 'SELECT * FROM listing WHERE id = ?';
    const [rows] = await db.query(selectQuery, [id]);

    if (rows.length === 0) {
      return res.status(404).json({ message: 'Listing not found' });
    }

    // Delete the listing from the database
    const deleteQuery = 'DELETE FROM listing WHERE id = ?';
    await db.query(deleteQuery, [id]);

    res.status(200).json({ message: 'Listing deleted successfully' });
  } catch (error) {
    console.error('Error deleting listing:', error);
    res.status(500).json({ message: 'Error deleting listing', error: error });
  }
});

module.exports = router;
