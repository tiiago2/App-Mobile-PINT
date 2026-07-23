const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const {
  sequelize,
  Utilizador,
  Consultor,
  Role,
  Area,
  ServiceLine,
  LearningPath,
} = require('../models');

const PASSWORD_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.#^~_\-+=])[A-Za-z\d@$!%*?&.#^~_\-+=]{8,}$/;
const CREDENTIALS_ERROR = 'Email ou password incorretos!';
const SESSION_ERROR = 'Sessão inválida ou expirada.';

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

function mapConsultorRoles(utilizador) {
  return (utilizador.Roles || [])
    .filter((role) => role.nome_role?.trim().toLowerCase() === 'consultor')
    .map((role) => ({
      nome: role.nome_role,
      icone_role: role.icone_role,
    }));
}

async function findUtilizadorByEmail(email) {
  return Utilizador.findOne({
    where: { email },
    include: [roleInclude()],
  });
}

async function findValidConsultorAccount(email) {
  const utilizador = await findUtilizadorByEmail(email);

  if (!utilizador || !hasConsultorRole(utilizador) || utilizador.ativo !== true) {
    return null;
  }

  const consultor = await Consultor.findOne({
    where: { id_utilizador: utilizador.id_utilizador },
  });

  if (!consultor || consultor.ativo !== true) {
    return null;
  }

  return { utilizador, consultor };
}

function createAccessToken(idUtilizador) {
  return jwt.sign(
    {
      id_utilizador: idUtilizador,
      role: 'Consultor',
      token_type: 'access',
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '8h' },
  );
}

function createRefreshToken(idUtilizador) {
  return jwt.sign(
    {
      id_utilizador: idUtilizador,
      role: 'Consultor',
      token_type: 'refresh',
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '365d' },
  );
}

function validatePasswordRequest(email, password, confirmPassword) {
  if (!email || !password || !confirmPassword) {
    return { status: 400, body: { error: 'Todos os campos são obrigatórios.' } };
  }

  if (!PASSWORD_REGEX.test(password)) {
    return {
      status: 400,
      body: { error: 'A palavra-passe não cumpre os requisitos mínimos.' },
    };
  }

  if (password !== confirmPassword) {
    return { status: 400, body: { error: 'As palavras-passe não coincidem.' } };
  }

  return null;
}

async function login(req, res, next) {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Todos os campos são obrigatórios.' });
    }

    const account = await findValidConsultorAccount(email.trim());

    if (!account) {
      return res.status(401).json({ error: CREDENTIALS_ERROR });
    }

    const { utilizador, consultor } = account;
    const passwordMatches = await bcrypt.compare(password, utilizador.password);

    if (!passwordMatches) {
      return res.status(401).json({ error: CREDENTIALS_ERROR });
    }

    if (utilizador.primeiro_login === true || consultor.primeiro_login === true) {
      return res.status(200).json({
        requiresPasswordChange: true,
        utilizador: {
          id: utilizador.id_utilizador,
          nome: utilizador.nome_user,
          email: utilizador.email,
          primeiro_login: true,
          aceitacao_politicas: utilizador.aceitacao_politicas,
          roles: mapConsultorRoles(utilizador),
        },
      });
    }

    return res.status(200).json({
      requiresPasswordChange: false,
      token: createAccessToken(utilizador.id_utilizador),
      refreshToken: createRefreshToken(utilizador.id_utilizador),
      utilizador: {
        id: utilizador.id_utilizador,
        nome: utilizador.nome_user,
        email: utilizador.email,
        lingua: utilizador.lingua,
        imagem_perfil: utilizador.imagem_perfil,
        primeiro_login: false,
        aceitacao_politicas: utilizador.aceitacao_politicas,
        pontos_totais: consultor.pontos_totais,
        id_area: consultor.id_area,
        roles: mapConsultorRoles(utilizador),
      },
    });
  } catch (error) {
    return next(error);
  }
}

async function primeiroAcesso(req, res, next) {
  try {
    const { email, password, confirmPassword } = req.body;
    const validationError = validatePasswordRequest(email, password, confirmPassword);

    if (validationError) {
      return res.status(validationError.status).json(validationError.body);
    }

    const account = await findValidConsultorAccount(email.trim());

    if (!account) {
      return res.status(404).json({ error: 'Email não encontrado.' });
    }

    const { utilizador, consultor } = account;

    if (utilizador.primeiro_login === false && consultor.primeiro_login === false) {
      return res.status(400).json({
        error: 'Este utilizador já concluiu a alteração de palavra-passe no primeiro acesso.',
      });
    }

    const hash = await bcrypt.hash(password, 10);
    const now = new Date();

    await sequelize.transaction(async (transaction) => {
      await utilizador.update(
        {
          password: hash,
          primeiro_login: false,
          aceitacao_politicas: true,
          update_user: now,
        },
        { transaction },
      );

      await consultor.update(
        {
          password: hash,
          primeiro_login: false,
          aceitacao_politicas: true,
          update_user: now,
        },
        { transaction },
      );
    });

    return res.status(200).json({
      message: 'Palavra-passe definida com sucesso. Já pode iniciar sessão.',
    });
  } catch (error) {
    return next(error);
  }
}

