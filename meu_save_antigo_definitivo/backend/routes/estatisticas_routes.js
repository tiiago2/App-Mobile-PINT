const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth_middleware');
const estatisticasController = require('../controllers/estatisticas_controller');

router.get('/me/estatisticas', authMiddleware, estatisticasController.obterMinhasEstatisticas);

module.exports = router;
