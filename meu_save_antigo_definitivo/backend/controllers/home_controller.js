const { QueryTypes } = require('sequelize');
const db = require('../models');
const { findActiveConsultor, toNumberOrNull, toStringOrNull } = require('../utils/consultor_helpers');

async function obterDashboardHome(req, res, next) {
  try {
    const idUtilizador = req.utilizadorLogado?.id_utilizador;
    const activeAccount = await findActiveConsultor(idUtilizador);

    if (!activeAccount) {
      return res.status(401).json({ error: 'Acesso não autorizado ou perfil inativo.' });
    }

    const { consultor } = activeAccount;

    // 1. Objetivos Ativos (top 4)
    let objetivosAtivos = [];
    try {
      const objRows = await db.sequelize.query(
        `
        SELECT
          obj.id_objetivo, obj.deadline, b.id_badge, b.nome_badge, b.descricao_badge, b.pontos_badge, a.nome_area
        FROM public.objetivos_consultor obj
        INNER JOIN public.badges b ON b.id_badge = obj.id_badge
        LEFT JOIN public.area a ON a.id_area = b.id_area
        WHERE obj.id_utilizador = :idUtilizador AND obj.ativo = true AND obj.deadline >= CURRENT_DATE
        ORDER BY obj.deadline ASC
        LIMIT 4;
        `,
        { replacements: { idUtilizador }, type: QueryTypes.SELECT },
      );
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      objetivosAtivos = objRows.map((row) => {
        const deadlineDate = new Date(row.deadline);
        const diffDays = Math.ceil((deadlineDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24));
        return {
          id_objetivo: toNumberOrNull(row.id_objetivo),
          titulo: toStringOrNull(row.nome_badge),
          categoria: toStringOrNull(row.nome_area) || 'Geral',
          deadline: row.deadline,
          diasRestantes: diffDays < 0 ? 0 : diffDays,
          progresso: 0.5,
        };
      });
    } catch (err) {
      objetivosAtivos = [];
    }

    // 2. Badges em Progresso
    const submissoesProgressoRows = await db.sequelize.query(
      `
      SELECT sub.id_submissao, sub.data_submissao, b.id_badge, b.nome_badge, b.imagem, b.especial, a.nome_area
      FROM public.submissoes sub
      INNER JOIN public.badges b ON b.id_badge = sub.id_badge
      LEFT JOIN public.area a ON a.id_area = b.id_area
      WHERE sub.id_utilizador = :idUtilizador AND sub.status = 'em_progresso'
        AND COALESCE(b.deleted_badge, false) = false
      ORDER BY sub.data_submissao DESC
      LIMIT 5;
      `,
      { replacements: { idUtilizador }, type: QueryTypes.SELECT },
    );

    const badgesEmProgresso = submissoesProgressoRows.map((row) => ({
      id_badge: toNumberOrNull(row.id_badge),
      titulo: toStringOrNull(row.nome_badge),
      categoria: toStringOrNull(row.nome_area) || 'Geral',
      estado: 'emProgresso',
      progresso: 50,
      especial: row.especial === true,
      imagem: toStringOrNull(row.imagem),
    }));

    // 3. Top 10 Ranking
    const rankingRows = await db.sequelize.query(
      `
      SELECT c.id_utilizador, c.nome_user AS nome, c.pontos_totais AS pontos, c.imagem_perfil AS img, a.nome_area AS area
      FROM public.consultor c
      INNER JOIN public.utilizador u ON u.id_utilizador = c.id_utilizador
      LEFT JOIN public.area a ON a.id_area = c.id_area
      WHERE c.ativo = true AND u.ativo = true
      ORDER BY c.pontos_totais DESC, c.id_utilizador ASC
      LIMIT 10;
      `,
      { type: QueryTypes.SELECT },
    );

    const rankResult = await db.sequelize.query(
      `
      SELECT COUNT(*)::int + 1 AS posicao
      FROM public.consultor c
      INNER JOIN public.utilizador u ON u.id_utilizador = c.id_utilizador
      WHERE c.ativo = true AND u.ativo = true AND c.pontos_totais > :pontosTotais;
      `,
      { replacements: { pontosTotais: consultor.pontos_totais || 0 }, type: QueryTypes.SELECT },
    );

    const ranking = rankingRows.map((row, idx) => ({
      id: toNumberOrNull(row.id_utilizador),
      posicao: idx + 1,
      nome: toStringOrNull(row.nome),
      area: toStringOrNull(row.area) || 'Geral',
      pontos: toNumberOrNull(row.pontos) || 0,
      img: toStringOrNull(row.img),
    }));

    return res.status(200).json({
      objetivos_ativos: objetivosAtivos,
      badges_em_progresso: badgesEmProgresso,
      posicao_utilizador: rankResult[0]?.posicao || 1,
      ranking_top10: ranking,
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  obterDashboardHome,
};
