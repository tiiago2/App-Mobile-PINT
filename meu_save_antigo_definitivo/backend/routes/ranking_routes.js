const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth_middleware');
const rankingController = require('../controllers/ranking_controller');

router.get('/ranking', authMiddleware, rankingController.obterRankingGeral);

module.exports = router;
