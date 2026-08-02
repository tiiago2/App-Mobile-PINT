const express = require('express');
const authRoutes = require('./auth_routes');
const meRoutes = require('./me_routes');
const candidaturasRoutes = require('./candidaturas_routes');
const perfilRoutes = require('./perfil_routes');
const objetivosRoutes = require('./objetivos_routes');
const estatisticasRoutes = require('./estatisticas_routes');
const rankingRoutes = require('./ranking_routes');
const homeRoutes = require('./home_routes');

const router = express.Router();

router.get('/health', (req, res) => {
  return res.status(200).json({
    status: 'ok',
    service: 'softinsa-pint-mobile-backend',
  });
});

router.use('/', authRoutes);
router.use('/', meRoutes);
router.use('/', candidaturasRoutes);
router.use('/', perfilRoutes);
router.use('/', objetivosRoutes);
router.use('/', estatisticasRoutes);
router.use('/', rankingRoutes);
router.use('/', homeRoutes);

module.exports = router;
