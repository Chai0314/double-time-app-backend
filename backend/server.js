'use strict';
const http = require('http');
const { createApp, testConnection } = require('./src/app');
const { init: initSocket } = require('./src/sockets');
const { sequelize } = require('./src/config/database');
const config = require('./src/config');
const logger = require('./src/utils/logger');

const syncSqlite = async () => {
  // SQLite 下：Sequelize 的 alter:true 会触发外键约束失败（建 backup → 删原表）
  // 这里改成「基础 sync() + 手动清残留 backup 表 + 手动补缺失列」
  // 表结构改动时：删 SQLite 文件重建，或手动写迁移
  try {
    await sequelize.sync();
    logger.info('✅ SQLite 表结构已就绪');
  } catch (e) {
    logger.error('❌ SQLite 同步失败：' + e.message);
    return;
  }
  // 手动补齐历史 SQLite 中可能缺失的列（alter 不可用时的简易迁移）
  try {
    const qi = sequelize.getQueryInterface();
    const coupleCols = await qi.describeTable('couple');
    if (!coupleCols.creator_id) {
      await sequelize.query('ALTER TABLE `couple` ADD COLUMN `creator_id` BIGINT UNSIGNED NULL');
      logger.info('🔧 已为 couple 表补加 creator_id 列');
    }
  } catch (e) {
    logger.error('❌ couple 表迁移失败：' + e.message);
  }
  // 清理残留的 *_backup 表（Sequelize alter 留下的）
  try {
    const [rows] = await sequelize.query(
      "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE '%_backup'"
    );
    for (const r of rows) {
      await sequelize.query(`DROP TABLE IF EXISTS \`${r.name}\``);
      logger.info(`🧹 已清理残留表 ${r.name}`);
    }
  } catch (e) {
    // ignore
  }
};

const bootstrap = async () => {
  await testConnection();

  if (config.db.driver === 'sqlite') {
    await syncSqlite();
  } else if (process.env.SYNC_ON_START === 'true') {
    // MySQL 下仅当显式开启才同步
    try {
      await sequelize.sync({ alter: true });
      logger.info('✅ MySQL 表结构已同步');
    } catch (e) {
      logger.error('❌ MySQL 同步失败：' + e.message);
    }
  }

  const app = createApp();
  const server = http.createServer(app);
  initSocket(server);
  server.listen(config.port, config.host, () => {
    logger.info(`🚀 双人时光后端已启动 http://${config.host}:${config.port}`);
    logger.info(`   环境：${config.env}`);
    logger.info(`   数据库：${config.db.driver} ${config.db.driver === 'sqlite' ? config.db.storage : `${config.db.host}:${config.db.port}/${config.db.name}`}`);
    logger.info(`   静态资源：${config.upload.dir}`);
  });

  // 优雅退出
  process.on('SIGTERM', () => {
    logger.info('SIGTERM received, shutting down...');
    server.close(() => process.exit(0));
  });
};

bootstrap();
