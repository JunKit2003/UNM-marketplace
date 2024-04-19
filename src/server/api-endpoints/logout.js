module.exports = async function logout(req, res) {
    try {
        await req.session.destroy(err => {
            if (err) {
                res.status(500).send({ message: 'Error logging out', error: err });
            } else {
                res.send({ message: 'Logout successful' });
            }
        });
        console.log(req.session);
    } catch (error) {
        console.error('Error:', error);
        res.status(500).send({ message: 'Internal server error', error });
    }
};
