'use strict';
const fs = require('fs');
const path = require('path');
const { Sequelize } = require('sequelize');
const config = require('./index');
const logger = require('../utils/logger');

// 确保上传目录存在
if (!fs.existsSync(config.upload.dir)) {
  fs.mkdirSync(config.upload.dir, { recursive: true });
}
['images', 'videos', 'avatars'].forEach((sub) => {
  const p = path.join(config.upload.dir, sub);
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
});

// SQLite 目录
if (config.db.driver === 'sqlite') {
  const dir = path.dirname(config.db.storage);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

let sequelize;
if (config.db.driver === 'sqlite') {
  sequelize = new Sequelize({
    dialect: 'sqlite',
    storage: config.db.storage,
    logging: config.env === 'development' ? (sql) => logger.debug(sql) : false,
    define: {
      underscored: true,
      freezeTableName: false,
    },
  });
} else {
  sequelize = new Sequelize(config.db.name, config.db.user, config.db.password, {
    host: config.db.host,
    port: config.db.port,
    dialect: 'mysql',
    timezone: '+08:00',
    logging: config.env === 'development' ? (sql) => logger.debug(sql) : false,
    define: {
      underscored: true,
      freezeTableName: false,
    },
    pool: {
      max: 10,
      min: 0,
      acquire: 30000,
      idle: 10000,
    },
  });
}

const testConnection = async () => {
  try {
    await sequelize.authenticate();
    logger.info(`✅ 数据库连接成功 [${config.db.driver}]`);
  } catch (e) {
    logger.error('❌ 数据库连接失败：' + e.message);
    if (config.db.driver === 'mysql') {
      logger.error('请检查 docker compose ps / .env 配置');
    } else {
      logger.error('SQLite 文件路径：' + config.db.storage);
    }
  }
};

module.exports = { sequelize, testConnection };
