const express = require('express');
const router = express.Router();
const v1Router = require('./v1');

// Mount API version 1 routers
router.use('/v1', v1Router);

// Support future extensions here
// router.use('/v2', v2Router);

module.exports = router;
