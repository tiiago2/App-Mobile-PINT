const { sequelize, Utilizador, Consultor, Area, ServiceLine, LearningPath, Badge, RegistoBadge } = require('../models');
const { findActiveConsultor, toNumberOrNull, toStringOrNull } = require('../utils/consultor_helpers');

async function atualizarPerfil(req, res, next) {
  try {
    const idUtilizador = req.utilizadorLogado?.id_utilizador;
    const activeAccount = await findActiveConsultor(idUtilizador);

    if (!activeAccount) {
      return res.status(401).json({ error: 'Acesso não autorizado ou perfil inativo.' });
    }

    const { utilizador, consultor } = activeAccount;
    const { nome, email, telefone, lingua, imagem_perfil } = req.body;

    // Se email foi fornecido e é diferente, verificar duplicados
    if (email && email.trim() !== utilizador.email) {
      const emailExistente = await Utilizador.findOne({
        where: { email: email.trim() },
      });
      if (emailExistente) {
        return res.status(400).json({ error: 'O email especificado já se encontra em uso.' });
      }
    }

    const updateFieldsUtilizador = {};
    const updateFieldsConsultor = {};
    const now = new Date();

    if (nome && nome.trim()) {
      updateFieldsUtilizador.nome_user = nome.trim();
      updateFieldsConsultor.nome_user = nome.trim();
    }
    if (email && email.trim()) {
      updateFieldsUtilizador.email = email.trim();
      updateFieldsConsultor.email = email.trim();
    }
    if (telefone !== undefined) {
      const telNum = Number(telefone);
      if (!Number.isNaN(telNum)) {
        updateFieldsUtilizador.telefone = telNum;
        updateFieldsConsultor.telefone = telNum;
      }
    }
    if (lingua && lingua.trim()) {
      updateFieldsUtilizador.lingua = lingua.trim();
      updateFieldsConsultor.lingua = lingua.trim();
    }
    if (imagem_perfil !== undefined) {
      updateFieldsUtilizador.imagem_perfil = String(imagem_perfil);
      updateFieldsConsultor.imagem_perfil = String(imagem_perfil);
    }

    updateFieldsUtilizador.update_user = now;
    updateFieldsConsultor.update_user = now;

    await sequelize.transaction(async (transaction) => {
      await utilizador.update(updateFieldsUtilizador, { transaction });
      await consultor.update(updateFieldsConsultor, { transaction });
    });

    return res.status(200).json({
      message: 'Perfil atualizado com sucesso.',
      utilizador: {
        id: utilizador.id_utilizador,
        nome: utilizador.nome_user,
        email: utilizador.email,
        telefone: utilizador.telefone,
        lingua: utilizador.lingua,
        foto: utilizador.imagem_perfil,
      },
    });
  } catch (error) {
    return next(error);
  }
}

async function obterLearningPathProgresso(req, res, next) {
  try {
    const idUtilizador = req.utilizadorLogado?.id_utilizador;
    const activeAccount = await findActiveConsultor(idUtilizador);

    if (!activeAccount) {
      return res.status(401).json({ error: 'Acesso não autorizado ou perfil inativo.' });
    }

    const { consultor } = activeAccount;
    const idArea = toNumberOrNull(consultor.id_area);

    if (!idArea) {
      return res.status(200).json({
        learning_path: null,
        badges_conquistados: 0,
        badges_totais: 0,
        progresso: 0,
      });
    }

    const area = await Area.findOne({
      where: { id_area: idArea },
      include: [
        {
          model: ServiceLine,
          as: 'ServiceLine',
          include: [
            {
              model: LearningPath,
              as: 'LearningPath',
            },
          ],
        },
      ],
    });

    const serviceLine = area?.ServiceLine;
    const learningPath = serviceLine?.LearningPath;

    if (!learningPath) {
      return res.status(200).json({
        learning_path: null,
        badges_conquistados: 0,
        badges_totais: 0,
        progresso: 0,
      });
    }

    // Obter todas as ServiceLines do mesmo LearningPath
    const serviceLines = await ServiceLine.findAll({
      where: { id_learning_path: learningPath.id_learning_path },
      attributes: ['id_service_line'],
    });
    const serviceLineIds = serviceLines.map((s) => s.id_service_line);

    // Obter todas as Áreas pertencentes às ServiceLines
    const areas = await Area.findAll({
      where: { id_service_line: serviceLineIds },
      attributes: ['id_area'],
    });
    const areaIds = areas.map((a) => a.id_area);

    // Contar total de badges no LearningPath
    const badgesTotais = await Badge.count({
      where: {
        id_area: areaIds,
        deleted_badge: false,
      },
    });

    // Contar badges conquistados pelo consultor no LearningPath
    const registos = await RegistoBadge.findAll({
      where: {
        id_utilizador: idUtilizador,
        expirado: false,
      },
      include: [
        {
          model: Badge,
          as: 'Badge',
          where: { id_area: areaIds },
          attributes: ['id_badge'],
        },
      ],
    });

    const badgesConquistados = registos.length;
    const progresso = badgesTotais > 0 ? Number((badgesConquistados / badgesTotais).toFixed(2)) : 0;

    return res.status(200).json({
      learning_path: {
        id: learningPath.id_learning_path,
        nome: toStringOrNull(learningPath.nome_learning_path),
        descricao: toStringOrNull(learningPath.descricao_larning_path),
      },
      badges_conquistados: badgesConquistados,
      badges_totais: badgesTotais,
      progresso,
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  atualizarPerfil,
  obterLearningPathProgresso,
};
