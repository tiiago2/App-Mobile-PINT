const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Utilizador = require('./utilizador')(sequelize, DataTypes);
const Consultor = require('./consultor')(sequelize, DataTypes);
const Role = require('./role')(sequelize, DataTypes);
const UtilizadorRoles = require('./utilizador_roles')(sequelize, DataTypes);
const Area = require('./area')(sequelize, DataTypes);
const ServiceLine = require('./service_line')(sequelize, DataTypes);
const LearningPath = require('./learning_path')(sequelize, DataTypes);

Utilizador.hasOne(Consultor, {
  foreignKey: 'id_utilizador',
  as: 'Consultor',
});

Consultor.belongsTo(Utilizador, {
  foreignKey: 'id_utilizador',
  as: 'Utilizador',
});

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

Area.hasMany(Consultor, {
  foreignKey: 'id_area',
  as: 'Consultores',
});

Consultor.belongsTo(Area, {
  foreignKey: 'id_area',
  as: 'Area',
});

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

module.exports = {
  sequelize,
  Utilizador,
  Consultor,
  Role,
  UtilizadorRoles,
  Area,
  ServiceLine,
  LearningPath,
};
