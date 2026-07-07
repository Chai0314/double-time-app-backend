'use strict';
/**
 * 备用初始化：当你没有 docker 时，可用此脚本让 Sequelize 直接建表
 *  - 已存在则不重建
 *  - 用法：npm run sync
 */
require('dotenv').config();
const { sequelize, testConnection } = require('../src/config/database');
const models = require('../src/models');

(async () => {
  try {
    await testConnection();
    // 引入模型确保 associations 完成
    Object.values(models).forEach((m) => {
      if (m && typeof m.associate === 'function') m.associate(models);
    });
    await sequelize.sync({ alter: true });
    console.log('✅ 表结构已同步');
    process.exit(0);
  } catch (e) {
    console.error('❌ 同步失败：', e.message);
    process.exit(1);
  }
})();
