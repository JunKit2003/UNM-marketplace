const router = require('express').Router();
const { ping, signup, login, logout, profile, getUsername, UploadListingDetails, UploadListingPhoto, RetrieveListing, DeleteListing, UpdateProfilePhoto } = require('../api-endpoints');

// All API Endpoints go here
router.post('/ping', ping);
router.post('/signup', signup);
router.post('/login', login);
router.post('/logout', logout);
router.post('/profile', profile);
router.post('/getUsername', getUsername);
router.post('/UploadListingDetails', UploadListingDetails);
router.post('/UploadListingPhoto', UploadListingPhoto);
router.post('/RetrieveListing', RetrieveListing);
router.post('/DeleteListing', DeleteListing);
router.post('/UpdateProfilePhoto', UpdateProfilePhoto);

module.exports = router;    