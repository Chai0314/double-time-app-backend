'use strict';
const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');
const { User, Couple } = require('./user');

const Schedule = sequelize.define(
  'Schedule',
  {
    id: { type: DataTypes.BIGINT.UNSIGNED, primaryKey: true, autoIncrement: true },
    coupleId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false, field: 'couple_id' },
    creatorId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false, field: 'creator_id' },
    title: { type: DataTypes.STRING(128), allowNull: false },
    category: { type: DataTypes.STRING(32), allowNull: false, defaultValue: 'other' },
    address: { type: DataTypes.STRING(255), allowNull: false, defaultValue: '' },
    longitude: { type: DataTypes.DECIMAL(10, 6), allowNull: true },
    latitude: { type: DataTypes.DECIMAL(10, 6), allowNull: true },
    startTime: { type: DataTypes.DATE, allowNull: false, field: 'start_time' },
    endTime: { type: DataTypes.DATE, allowNull: true, field: 'end_time' },
    repeatType: { type: DataTypes.STRING(16), allowNull: false, defaultValue: 'none', field: 'repeat_type' },
    repeatEnd: { type: DataTypes.DATEONLY, allowNull: true, field: 'repeat_end' },
    remindOffset: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0, field: 'remind_offset' },
    budget: { type: DataTypes.DECIMAL(10, 2), allowNull: false, defaultValue: 0 },
    actualCost: { type: DataTypes.DECIMAL(10, 2), allowNull: false, defaultValue: 0, field: 'actual_cost' },
    remark: { type: DataTypes.TEXT, allowNull: true },
    status: { type: DataTypes.TINYINT, allowNull: false, defaultValue: 0 },
    isArchived: { type: DataTypes.TINYINT, allowNull: false, defaultValue: 0, field: 'is_archived' },
  },
  { tableName: 'schedule', timestamps: true, createdAt: 'created_at', updatedAt: 'updated_at' }
);

const ScheduleMember = sequelize.define(
  'ScheduleMember',
  {
    scheduleId: { type: DataTypes.BIGINT.UNSIGNED, primaryKey: true, field: 'schedule_id' },
    userId: { type: DataTypes.BIGINT.UNSIGNED, primaryKey: true, field: 'user_id' },
  },
  { tableName: 'schedule_member', timestamps: false }
);

Schedule.belongsToMany(User, {
  through: ScheduleMember,
  foreignKey: 'scheduleId',
  otherKey: 'userId',
  as: 'members',
});
User.belongsToMany(Schedule, {
  through: ScheduleMember,
  foreignKey: 'userId',
  otherKey: 'scheduleId',
  as: 'joinedSchedules',
});
Schedule.belongsTo(User, { foreignKey: 'creatorId', as: 'creator' });
Schedule.belongsTo(Couple, { foreignKey: 'coupleId', as: 'couple' });

module.exports = { Schedule, ScheduleMember };
