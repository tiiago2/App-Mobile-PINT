module.exports = (sequelize, DataTypes) => {
  return sequelize.define(
    'RegistoBadge',
    {
      id_registo: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      id_badge: {
        type: DataTypes.INTEGER,
        allowNull: false,
      },
      id_utilizador: {
        type: DataTypes.INTEGER,
        allowNull: false,
      },
      data_obtencao: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: DataTypes.NOW,
      },
      expirado: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      },
    },
    {
      tableName: 'registo_badges',
      timestamps: false,
    },
  );
};
