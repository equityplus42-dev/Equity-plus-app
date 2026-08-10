const express = require('express');
const router = express.Router();
const videoAssignmentController = require('../../controllers/videoAssignment.controller');
const authMiddleware = require('../../middleware/auth.middleware');
const roleMiddleware = require('../../middleware/role.middleware');

router.use(authMiddleware);
router.use(roleMiddleware(['ADMIN']));

// Overview & Dashboard Stats
router.get('/stats', videoAssignmentController.getDashboardStats);

// Video Assignments List
router.get('/', videoAssignmentController.getVideoAssignments);

// Video Assignment Details for a specific video
router.get('/:id', videoAssignmentController.getVideoAssignmentDetails);

// Single Assign
router.post('/assign', videoAssignmentController.assignVideo);

// Bulk Assign
router.post('/bulk-assign', videoAssignmentController.bulkAssignVideo);

// Single Unassign
router.post('/:id/unassign', videoAssignmentController.unassignVideo);

// Bulk Unassign
router.post('/bulk-unassign', videoAssignmentController.bulkUnassignVideo);

// User Directory Video Assignments View
router.get('/user/:id', videoAssignmentController.getUserVideoAssignmentsAdmin);

// Force-delete a video (even if snapshot-protected) — irreversible admin override
router.delete('/:id/force-delete', videoAssignmentController.forceDeleteVideo);

module.exports = router;
