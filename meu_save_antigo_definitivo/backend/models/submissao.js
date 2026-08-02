module.exports = (sequelize, DataTypes) => {
  return sequelize.define(
    'Submissao',
    {
      id_submissao: {
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
      status: {
        type: DataTypes.TEXT,
        allowNull: false,
        defaultValue: 'pendente',
      },
      data_submissao: {
        type: DataTypes.DATE,
        allowNull: false,
        defaultValue: DataTypes.NOW,
      },
    },
    {
      tableName: 'submissoes',
      timestamps: false,
    },
  );
};
