const express = require('express');
const router = express.Router();
const searchController = require('../../controllers/search.controller');
const authMiddleware = require('../../middleware/auth.middleware');

router.get('/', authMiddleware, searchController.searchUsers);

module.exports = router;
