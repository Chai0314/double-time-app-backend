'use strict';
require('dotenv').config();

const path = require('path');

const config = {
  env: process.env.NODE_ENV || 'development',
  port: parseInt(process.env.PORT, 10) || 3000,
  host: process.env.HOST || '0.0.0.0',

  // 数据库驱动：mysql | sqlite
  // 没设 DB_HOST 时自动用 sqlite
  db: {
    driver: process.env.DB_DRIVER || (process.env.DB_HOST ? 'mysql' : 'sqlite'),
    host: process.env.DB_HOST || '127.0.0.1',
    port: parseInt(process.env.DB_PORT, 10) || 3306,
    name: process.env.DB_NAME || 'couple_space',
    user: process.env.DB_USER || 'couple',
    password: process.env.DB_PASSWORD || 'couple_pwd',
    storage: process.env.DB_STORAGE || path.resolve(__dirname, '../../', 'data/couple_space.sqlite'),
  },

  jwt: {
    secret: process.env.JWT_SECRET || 'couple_space_jwt_secret_change_me',
    expiresIn: process.env.JWT_EXPIRES_IN || '30d',
  },

  upload: {
    dir: path.resolve(__dirname, '../../', process.env.UPLOAD_DIR || 'uploads'),
    maxMB: parseInt(process.env.MAX_UPLOAD_MB, 10) || 50,
  },

  cors: {
    origin: process.env.CORS_ORIGIN || '*',
  },
};

module.exports = config;
