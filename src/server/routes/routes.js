const router = require('express').Router();
const { ping, signup, login, logout, profile } = require('../api-endpoints');

// All API Endpoints go here
router.post('/ping', ping);
router.post('/signup', signup);
router.post('/login', login);
router.post('/logout', logout);
router.post('/profile', profile);

module.exports = router;