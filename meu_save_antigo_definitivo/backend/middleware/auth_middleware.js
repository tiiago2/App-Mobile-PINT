const jwt = require('jsonwebtoken');

function authMiddleware(req, res, next) {
  const authorization = req.headers.authorization;

  if (!authorization || typeof authorization !== 'string') {
    return res.status(401).json({ error: 'Acesso não autorizado.' });
  }

  const parts = authorization.split(' ');

  if (parts.length !== 2 || parts[0] !== 'Bearer' || !parts[1]) {
    return res.status(401).json({ error: 'Acesso não autorizado.' });
  }

  try {
    const payload = jwt.verify(parts[1], process.env.JWT_SECRET);
    const isValidPayload =
      payload &&
      payload.token_type === 'access' &&
      payload.role === 'Consultor' &&
      payload.id_utilizador;

    if (!isValidPayload) {
      return res.status(401).json({ error: 'Acesso não autorizado.' });
    }

    req.utilizadorLogado = payload;
    return next();
  } catch (error) {
    return res.status(401).json({ error: 'Acesso não autorizado.' });
  }
}

module.exports = authMiddleware;
