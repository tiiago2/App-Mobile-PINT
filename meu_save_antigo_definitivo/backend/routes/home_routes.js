const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth_middleware');
const homeController = require('../controllers/home_controller');

router.get('/me/home', authMiddleware, homeController.obterDashboardHome);

module.exports = router;
