const router = require('express').Router();
const { ping } = require('../api-endpoints');

// All API Endpoints go here
router.post('/ping', ping);


module.exports = router;