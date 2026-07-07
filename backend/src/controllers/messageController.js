'use strict';
const { Message, User } = require('../models');
const { success, BizError } = require('../utils/response');
const messageService = require('../services/messageService');

const toDTO = messageService.toMessageDTO;

/**
 * GET /api/messages?unread=1
 */
exports.list = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  if (!me.coupleId) throw new BizError('未绑定');
  const where = { receiverId: me.id };
  if (req.query.unread === '1') where.isRead = 0;
  const list = await Message.findAll({
    where,
    include: [{ model: User, as: 'sender', attributes: ['id', 'nickname', 'avatar'] }],
    order: [['created_at', 'DESC']],
    limit: 100,
  });
  res.json(success(list.map(toDTO)));
};

/**
 * GET /api/messages/unread-count
 */
exports.unreadCount = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const count = await Message.count({ where: { receiverId: me.id, isRead: 0 } });
  res.json(success({ count }));
};

/**
 * PUT /api/messages/read-all
 */
exports.readAll = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  await Message.update({ isRead: 1 }, { where: { receiverId: me.id, isRead: 0 } });
  res.json(success(null, '已全部已读'));
};

/**
 * PUT /api/messages/:id/read
 */
exports.read = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const m = await Message.findOne({ where: { id: req.params.id, receiverId: me.id } });
  if (!m) throw new BizError('消息不存在', 404);
  await m.update({ isRead: 1 });
  res.json(success(null, 'ok'));
};
