const { QueryTypes } = require('sequelize');
const db = require('../models');
const { findActiveConsultor, toNumberOrNull, toStringOrNull } = require('../utils/consultor_helpers');

async function obterRankingGeral(req, res, next) {
  try {
    const idUtilizador = req.utilizadorLogado?.id_utilizador;
    const activeAccount = await findActiveConsultor(idUtilizador);

    if (!activeAccount) {
      return res.status(401).json({ error: 'Acesso não autorizado ou perfil inativo.' });
    }

    const { consultor } = activeAccount;
    const limit = Math.min(Math.max(Number(req.query.limit) || 20, 1), 100);

    const rows = await db.sequelize.query(
      `
      SELECT
        c.id_utilizador,
        c.nome_user AS nome,
        c.pontos_totais AS pontos,
        c.imagem_perfil AS img,
        a.nome_area AS area,
        sl.nome_service_line AS service_line
      FROM public.consultor c
      INNER JOIN public.utilizador u ON u.id_utilizador = c.id_utilizador
      LEFT JOIN public.area a ON a.id_area = c.id_area
      LEFT JOIN public.service_line sl ON sl.id_service_line = a.id_service_line
      WHERE c.ativo = true AND u.ativo = true
      ORDER BY c.pontos_totais DESC, c.id_utilizador ASC
      LIMIT :limit;
      `,
      {
        replacements: { limit },
        type: QueryTypes.SELECT,
      },
    );

    const rankResult = await db.sequelize.query(
      `
      SELECT COUNT(*)::int + 1 AS posicao
      FROM public.consultor c
      INNER JOIN public.utilizador u ON u.id_utilizador = c.id_utilizador
      WHERE c.ativo = true AND u.ativo = true AND c.pontos_totais > :pontosTotais;
      `,
      {
        replacements: { pontosTotais: consultor.pontos_totais || 0 },
        type: QueryTypes.SELECT,
      },
    );

    const countResult = await db.sequelize.query(
      `
      SELECT COUNT(*)::int AS total
      FROM public.consultor c
      INNER JOIN public.utilizador u ON u.id_utilizador = c.id_utilizador
      WHERE c.ativo = true AND u.ativo = true;
      `,
      { type: QueryTypes.SELECT },
    );

    const ranking = rows.map((row, idx) => ({
      id: toNumberOrNull(row.id_utilizador),
      posicao: idx + 1,
      nome: toStringOrNull(row.nome),
      area: toStringOrNull(row.area) || 'Geral',
      service_line: toStringOrNull(row.service_line) || 'Digital',
      pontos_sempre: toNumberOrNull(row.pontos) || 0,
      pontos: toNumberOrNull(row.pontos) || 0,
      img: toStringOrNull(row.img),
    }));

    return res.status(200).json({
      total_consultores: countResult[0]?.total || ranking.length,
      posicao_utilizador: rankResult[0]?.posicao || 1,
      ranking,
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  obterRankingGeral,
};
