const express = require('express');
const authRoutes = require('./auth_routes');
const meRoutes = require('./me_routes');

const router = express.Router();

router.get('/health', (req, res) => {
  return res.status(200).json({
    status: 'ok',
    service: 'softinsa-pint-mobile-backend',
  });
});

router.use('/', authRoutes);
router.use('/me', meRoutes);

module.exports = router;
