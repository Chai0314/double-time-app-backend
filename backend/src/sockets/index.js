'use strict';
const { Server } = require('socket.io');
const { verify } = require('../middleware/auth');
const logger = require('../utils/logger');

let io = null;
const userSockets = new Map(); // userId -> Set<socketId>

/**
 * 初始化 Socket.io
 *  客户端连接时通过 auth.token 鉴权
 *  每个 socket 加入以 userId 和 coupleId 命名的房间
 */
exports.init = (httpServer) => {
  io = new Server(httpServer, {
    cors: { origin: '*', methods: ['GET', 'POST'] },
  });

  // 中间件：校验 token
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.query?.token;
    if (!token) return next(new Error('未授权'));
    try {
      const payload = verify(token);
      socket.userId = payload.id;
      socket.coupleId = payload.coupleId;
      next();
    } catch (e) {
      next(new Error('token 失效'));
    }
  });

  io.on('connection', (socket) => {
    logger.info(`🟢 socket connected: userId=${socket.userId} coupleId=${socket.coupleId}`);

    // 用户与 socket 映射
    if (!userSockets.has(socket.userId)) userSockets.set(socket.userId, new Set());
    userSockets.get(socket.userId).add(socket.id);

    // 加入自己 + 情侣房间
    socket.join(`user:${socket.userId}`);
    if (socket.coupleId) socket.join(`couple:${socket.coupleId}`);

    // 客户端可主动更新 coupleId（绑定后）
    socket.on('bind_couple', (coupleId) => {
      if (coupleId) {
        socket.coupleId = coupleId;
        socket.join(`couple:${coupleId}`);
      }
    });

    socket.on('disconnect', () => {
      const set = userSockets.get(socket.userId);
      if (set) {
        set.delete(socket.id);
        if (set.size === 0) userSockets.delete(socket.userId);
      }
      logger.info(`🔴 socket disconnected: userId=${socket.userId}`);
    });
  });

  return io;
};

/**
 * 推送给指定情侣对（双端实时同步）
 *  业务层调用：broadcast(coupleId, 'schedule_update', payload)
 */
exports.broadcast = (coupleId, event, payload) => {
  if (!io || !coupleId) return;
  io.to(`couple:${coupleId}`).emit(event, payload);
};

/**
 * 推送给指定用户
 */
exports.emitToUser = (userId, event, payload) => {
  if (!io) return;
  io.to(`user:${userId}`).emit(event, payload);
};

exports.getIO = () => io;
