// getCategories.js

const categories = [
    'Books',
    'Vehicles',
    'Property Rentals',
    'Home & Garden',
    'Electronics',
    'Hobbies',
    'Clothing & Accessories',
    'Family',
    'Entertainment',
    'Sports equipment',
    'uqiwjdbfdiwqebf',
    'Other'
];

module.exports = function getCategories(req, res) {
    try {
        res.status(200).json({ categories });
    } catch (error) {
        console.error(error);
        res.status(500).send({ message: 'Error in retrieving categories', error });
    }
};