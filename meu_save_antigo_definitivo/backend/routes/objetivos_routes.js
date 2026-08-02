const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth_middleware');
const objetivosController = require('../controllers/objetivos_controller');

router.get('/me/objetivos', authMiddleware, objetivosController.listarMeusObjetivos);
router.post('/me/objetivos', authMiddleware, objetivosController.criarObjetivo);
router.delete('/me/objetivos/:id', authMiddleware, objetivosController.removerObjetivo);

module.exports = router;