async function esqueciPassword(req, res, next) {
  try {
    const { email, password, confirmPassword } = req.body;
    const validationError = validatePasswordRequest(email, password, confirmPassword);

    if (validationError) {
      return res.status(validationError.status).json(validationError.body);
    }

    const account = await findValidConsultorAccount(email.trim());

    if (!account) {
      return res.status(404).json({ error: 'Email não encontrado.' });
    }

    const { utilizador, consultor } = account;
    const hash = await bcrypt.hash(password, 10);
    const now = new Date();

    await sequelize.transaction(async (transaction) => {
      await utilizador.update(
        {
          password: hash,
          update_user: now,
        },
        { transaction },
      );

      await consultor.update(
        {
          password: hash,
          update_user: now,
        },
        { transaction },
      );
    });

    return res.status(200).json({
      message: 'Palavra-passe alterada com sucesso.',
    });
  } catch (error) {
    return next(error);
  }
}

async function refreshToken(req, res, next) {
  try {
    const { refreshToken: token } = req.body;

    if (!token) {
      return res.status(401).json({ error: SESSION_ERROR });
    }

    let payload;

    try {
      payload = jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      return res.status(401).json({ error: SESSION_ERROR });
    }

    const isValidPayload =
      payload &&
      payload.token_type === 'refresh' &&
      payload.role === 'Consultor' &&
      payload.id_utilizador;

    if (!isValidPayload) {
      return res.status(401).json({ error: SESSION_ERROR });
    }

    const utilizador = await Utilizador.findOne({
      where: { id_utilizador: payload.id_utilizador },
      include: [roleInclude()],
    });

    if (!utilizador || !hasConsultorRole(utilizador) || utilizador.ativo !== true) {
      return res.status(401).json({ error: SESSION_ERROR });
    }

    const consultor = await Consultor.findOne({
      where: { id_utilizador: utilizador.id_utilizador },
    });

    const validAccount =
      consultor &&
      consultor.ativo === true &&
      utilizador.primeiro_login === false &&
      consultor.primeiro_login === false;

    if (!validAccount) {
      return res.status(401).json({ error: SESSION_ERROR });
    }

    return res.status(200).json({
      token: createAccessToken(utilizador.id_utilizador),
    });
  } catch (error) {
    return next(error);
  }
}

async function getUser(req, res, next) {
  try {
    const utilizador = await Utilizador.findOne({
      where: { id_utilizador: req.utilizadorLogado.id_utilizador },
      include: [
        {
          model: Consultor,
          as: 'Consultor',
          include: [
            {
              model: Area,
              as: 'Area',
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
            },
          ],
        },
      ],
    });

    const consultor = utilizador?.Consultor;

    if (!utilizador || utilizador.ativo !== true || !consultor || consultor.ativo !== true) {
      return res.status(401).json({ error: 'Acesso não autorizado.' });
    }

    const area = consultor.Area || null;
    const serviceLine = area?.ServiceLine || null;
    const learningPath = serviceLine?.LearningPath || null;

    return res.status(200).json({
      utilizador: {
        id: utilizador.id_utilizador,
        nome: utilizador.nome_user,
        email: utilizador.email,
        telefone: utilizador.telefone,
        lingua: utilizador.lingua,
        foto: utilizador.imagem_perfil,
        ultimoLogin: utilizador.last_login,
        pontosTotais: consultor.pontos_totais,
        aceitacaoPoliticas: utilizador.aceitacao_politicas,
        primeiroLogin: utilizador.primeiro_login,
        area: area
          ? {
              id: area.id_area,
              nome: area.nome_area,
            }
          : null,
        serviceLine: serviceLine
          ? {
              id: serviceLine.id_service_line,
              nome: serviceLine.nome_service_line,
            }
          : null,
        learningPath: learningPath
          ? {
              id: learningPath.id_learning_path,
              nome: learningPath.nome_learning_path,
            }
          : null,
      },
    });
  } catch (error) {
    return next(error);
  }
}

async function putLastLogin(req, res, next) {
  try {
    const idUtilizador = req.utilizadorLogado.id_utilizador;
    const now = new Date();

    await sequelize.transaction(async (transaction) => {
      await Utilizador.update(
        {
          last_login: now,
          update_user: now,
        },
        {
          where: { id_utilizador: idUtilizador },
          transaction,
        },
      );

      await Consultor.update(
        {
          last_login: now,
          update_user: now,
        },
        {
          where: { id_utilizador: idUtilizador },
          transaction,
        },
      );
    });

    return res.status(200).json({
      message: 'Last Login adicionado com sucesso',
    });
  } catch (error) {
    return next(error);
  }
}

async function aceitarRgpd(req, res, next) {
  try {
    const idUtilizador = req.utilizadorLogado.id_utilizador;
    const now = new Date();

    await sequelize.transaction(async (transaction) => {
      await Utilizador.update(
        {
          aceitacao_politicas: true,
          update_user: now,
        },
        {
          where: { id_utilizador: idUtilizador },
          transaction,
        },
      );

      await Consultor.update(
        {
          aceitacao_politicas: true,
          update_user: now,
        },
        {
          where: { id_utilizador: idUtilizador },
          transaction,
        },
      );
    });

    return res.status(200).json({
      message: 'Políticas RGPD aceites com sucesso.',
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  login,
  primeiroAcesso,
  esqueciPassword,
  refreshToken,
  getUser,
  putLastLogin,
  aceitarRgpd,
};
