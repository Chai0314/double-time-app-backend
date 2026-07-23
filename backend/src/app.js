'use strict';
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const path = require('path');
const config = require('./config');
const logger = require('./utils/logger');
const { fail, BizError } = require('./utils/response');
const { testConnection } = require('./config/database');

const authRouter = require('./routes/auth');
const scheduleRouter = require('./routes/schedule');
const mediaRouter = require('./routes/media');
const todoRouter = require('./routes/todo');
const statsRouter = require('./routes/stats');

const createApp = () => {
  const app = express();

  // CORS
  app.use(
    cors({
      origin: config.cors.origin === '*' ? true : config.cors.origin.split(','),
      credentials: true,
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
      exposedHeaders: ['Content-Disposition'],
    })
  );

  app.use(express.json({ limit: '5mb' }));
  app.use(express.urlencoded({ extended: true, limit: '5mb' }));
  app.use(morgan('dev'));

  // 静态资源：图片/视频
  app.use('/uploads', express.static(config.upload.dir));

  // 健康检查
  app.get('/api/health', (req, res) => res.json({ code: 0, msg: 'ok', data: { time: Date.now() } }));

  // 业务路由
  app.use('/api', authRouter);
  app.use('/api', scheduleRouter);
  app.use('/api', mediaRouter);
  app.use('/api', todoRouter);
  app.use('/api', statsRouter);

  // 404
  app.use((req, res) => res.status(404).json(fail('not found', 404)));

  // 统一错误处理
  // eslint-disable-next-line no-unused-vars
  app.use((err, req, res, next) => {
    if (err instanceof BizError) {
      return res.status(200).json(fail(err.message, err.code));
    }
    logger.error('💥 ' + (err.stack || err.message));
    res.status(500).json(fail(err.message || 'server error', 500));
  });

  return app;
};

module.exports = { createApp, testConnection };
