'use strict';
const { DataTypes } = require('sequelize');
const { sequelize } = require('../config/database');
const { User, Couple } = require('./user');
const { Schedule } = require('./schedule');

const Media = sequelize.define(
  'Media',
  {
    id: { type: DataTypes.BIGINT.UNSIGNED, primaryKey: true, autoIncrement: true },
    coupleId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false, field: 'couple_id' },
    scheduleId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: true, field: 'schedule_id' },
    uploaderId: { type: DataTypes.BIGINT.UNSIGNED, allowNull: false, field: 'uploader_id' },
    mediaType: { type: DataTypes.STRING(16), allowNull: false, defaultValue: 'image', field: 'media_type' },
    url: { type: DataTypes.STRING(255), allowNull: false },
    thumbUrl: { type: DataTypes.STRING(255), allowNull: false, defaultValue: '', field: 'thumb_url' },
    duration: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
    width: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
    height: { type: DataTypes.INTEGER, allowNull: false, defaultValue: 0 },
    size: { type: DataTypes.BIGINT, allowNull: false, defaultValue: 0 },
    remark: { type: DataTypes.STRING(255), allowNull: false, defaultValue: '' },
    isStar: { type: DataTypes.TINYINT, allowNull: false, defaultValue: 0, field: 'is_star' },
    takenAt: { type: DataTypes.DATE, allowNull: true, field: 'taken_at' },
  },
  { tableName: 'media', timestamps: true, createdAt: 'created_at', updatedAt: 'updated_at' }
);

Media.belongsTo(Couple, { foreignKey: 'coupleId', as: 'couple' });
Media.belongsTo(Schedule, { foreignKey: 'scheduleId', as: 'schedule' });
Media.belongsTo(User, { foreignKey: 'uploaderId', as: 'uploader' });

module.exports = { Media };
