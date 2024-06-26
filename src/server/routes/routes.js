const router = require('express').Router();
const { ping,
    signup,
    login,
    logout,
    profile,
    getUsername,
    UploadListingDetails,
    UploadListingPhoto,
    RetrieveListing,
    DeleteListing,
    UpdateProfilePhoto,
    EditListing,
    DeleteListingPhoto,
    getProfilePhoto,
    changePassword,
    getCategories,
    RetrieveListingImages,
    authenticate,
    createStreamUserAndToken,
    getStreamToken,
    SaveListing,
    DeleteSavedListing,
    GetUserSavedListings } = require('../api-endpoints');

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
router.post('/EditListing', EditListing);
router.post('/DeleteListingPhoto', DeleteListingPhoto);
router.post('/getProfilePhoto', getProfilePhoto);
router.post('/changePassword', changePassword);
router.post('/getCategories', getCategories);
router.post('/RetrieveListingImages', RetrieveListingImages);
router.post('/authenticate', authenticate);
router.post('/createStreamUserAndToken', createStreamUserAndToken);
router.post('/getStreamToken', getStreamToken);
router.post('/SaveListing', SaveListing);
router.post('/DeleteSavedListing', DeleteSavedListing);
router.post('/GetUserSavedListings', GetUserSavedListings);
module.exports = router;    