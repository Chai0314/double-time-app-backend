'use strict';
const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');

const User = sequelize.define(
  'User',
  {
    id: { type: DataTypes.BIGINT.UNSIGNED, primaryKey: true, autoIncrement: true },
    coupleId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true, field: 'couple_id' },
    nickname: { type: DataTypes.STRING(64), allowNull: false, defaultValue: '' },
    avatar: { type: DataTypes.STRING(255), allowNull: false, defaultValue: '' },
    account: { type: DataTypes.STRING(64), allowNull: true, unique: true },
    passwordHash: { type: DataTypes.STRING(255), allowNull: true, field: 'password_hash' },
    openid: { type: DataTypes.STRING(64), allowNull: true, unique: true },
    phone: { type: DataTypes.STRING(20), allowNull: true },
    gender: { type: DataTypes.TINYINT, allowNull: false, defaultValue: 0 },
    bio: { type: DataTypes.STRING(255), allowNull: false, defaultValue: '' },
    anniversary: { type: DataTypes.DATEONLY, allowNull: true },
    workStart: { type: DataTypes.TIME, allowNull: true, field: 'work_start' },
    workEnd: { type: DataTypes.TIME, allowNull: true, field: 'work_end' },
    status: { type: DataTypes.TINYINT, allowNull: false, defaultValue: 1 },
    lastLoginAt: { type: DataTypes.DATE, allowNull: true, field: 'last_login_at' },
  },
  { tableName: 'user', timestamps: true, createdAt: 'created_at', updatedAt: 'updated_at' }
);

const Couple = sequelize.define(
  'Couple',
  {
    id: { type: DataTypes.BIGINT.UNSIGNED, primaryKey: true, autoIncrement: true },
    inviteCode: {
      type: DataTypes.STRING(12),
      allowNull: false,
      unique: true,
      field: 'invite_code',
    },
    status: { type: DataTypes.TINYINT, allowNull: false, defaultValue: 0 },
    // 邀请码创建者：未绑定时记录是谁生成的，便于复用邀请码
    creatorId: {
      type: DataTypes.BIGINT.UNSIGNED,
      allowNull: true,
      field: 'creator_id',
    },
  },
  { tableName: 'couple', timestamps: true, createdAt: 'created_at', updatedAt: 'updated_at' }
);

User.belongsTo(Couple, { foreignKey: 'coupleId', as: 'couple' });
Couple.belongsTo(User, { foreignKey: 'creatorId', as: 'creator' });
Couple.hasMany(User, { foreignKey: 'coupleId', as: 'members' });

module.exports = { User, Couple };
