module.exports = (sequelize, DataTypes) => {
  return sequelize.define(
    'Role',
    {
      id_role: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      nome_role: {
        type: DataTypes.TEXT,
        allowNull: false,
      },
      icone_role: {
        type: DataTypes.TEXT,
        allowNull: false,
      },
    },
    {
      tableName: 'role',
      timestamps: false,
    },
  );
};
