const { QueryTypes } = require('sequelize');
const db = require('../models');

function toNumberOrNull(value) {
  if (value === null || value === undefined) {
    return null;
  }

  const numberValue = Number(value);
  return Number.isFinite(numberValue) ? numberValue : null;
}

function toBoolean(value) {
  if (value === true || value === false) {
    return value;
  }

  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (normalized === 'true' || normalized === '1') {
      return true;
    }
    if (normalized === 'false' || normalized === '0') {
      return false;
    }
  }

  if (typeof value === 'number') {
    return value === 1;
  }

  return false;
}

function toIsoDateOrNull(value) {
  if (!value) {
    return null;
  }

  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

function toStringOrNull(value) {
  if (value === null || value === undefined) {
    return null;
  }

  const stringValue = String(value).trim();
  return stringValue.length > 0 ? stringValue : null;
}

function normalizarStatus(status) {
  return toStringOrNull(status)?.toLowerCase() ?? null;
}

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

  switch (statusSubmissao) {
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

function mapBadge(row, idAreaConsultor) {
  const idBadge = toNumberOrNull(row.id_badge);
  const idArea = toNumberOrNull(row.id_area);
  const idNivel = toNumberOrNull(row.id_nivel);
  const pontosBadge = toNumberOrNull(row.pontos_badge);
  const validade = toNumberOrNull(row.validade);
  const idSubmissao = toNumberOrNull(row.id_submissao);
  const idRegisto = toNumberOrNull(row.id_registo);
  const dataSubmissao = toIsoDateOrNull(row.data_submissao);
  const dataObtencao = toIsoDateOrNull(row.data_obtencao);
  const dataExpiracao = calcularDataExpiracao(row.data_obtencao, validade);
  const statusSubmissao = normalizarStatus(row.status_submissao);
  const registoExpirado = toBoolean(row.registo_expirado);
  const temRegisto = idRegisto !== null;
  const { estado, inconsistencias } = calcularEstado({
    temRegisto,
    registoExpirado,
    dataExpiracao,
    statusSubmissao,
  });

  return {
    id_badge: idBadge,
    nome_badge: toStringOrNull(row.nome_badge),
    descricao_badge: toStringOrNull(row.descricao_badge),
    imagem: toStringOrNull(row.imagem),
    especial: toBoolean(row.especial),
    pontos_badge: pontosBadge,
    validade,
    update_badge: toIsoDateOrNull(row.update_badge),

    area:
      idArea !== null && row.nome_area !== null
        ? {
            id_area: idArea,
            nome_area: toStringOrNull(row.nome_area),
            id_service_line: toNumberOrNull(row.id_service_line),
          }
        : null,

    nivel:
      idNivel !== null || row.nome_nivel !== null
        ? {
            id_nivel: idNivel,
            nome_nivel: toStringOrNull(row.nome_nivel),
          }
        : null,

    minha_area: idArea !== null && idAreaConsultor !== null && idArea === idAreaConsultor,
    estado,
    progresso: estado === 'conquistados' ? 100 : 0,

    data_candidatura: dataSubmissao,
    data_obtencao: dataObtencao,
    data_expiracao: dataExpiracao,

    submissao:
      idSubmissao !== null
        ? {
            id_submissao: idSubmissao,
            status: toStringOrNull(row.status_submissao),
            data_submissao: dataSubmissao,
          }
        : null,

    registo:
      idRegisto !== null
        ? {
            id_registo: idRegisto,
            data_obtencao: dataObtencao,
            expirado: registoExpirado,
          }
        : null,

    inconsistencias,
  };
}

exports.listarMeusBadges = async (req, res) => {
  try {
    const idUtilizador = req.utilizadorLogado?.id_utilizador;

    if (!idUtilizador) {
      return res.status(401).json({ error: 'Utilizador nao autenticado.' });
    }

    const utilizador = await db.Utilizador.findOne({
      where: {
        id_utilizador: idUtilizador,
        ativo: true,
      },
    });

    if (!utilizador) {
      return res.status(404).json({ error: 'Utilizador nao encontrado.' });
    }

    const consultor = await db.Consultor.findOne({
      where: {
        id_utilizador: idUtilizador,
        ativo: true,
      },
    });

    if (!consultor) {
      return res.status(403).json({ error: 'Utilizador sem registo de consultor.' });
    }

    const idAreaConsultor = toNumberOrNull(consultor.id_area);
    const rows = await db.sequelize.query(
      `
      SELECT
          b.id_badge,
          b.id_area,
          b.id_nivel,
          b.validade,
          b.especial,
          b.pontos_badge,
          b.nome_badge,
          b.imagem,
          b.update_badge,
          b.descricao_badge,

          a.nome_area,
          a.id_service_line,

          n.nome_nivel,

          s.id_submissao,
          s.status AS status_submissao,
          s.data_submissao,

          r.id_registo,
          r.data_obtencao,
          r.expirado AS registo_expirado

      FROM public.badges b

      LEFT JOIN public.area a
          ON a.id_area = b.id_area

      LEFT JOIN public.nivel n
          ON n.id_nivel = b.id_nivel

      LEFT JOIN LATERAL (
          SELECT
              sub.id_submissao,
              sub.status,
              sub.data_submissao
          FROM public.submissoes sub
          WHERE sub.id_badge = b.id_badge
            AND sub.id_utilizador = :idUtilizador
          ORDER BY
              sub.data_submissao DESC NULLS LAST,
              sub.id_submissao DESC
          LIMIT 1
      ) s ON TRUE

      LEFT JOIN LATERAL (
          SELECT
              reg.id_registo,
              reg.data_obtencao,
              reg.expirado
          FROM public.registo_badges reg
          WHERE reg.id_badge = b.id_badge
            AND reg.id_utilizador = :idUtilizador
          ORDER BY
              reg.data_obtencao DESC NULLS LAST,
              reg.id_registo DESC
          LIMIT 1
      ) r ON TRUE

      WHERE COALESCE(b.deleted_badge, false) = false

      ORDER BY
          b.especial DESC,
          CASE WHEN b.id_area = :idAreaConsultor THEN 0 ELSE 1 END,
          a.nome_area ASC NULLS LAST,
          b.id_nivel ASC NULLS LAST,
          b.nome_badge ASC;
      `,
      {
        replacements: {
          idUtilizador,
          idAreaConsultor,
        },
        type: QueryTypes.SELECT,
      },
    );

    const badges = rows.map((row) => mapBadge(row, idAreaConsultor));

    return res.status(200).json({
      id_utilizador: toNumberOrNull(idUtilizador),
      id_area_consultor: idAreaConsultor,
      total: badges.length,
      badges,
    });
  } catch (error) {
    console.error('Backend PDM: erro ao listar badges do consultor.');
    return res.status(500).json({
      error: 'Erro ao listar badges do consultor.',
    });
  }
};
