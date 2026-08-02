const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth_middleware');
const candidaturasController = require('../controllers/candidaturas_controller');

router.get('/me/candidaturas', authMiddleware, candidaturasController.listarMinhasCandidaturas);
router.post('/me/candidaturas', authMiddleware, candidaturasController.submeterCandidatura);

module.exports = router;
