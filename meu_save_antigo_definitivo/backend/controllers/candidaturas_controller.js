const { QueryTypes } = require('sequelize');
const db = require('../models');
const { findActiveConsultor, toNumberOrNull, toStringOrNull, toIsoDateOrNull } = require('../utils/consultor_helpers');
const { validateId, validateRequired } = require('../utils/validators');
const { calcularDataExpiracao, calcularEstado } = require('../utils/badge_state');


async function listarMinhasCandidaturas(req, res, next) {
  try {
    const idUtilizador = req.utilizadorLogado?.id_utilizador;
    const activeAccount = await findActiveConsultor(idUtilizador);

    if (!activeAccount) {
      return res.status(401).json({ error: 'Acesso não autorizado ou perfil inativo.' });
    }

    const { consultor } = activeAccount;
    const idAreaConsultor = toNumberOrNull(consultor.id_area);

    const rows = await db.sequelize.query(
      `
      SELECT
        sub.id_submissao,
        sub.status AS status_submissao,
        sub.data_submissao,
        b.id_badge,
        b.nome_badge,
        b.descricao_badge,
        b.imagem,
        b.especial,
        b.pontos_badge,
        b.validade,
        a.id_area,
        a.nome_area,
        r.id_registo,
        r.data_obtencao,
        r.expirado AS registo_expirado
      FROM public.submissoes sub
      INNER JOIN public.badges b ON b.id_badge = sub.id_badge
      LEFT JOIN public.area a ON a.id_area = b.id_area
      LEFT JOIN LATERAL (
        SELECT reg.id_registo, reg.data_obtencao, reg.expirado
        FROM public.registo_badges reg
        WHERE reg.id_badge = b.id_badge AND reg.id_utilizador = :idUtilizador
        ORDER BY reg.data_obtencao DESC NULLS LAST, reg.id_registo DESC
        LIMIT 1
      ) r ON TRUE
      WHERE sub.id_utilizador = :idUtilizador
        AND COALESCE(b.deleted_badge, false) = false
      ORDER BY sub.data_submissao DESC NULLS LAST, sub.id_submissao DESC;
      `,
      {
        replacements: { idUtilizador },
        type: QueryTypes.SELECT,
      },
    );

    const candidaturas = rows.map((row) => {
      const idRegisto = toNumberOrNull(row.id_registo);
      const temRegisto = idRegisto !== null;
      const validade = toNumberOrNull(row.validade);
      const dataObtencao = toIsoDateOrNull(row.data_obtencao);
      const dataExpiracao = calcularDataExpiracao(row.data_obtencao, validade);
      const { estado } = calcularEstado({
        temRegisto,
        registoExpirado: row.registo_expirado === true,
        dataExpiracao,
        statusSubmissao: row.status_submissao,
      });

      return {
        id_submissao: toNumberOrNull(row.id_submissao),
        status: toStringOrNull(row.status_submissao),
        estado_calculado: estado,
        data_submissao: toIsoDateOrNull(row.data_submissao),
        data_obtencao: dataObtencao,
        data_expiracao: dataExpiracao,
        progresso: estado === 'conquistados' || row.status_submissao === 'aceite' ? 100 : (row.status_submissao === 'em_progresso' ? 50 : 0),
        badge: {
          id_badge: toNumberOrNull(row.id_badge),
          nome_badge: toStringOrNull(row.nome_badge),
          descricao_badge: toStringOrNull(row.descricao_badge),
          imagem: toStringOrNull(row.imagem),
          especial: row.especial === true,
          pontos_badge: toNumberOrNull(row.pontos_badge),
          area_nome: toStringOrNull(row.nome_area),
          minha_area: idAreaConsultor !== null && row.id_area === idAreaConsultor,
        },
      };
    });

    return res.status(200).json({
      pontos_totais: toNumberOrNull(consultor.pontos_totais) || 0,
      total: candidaturas.length,
      candidaturas,
    });
  } catch (error) {
    return next(error);
  }
}

async function submeterCandidatura(req, res, next) {
  try {
    const idUtilizador = req.utilizadorLogado?.id_utilizador;
    const activeAccount = await findActiveConsultor(idUtilizador);

    if (!activeAccount) {
      return res.status(401).json({ error: 'Acesso não autorizado ou perfil inativo.' });
    }

    const validationError = validateRequired(['id_badge'], req.body);
    if (validationError) {
      return res.status(400).json({ error: validationError });
    }

    const idBadge = Number(req.body.id_badge);
    if (!validateId(idBadge)) {
      return res.status(400).json({ error: 'O id_badge deve ser um número inteiro válido.' });
    }

    const badge = await db.Badge.findOne({
      where: {
        id_badge: idBadge,
        deleted_badge: false,
      },
    });

    if (!badge) {
      return res.status(404).json({ error: 'Badge não encontrado ou inativo.' });
    }

    // Verificar se já existe submissão ativa ou pendente
    const submissaoExistente = await db.Submissao.findOne({
      where: {
        id_badge: idBadge,
        id_utilizador: idUtilizador,
        status: ['pendente', 'em_progresso'],
      },
    });

    if (submissaoExistente) {
      return res.status(400).json({
        error: 'Já possui uma candidatura pendente ou em progresso para este badge.',
      });
    }

    // Verificar se já possui registo válido do badge
    const registoExistente = await db.RegistoBadge.findOne({
      where: {
        id_badge: idBadge,
        id_utilizador: idUtilizador,
        expirado: false,
      },
    });

    if (registoExistente) {
      return res.status(400).json({
        error: 'Já possui este badge conquistado e dentro do prazo de validade.',
      });
    }

    const novaSubmissao = await db.Submissao.create({
      id_badge: idBadge,
      id_utilizador: idUtilizador,
      status: 'pendente',
      data_submissao: new Date(),
    });

    return res.status(201).json({
      message: 'Candidatura submetida com sucesso.',
      submissao: {
        id_submissao: novaSubmissao.id_submissao,
        id_badge: novaSubmissao.id_badge,
        status: novaSubmissao.status,
        data_submissao: novaSubmissao.data_submissao,
      },
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  listarMinhasCandidaturas,
  submeterCandidatura,
};
