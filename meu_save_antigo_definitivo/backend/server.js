require('dotenv').config();

const express = require('express');
const cors = require('cors');

const sequelize = require('./config/database');
const router = require('./routes');
const errorHandler = require('./middleware/error_handler');

const app = express();
const port = process.env.PORT || 5001;

app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.use('/api', router);

app.use((req, res) => {
  return res.status(404).json({
    error: 'Rota não encontrada.',
  });
});

app.use(errorHandler);

async function startBackend() {
  try {
    if (!process.env.JWT_SECRET || !process.env.JWT_SECRET.trim()) {
      console.error('Backend PDM: JWT_SECRET não está configurado.');
      process.exit(1);
    }

    await sequelize.authenticate();
    console.log('Backend PDM: ligação à base de dados estabelecida.');

    app.listen(port, '0.0.0.0', () => {
      console.log(`Backend PDM disponível na porta ${port}.`);
    });
  } catch (error) {
    console.error('Backend PDM: não foi possível estabelecer ligação à base de dados.');
    process.exit(1);
  }
}

startBackend();
