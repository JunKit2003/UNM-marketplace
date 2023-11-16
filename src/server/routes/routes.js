const router = require('express').Router();
const { ping, register, login } = require('../api-endpoints');

// All API Endpoints go here
router.post('/ping', ping);
router.post('/register', register);
router.post('/login', login);

module.exports = router;