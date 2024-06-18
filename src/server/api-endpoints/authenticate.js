module.exports = async function authenticate(req, res) {
    try {
        if (req.session.user) {
            return res.status(200).send({ message: 'User logged in' });
        } else {
            return res.status(404).send({ message: 'User not logged in' });
        }
    } catch (error) {
        console.error('Error:', error);
        res.status(500).send({ message: 'Internal server error', error });
    }
};
