module.exports = (sequelize, DataTypes) => {
  return sequelize.define(
    'Badge',
    {
      id_badge: {
        type: DataTypes.INTEGER,
        primaryKey: true,
        autoIncrement: true,
      },
      id_area: {
        type: DataTypes.INTEGER,
        allowNull: true,
      },
      id_nivel: {
        type: DataTypes.INTEGER,
        allowNull: true,
      },
      validade: {
        type: DataTypes.INTEGER,
        allowNull: true,
      },
      especial: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      },
      pontos_badge: {
        type: DataTypes.INTEGER,
        allowNull: false,
        defaultValue: 0,
      },
      nome_badge: {
        type: DataTypes.TEXT,
        allowNull: false,
      },
      imagem: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
      update_badge: {
        type: DataTypes.DATE,
        allowNull: true,
      },
      descricao_badge: {
        type: DataTypes.TEXT,
        allowNull: true,
      },
      deleted_badge: {
        type: DataTypes.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      },
    },
    {
      tableName: 'badges',
      timestamps: false,
    },
  );
};
