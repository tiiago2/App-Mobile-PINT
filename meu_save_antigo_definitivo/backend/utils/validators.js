/**
 * Utilitários de validação de input para os controladores do Backend PDM.
 */

function validateRequired(fields, body) {
  if (!body || typeof body !== 'object') {
    return 'Corpo da requisição inválido.';
  }

  for (const field of fields) {
    const val = body[field];
    if (val === undefined || val === null || (typeof val === 'string' && val.trim() === '')) {
      return `O campo '${field}' é obrigatório.`;
    }
  }

  return null;
}

function validateId(value) {
  if (value === null || value === undefined) return false;
  const num = Number(value);
  return Number.isInteger(num) && num > 0;
}

function validateDate(value) {
  if (!value) return false;
  const date = new Date(value);
  return !Number.isNaN(date.getTime());
}

function validateEnum(value, allowedValues) {
  if (!value) return false;
  return allowedValues.includes(value);
}

function validatePagination(query, defaultPage = 1, defaultLimit = 20) {
  let page = Number(query?.page) || defaultPage;
  let limit = Number(query?.limit) || defaultLimit;

  if (page < 1) page = 1;
  if (limit < 1 || limit > 100) limit = defaultLimit;

  const offset = (page - 1) * limit;

  return { page, limit, offset };
}

module.exports = {
  validateRequired,
  validateId,
  validateDate,
  validateEnum,
  validatePagination,
};
