module.exports = async function authenticate (req, res){
    if (req.session.user) {
        return res.status(200).send({ message: 'User logged in' });
    } else {
        return res.status(404).send({ message: 'User not logged in' });
    }
}