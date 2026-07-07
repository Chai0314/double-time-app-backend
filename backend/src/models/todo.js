'use strict';
const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');
const { User, Couple } = require('./user');
const { Schedule } = require('./schedule');

const Todo = sequelize.define(
  'Todo',
  {
    id: { type: DataTypes.BIGINT.UNSIGNED, primaryKey: true, autoIncrement: true },
    coupleId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false, field: 'couple_id' },
    creatorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false, field: 'creator_id' },
    title: { type: DataTypes.STRING(128), allowNull: false },
    category: { type: DataTypes.STRING(32), allowNull: false, defaultValue: 'daily' },
    level: { type: DataTypes.TINYINT, allowNull: false, defaultValue: 1, comment: '1高 2中 3低' },
    executorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true, field: 'executor_id' },
    scheduleId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true, field: 'schedule_id' },
    deadline: { type: DataTypes.DATE, allowNull: true },
    remindOffset: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0, field: 'remind_offset' },
    repeatType: { type: DataTypes.STRING(16), allowNull: false, defaultValue: 'none', field: 'repeat_type' },
    remark: { type: DataTypes.TEXT, allowNull: true },
    status: { type: DataTypes.TINYINT, allowNull: false, defaultValue: 0 },
    completedAt: { type: DataTypes.DATE, allowNull: true, field: 'completed_at' },
  },
  { tableName: 'todo', timestamps: true, createdAt: 'created_at', updatedAt: 'updated_at' }
);

Todo.belongsTo(User, { foreignKey: 'creatorId', as: 'creator' });
Todo.belongsTo(User, { foreignKey: 'executorId', as: 'executor' });
Todo.belongsTo(Schedule, { foreignKey: 'scheduleId', as: 'schedule' });
Todo.belongsTo(Couple, { foreignKey: 'coupleId', as: 'couple' });

module.exports = { Todo };
