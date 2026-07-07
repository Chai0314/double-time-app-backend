'use strict';
const jwt = require('jsonwebtoken');
const config = require('../config');
const { fail, BizError } = require('../utils/response');

/**
 * 签发 token
 */
const sign = (payload) =>
  jwt.sign(payload, config.jwt.secret, { expiresIn: config.jwt.expiresIn });

/**
 * 校验 token
 */
const verify = (token) => jwt.verify(token, config.jwt.secret);

/**
 * 鉴权中间件
 */
const authMiddleware = (req, res, next) => {
  const auth = req.headers['authorization'] || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) return res.status(401).json(fail('未登录', 401));
  try {
    const decoded = verify(token);
    req.user = decoded; // { id, coupleId }
    next();
  } catch (e) {
    return res.status(401).json(fail('token 失效', 401));
  }
};

module.exports = { sign, verify, authMiddleware, BizError };
