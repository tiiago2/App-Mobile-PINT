const { Utilizador, Consultor, Role } = require('../models');

function toNumberOrNull(value) {
  if (value === null || value === undefined) return null;
  const numberValue = Number(value);
  return Number.isFinite(numberValue) ? numberValue : null;
}

function toBoolean(value) {
  if (value === true || value === false) return value;
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (normalized === 'true' || normalized === '1') return true;
    if (normalized === 'false' || normalized === '0') return false;
  }
  if (typeof value === 'number') return value === 1;
  return false;
}

function toIsoDateOrNull(value) {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

function toStringOrNull(value) {
  if (value === null || value === undefined) return null;
  const stringValue = String(value).trim();
  return stringValue.length > 0 ? stringValue : null;
}

function roleInclude() {
  return {
    model: Role,
    as: 'Roles',
    attributes: ['nome_role', 'icone_role'],
    through: { attributes: [] },
  };
}

function hasConsultorRole(utilizador) {
  return Boolean(
    utilizador?.Roles?.some((role) => role.nome_role?.trim().toLowerCase() === 'consultor'),
  );
}

async function findActiveConsultor(idUtilizador) {
  if (!idUtilizador) return null;

  const utilizador = await Utilizador.findOne({
    where: {
      id_utilizador: idUtilizador,
      ativo: true,
    },
    include: [roleInclude()],
  });

  if (!utilizador || !hasConsultorRole(utilizador)) return null;

  const consultor = await Consultor.findOne({
    where: {
      id_utilizador: idUtilizador,
      ativo: true,
    },
  });

  if (!consultor) return null;

  return { utilizador, consultor };
}

module.exports = {
  toNumberOrNull,
  toBoolean,
  toIsoDateOrNull,
  toStringOrNull,
  findActiveConsultor,
};
