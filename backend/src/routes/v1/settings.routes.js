const express = require('express');
const router = express.Router();
const settingsController = require('../../controllers/settings.controller');

// Open endpoint for initial app config loading
router.get('/', settingsController.getSettings);

module.exports = router;
