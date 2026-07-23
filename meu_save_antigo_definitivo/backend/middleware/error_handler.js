function errorHandler(error, req, res, next) {
  console.error('Backend PDM: erro interno tratado pelo middleware global.');

  const statusCode =
    Number.isInteger(error.status) && error.status >= 400 && error.status <= 599
      ? error.status
      : 500;

  return res.status(statusCode).json({
    error: 'Erro interno do servidor.',
  });
}

module.exports = errorHandler;
