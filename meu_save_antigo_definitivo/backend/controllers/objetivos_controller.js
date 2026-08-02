const { QueryTypes } = require('sequelize');
const db = require('../models');
const { findActiveConsultor, toNumberOrNull, toStringOrNull, toIsoDateOrNull } = require('../utils/consultor_helpers');
const { validateId, validateRequired, validateDate } = require('../utils/validators');

async function listarMeusObjetivos(req, res, next) {
  try {
    const idUtilizador = req.utilizadorLogado?.id_utilizador;
    const activeAccount = await findActiveConsultor(idUtilizador);

    if (!activeAccount) {
      return res.status(401).json({ error: 'Acesso não autorizado ou perfil inativo.' });
    }

    const rows = await db.sequelize.query(
      `
      SELECT
        obj.id_objetivo,
        obj.deadline,
        obj.criado_em,
        obj.ativo,
        b.id_badge,
        b.nome_badge,
        b.descricao_badge,
        b.imagem,
        b.especial,
        b.pontos_badge,
        a.nome_area,
        r.id_registo,
        r.data_obtencao,
        sub.status AS status_submissao
      FROM public.objetivos_consultor obj
      INNER JOIN public.badges b ON b.id_badge = obj.id_badge
      LEFT JOIN public.area a ON a.id_area = b.id_area
      LEFT JOIN LATERAL (
        SELECT reg.id_registo, reg.data_obtencao
        FROM public.registo_badges reg
        WHERE reg.id_badge = b.id_badge AND reg.id_utilizador = :idUtilizador AND reg.expirado = false
        ORDER BY reg.data_obtencao DESC
        LIMIT 1
      ) r ON TRUE
      LEFT JOIN LATERAL (
        SELECT sub.status
        FROM public.submissoes sub
        WHERE sub.id_badge = b.id_badge AND sub.id_utilizador = :idUtilizador
        ORDER BY sub.data_submissao DESC
        LIMIT 1
      ) sub ON TRUE
      WHERE obj.id_utilizador = :idUtilizador AND obj.ativo = true
      ORDER BY obj.deadline ASC;
      `,
      {
        replacements: { idUtilizador },
        type: QueryTypes.SELECT,
      },
    );

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const objetivos = rows.map((row) => {
      const deadlineDate = new Date(row.deadline);
      const diffTime = deadlineDate.getTime() - today.getTime();
      const diasRestantes = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      const concluido = row.id_registo !== null;
      const expirado = diasRestantes < 0 && !concluido;
      let progresso = 0.0;

      if (concluido) {
        progresso = 1.0;
      } else if (row.status_submissao === 'em_progresso') {
        progresso = 0.5;
      } else if (row.status_submissao === 'pendente') {
        progresso = 0.2;
      }

      return {
        id_objetivo: toNumberOrNull(row.id_objetivo),
        deadline: toIsoDateOrNull(row.deadline),
        diasRestantes: diasRestantes < 0 ? 0 : diasRestantes,
        progresso,
        ativo: !expirado && !concluido,
        concluido,
        expirado,
        badge: {
          id_badge: toNumberOrNull(row.id_badge),
          titulo: toStringOrNull(row.nome_badge),
          categoria: toStringOrNull(row.nome_area) || 'Geral',
          descricao: toStringOrNull(row.descricao_badge),
          imagem: toStringOrNull(row.imagem),
          especial: row.especial === true,
          pontos: toNumberOrNull(row.pontos_badge),
        },
      };
    });

    return res.status(200).json({
      total: objetivos.length,
      objetivos,
    });
  } catch (error) {
    // Se a tabela de objetivos ainda não existir na BD PostgreSQL
    if (error.original?.code === '42P01') {
      return res.status(200).json({ total: 0, objetivos: [] });
    }
    return next(error);
  }
}

async function criarObjetivo(req, res, next) {
  try {
    const idUtilizador = req.utilizadorLogado?.id_utilizador;
    const activeAccount = await findActiveConsultor(idUtilizador);

    if (!activeAccount) {
      return res.status(401).json({ error: 'Acesso não autorizado ou perfil inativo.' });
    }

    const validationError = validateRequired(['id_badge', 'deadline'], req.body);
    if (validationError) {
      return res.status(400).json({ error: validationError });
    }

    const idBadge = Number(req.body.id_badge);
    if (!validateId(idBadge)) {
      return res.status(400).json({ error: 'O id_badge deve ser um número inteiro válido.' });
    }

    if (!validateDate(req.body.deadline)) {
      return res.status(400).json({ error: 'A data limite (deadline) é inválida.' });
    }

    const deadlineDate = new Date(req.body.deadline);
    if (deadlineDate <= new Date()) {
      return res.status(400).json({ error: 'A data limite deve ser uma data futura.' });
    }

    const badge = await db.Badge.findOne({
      where: { id_badge: idBadge, deleted_badge: false },
    });

    if (!badge) {
      return res.status(404).json({ error: 'Badge não encontrado.' });
    }

    // Criar objetivo
    const novoObjetivo = await db.Objetivo.create({
      id_utilizador: idUtilizador,
      id_badge: idBadge,
      deadline: req.body.deadline,
      criado_em: new Date(),
      ativo: true,
    });

    return res.status(201).json({
      message: 'Objetivo criado com sucesso.',
      objetivo: {
        id_objetivo: novoObjetivo.id_objetivo,
        id_badge: novoObjetivo.id_badge,
        deadline: novoObjetivo.deadline,
        ativo: novoObjetivo.ativo,
      },
    });
  } catch (error) {
    return next(error);
  }
}

async function removerObjetivo(req, res, next) {
  try {
    const idUtilizador = req.utilizadorLogado?.id_utilizador;
    const activeAccount = await findActiveConsultor(idUtilizador);

    if (!activeAccount) {
      return res.status(401).json({ error: 'Acesso não autorizado ou perfil inativo.' });
    }

    const idObjetivo = Number(req.params.id);
    if (!validateId(idObjetivo)) {
      return res.status(400).json({ error: 'ID de objetivo inválido.' });
    }

    const objetivo = await db.Objetivo.findOne({
      where: {
        id_objetivo: idObjetivo,
        id_utilizador: idUtilizador,
      },
    });

    if (!objetivo) {
      return res.status(404).json({ error: 'Objetivo não encontrado.' });
    }

    await objetivo.update({ ativo: false });

    return res.status(200).json({
      message: 'Objetivo removido com sucesso.',
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  listarMeusObjetivos,
  criarObjetivo,
  removerObjetivo,
};
