'use strict';
const { Message } = require('../models');
const { broadcast } = require('../sockets');

const toDTO = (m) => {
  const j = m.toJSON ? m.toJSON() : m;
  return {
    id: j.id,
    type: j.type,
    title: j.title,
    content: j.content,
    refType: j.refType,
    refId: j.refId,
    isRead: j.isRead,
    createdAt: j.createdAt,
    sender: j.sender
      ? { id: j.sender.id, nickname: j.sender.nickname, avatar: j.sender.avatar }
      : null,
  };
};

/**
 * 服务层：创建一条消息，并实时推送给 receiver
 * params: { coupleId, senderId, receiverId, type, title, content, refType?, refId? }
 */
exports.createMessage = async (params) => {
  if (!params || !params.receiverId) return null;
  const m = await Message.create({
    coupleId: params.coupleId,
    senderId: params.senderId || null,
    receiverId: params.receiverId,
    type: params.type,
    title: params.title || '',
    content: params.content || '',
    refType: params.refType || '',
    refId: params.refId || null,
  });
  await m.reload({
    include: [
      { model: require('../models').User, as: 'sender', attributes: ['id', 'nickname', 'avatar'] },
    ],
  });
  if (params.coupleId) {
    broadcast(params.coupleId, 'message_push', toDTO(m));
  }
  return m;
};

exports.toMessageDTO = toDTO;
