const { toNumberOrNull, toIsoDateOrNull } = require('./consultor_helpers');

function calcularDataExpiracao(dataObtencao, validade) {
  const dataObtencaoIso = toIsoDateOrNull(dataObtencao);
  const validadeDias = toNumberOrNull(validade);

  if (!dataObtencaoIso || validadeDias === null || validadeDias <= 0) {
    return null;
  }

  const data = new Date(dataObtencaoIso);
  const dataExpiracao = new Date(
    Date.UTC(
      data.getUTCFullYear(),
      data.getUTCMonth(),
      data.getUTCDate() + validadeDias,
      data.getUTCHours(),
      data.getUTCMinutes(),
      data.getUTCSeconds(),
      data.getUTCMilliseconds(),
    ),
  );

  return dataExpiracao.toISOString();
}

function calcularEstado({ temRegisto, registoExpirado, dataExpiracao, statusSubmissao }) {
  const inconsistencias = [];
  const expirouPorData = dataExpiracao
    ? new Date(dataExpiracao).getTime() <= Date.now()
    : false;

  if (temRegisto && (registoExpirado || expirouPorData)) {
    return { estado: 'expirados', inconsistencias };
  }

  if (temRegisto) {
    return { estado: 'conquistados', inconsistencias };
  }

  switch (statusSubmissao?.toLowerCase()) {
    case 'pendente':
      return { estado: 'pendentes', inconsistencias };
    case 'recusada':
      return { estado: 'recusados', inconsistencias };
    case 'em_progresso':
      return { estado: 'emProgresso', inconsistencias };
    case 'aceite':
      inconsistencias.push('submissao_aceite_sem_registo');
      return { estado: 'pendentes', inconsistencias };
    default:
      return { estado: 'disponivel', inconsistencias };
  }
}

module.exports = {
  calcularDataExpiracao,
  calcularEstado,
};
