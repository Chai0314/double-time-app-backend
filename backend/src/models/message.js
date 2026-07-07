'use strict';
const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');
const { User, Couple } = require('./user');

const Message = sequelize.define(
  'Message',
  {
    id: { type: DataTypes.BIGINT.UNSIGNED, primaryKey: true, autoIncrement: true },
    coupleId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false, field: 'couple_id' },
    senderId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true, field: 'sender_id' },
    receiverId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false, field: 'receiver_id' },
    type: { type: DataTypes.STRING(32), allowNull: false },
    title: { type: DataTypes.STRING(128), allowNull: false, defaultValue: '' },
    content: { type: DataTypes.STRING(512), allowNull: false, defaultValue: '' },
    refType: { type: DataTypes.STRING(32), allowNull: false, defaultValue: '', field: 'ref_type' },
    refId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true, field: 'ref_id' },
    isRead: { type: DataTypes.TINYINT, allowNull: false, defaultValue: 0, field: 'is_read' },
  },
  { tableName: 'message', timestamps: true, createdAt: 'created_at', updatedAt: false }
);

Message.belongsTo(User, { foreignKey: 'senderId', as: 'sender' });
Message.belongsTo(User, { foreignKey: 'receiverId', as: 'receiver' });
Message.belongsTo(Couple, { foreignKey: 'coupleId', as: 'couple' });

module.exports = { Message };
