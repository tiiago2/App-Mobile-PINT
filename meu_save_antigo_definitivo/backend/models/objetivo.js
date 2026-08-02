module.exports = (sequelize, DataTypes) => {
  return sequelize.define(
    'Objetivo',
    {
      id_objetivo: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      id_utilizador: {
        type: DataTypes.INTEGER,
        allowNull: false,
      },
      id_badge: {
        type: DataTypes.INTEGER,
        allowNull: false,
      },
      deadline: {
        type: DataTypes.DATEONLY,
        allowNull: false,
      },
      criado_em: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: DataTypes.NOW,
      },
      ativo: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: true,
      },
    },
    {
      tableName: 'objetivos_consultor',
      timestamps: false,
    },
  );
};
