const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth_middleware');
const controller = require('../controllers/me_badges_controller');

router.get('/badges', authMiddleware, controller.listarMeusBadges);

module.exports = router;
