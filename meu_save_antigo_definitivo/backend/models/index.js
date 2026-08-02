const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Utilizador = require('./utilizador')(sequelize, DataTypes);
const Consultor = require('./consultor')(sequelize, DataTypes);
const Role = require('./role')(sequelize, DataTypes);
const UtilizadorRoles = require('./utilizador_roles')(sequelize, DataTypes);
const Area = require('./area')(sequelize, DataTypes);
const ServiceLine = require('./service_line')(sequelize, DataTypes);
const LearningPath = require('./learning_path')(sequelize, DataTypes);
const Badge = require('./badge')(sequelize, DataTypes);
const Submissao = require('./submissao')(sequelize, DataTypes);
const RegistoBadge = require('./registo_badge')(sequelize, DataTypes);
const Nivel = require('./nivel')(sequelize, DataTypes);
const Objetivo = require('./objetivo')(sequelize, DataTypes);

// Utilizador & Consultor
Utilizador.hasOne(Consultor, {
  foreignKey: 'id_utilizador',
  as: 'Consultor',
});

Consultor.belongsTo(Utilizador, {
  foreignKey: 'id_utilizador',
  as: 'Utilizador',
});

// Roles
Utilizador.belongsToMany(Role, {
  through: UtilizadorRoles,
  foreignKey: 'id_utilizador',
  otherKey: 'id_role',
  as: 'Roles',
});

Role.belongsToMany(Utilizador, {
  through: UtilizadorRoles,
  foreignKey: 'id_role',
  otherKey: 'id_utilizador',
  as: 'Utilizadores',
});

// Area & Consultor
Area.hasMany(Consultor, {
  foreignKey: 'id_area',
  as: 'Consultores',
});

Consultor.belongsTo(Area, {
  foreignKey: 'id_area',
  as: 'Area',
});

// Organizational Hierarchy
LearningPath.hasMany(ServiceLine, {
  foreignKey: 'id_learning_path',
  as: 'ServiceLines',
});

ServiceLine.belongsTo(LearningPath, {
  foreignKey: 'id_learning_path',
  as: 'LearningPath',
});

ServiceLine.hasMany(Area, {
  foreignKey: 'id_service_line',
  as: 'Areas',
});

Area.belongsTo(ServiceLine, {
  foreignKey: 'id_service_line',
  as: 'ServiceLine',
});

// Badges, Submissoes, RegistoBadges, Nivel
Badge.belongsTo(Area, {
  foreignKey: 'id_area',
  as: 'Area',
});

Area.hasMany(Badge, {
  foreignKey: 'id_area',
  as: 'Badges',
});

Badge.belongsTo(Nivel, {
  foreignKey: 'id_nivel',
  as: 'Nivel',
});

Nivel.hasMany(Badge, {
  foreignKey: 'id_nivel',
  as: 'Badges',
});

Submissao.belongsTo(Badge, {
  foreignKey: 'id_badge',
  as: 'Badge',
});

Submissao.belongsTo(Utilizador, {
  foreignKey: 'id_utilizador',
  as: 'Utilizador',
});

RegistoBadge.belongsTo(Badge, {
  foreignKey: 'id_badge',
  as: 'Badge',
});

RegistoBadge.belongsTo(Utilizador, {
  foreignKey: 'id_utilizador',
  as: 'Utilizador',
});

Objetivo.belongsTo(Badge, {
  foreignKey: 'id_badge',
  as: 'Badge',
});

Objetivo.belongsTo(Utilizador, {
  foreignKey: 'id_utilizador',
  as: 'Utilizador',
});

module.exports = {
  sequelize,
  Utilizador,
  Consultor,
  Role,
  UtilizadorRoles,
  Area,
  ServiceLine,
  LearningPath,
  Badge,
  Submissao,
  RegistoBadge,
  Nivel,
  Objetivo,
};
