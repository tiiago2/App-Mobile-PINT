const express = require('express');
const router = express.Router();
const authMiddleware = require('../middleware/auth_middleware');
const perfilController = require('../controllers/perfil_controller');

router.put('/me/perfil', authMiddleware, perfilController.atualizarPerfil);
router.get('/me/perfil/learning-path', authMiddleware, perfilController.obterLearningPathProgresso);

module.exports = router;
