const express = require('express');

const authController = require('../controllers/auth_controller');
const authMiddleware = require('../middleware/auth_middleware');

const router = express.Router();

router.post('/login', authController.login);
router.post('/primeiro-acesso', authController.primeiroAcesso);
router.post('/esqueci-password', authController.esqueciPassword);
router.post('/refresh-token', authController.refreshToken);
router.get('/getuser', authMiddleware, authController.getUser);
router.put('/putlastlogin', authMiddleware, authController.putLastLogin);
router.put('/aceitar-rgpd', authMiddleware, authController.aceitarRgpd);

module.exports = router;
