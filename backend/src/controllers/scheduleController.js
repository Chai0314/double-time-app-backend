'use strict';
const { Op, fn, col, literal } = require('sequelize');
const { Schedule, ScheduleMember, User, Couple } = require('../models');
const { success, BizError } = require('../utils/response');
const { broadcast } = require('../sockets');
const { createMessage } = require('../services/messageService');

const toDTO = (s) => {
  const j = s.toJSON();
  return {
    id: j.id,
    title: j.title,
    category: j.category,
    address: j.address,
    longitude: j.longitude ? Number(j.longitude) : null,
    latitude: j.latitude ? Number(j.latitude) : null,
    startTime: j.startTime,
    endTime: j.endTime,
    repeatType: j.repeatType,
    repeatEnd: j.repeatEnd,
    remindOffset: j.remindOffset,
    budget: Number(j.budget),
    actualCost: Number(j.actualCost),
    remark: j.remark,
    status: j.status,
    isArchived: j.isArchived,
    creator: j.creator
      ? { id: j.creator.id, nickname: j.creator.nickname, avatar: j.creator.avatar }
      : null,
    members: (j.members || []).map((m) => ({
      id: m.id,
      nickname: m.nickname,
      avatar: m.avatar,
    })),
    createdAt: j.createdAt,
  };
};

const ensureCouple = (user) => {
  if (!user.coupleId) throw new BizError('请先绑定伴侣', 400);
  return user.coupleId;
};

/**
 * GET /api/schedules?view=month&year=2026&month=6
 *  GET /api/schedules?start=ISO&end=ISO
 *  GET /api/schedules?archived=1
 */
exports.list = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const { view, start, end, archived } = req.query;
  const where = { coupleId };
  if (archived === '1') where.isArchived = 1;
  else where.isArchived = 0;

  if (start && end) {
    where.startTime = { [Op.between]: [new Date(start), new Date(end)] };
  } else if (view === 'month' && req.query.year && req.query.month) {
    const y = parseInt(req.query.year, 10);
    const m = parseInt(req.query.month, 10); // 1-12
    const first = new Date(y, m - 1, 1);
    const last = new Date(y, m, 1);
    where.startTime = { [Op.between]: [first, last] };
  }

  const list = await Schedule.findAll({
    where,
    include: [
      { model: User, as: 'creator', attributes: ['id', 'nickname', 'avatar'] },
      { model: User, as: 'members', attributes: ['id', 'nickname', 'avatar'] },
    ],
    order: [['start_time', 'ASC']],
  });
  res.json(success(list.map(toDTO)));
};

/**
 * GET /api/schedules/today
 */
exports.today = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const end = new Date(start.getTime() + 86400000);
  const list = await Schedule.findAll({
    where: { coupleId, isArchived: 0, startTime: { [Op.between]: [start, end] } },
    include: [
      { model: User, as: 'creator', attributes: ['id', 'nickname', 'avatar'] },
      { model: User, as: 'members', attributes: ['id', 'nickname', 'avatar'] },
    ],
    order: [['start_time', 'ASC']],
  });
  res.json(success(list.map(toDTO)));
};

/**
 * GET /api/schedules/:id
 */
exports.detail = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const s = await Schedule.findOne({
    where: { id: req.params.id, coupleId },
    include: [
      { model: User, as: 'creator', attributes: ['id', 'nickname', 'avatar'] },
      { model: User, as: 'members', attributes: ['id', 'nickname', 'avatar'] },
    ],
  });
  if (!s) throw new BizError('行程不存在', 404);
  res.json(success(toDTO(s)));
};

/**
 * POST /api/schedules
 */
exports.create = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const b = req.body || {};
  if (!b.title) throw new BizError('标题必填');
  if (!b.startTime) throw new BizError('开始时间必填');

  const s = await Schedule.create({
    coupleId,
    creatorId: me.id,
    title: b.title,
    category: b.category || 'other',
    address: b.address || '',
    longitude: b.longitude || null,
    latitude: b.latitude || null,
    startTime: new Date(b.startTime),
    endTime: b.endTime ? new Date(b.endTime) : null,
    repeatType: b.repeatType || 'none',
    repeatEnd: b.repeatEnd || null,
    remindOffset: b.remindOffset || 0,
    budget: b.budget || 0,
    actualCost: b.actualCost || 0,
    remark: b.remark || '',
    status: 0,
  });

  // 参与人：默认双人
  let memberIds = Array.isArray(b.memberIds) && b.memberIds.length > 0 ? b.memberIds : null;
  if (!memberIds) {
    const members = await User.findAll({ where: { coupleId } });
    memberIds = members.map((m) => m.id);
  }
  await ScheduleMember.bulkCreate(memberIds.map((uid) => ({ scheduleId: s.id, userId: uid })));
  await s.reload({ include: [{ model: User, as: 'members' }, { model: User, as: 'creator' }] });

  // 通知伴侣
  await createMessage({
    coupleId,
    senderId: me.id,
    receiverId: memberIds.find((id) => id !== me.id),
    type: 'schedule',
    title: '新增行程',
    content: `${me.nickname} 新建了行程：${s.title}`,
    refType: 'schedule',
    refId: s.id,
  });

  broadcast(coupleId, 'schedule_update', { action: 'create', data: toDTO(s) });
  res.json(success(toDTO(s)));
};

/**
 * PUT /api/schedules/:id
 */
exports.update = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const s = await Schedule.findOne({ where: { id: req.params.id, coupleId } });
  if (!s) throw new BizError('行程不存在', 404);

  const allow = [
    'title', 'category', 'address', 'longitude', 'latitude',
    'startTime', 'endTime', 'repeatType', 'repeatEnd', 'remindOffset',
    'budget', 'actualCost', 'remark', 'status', 'isArchived',
  ];
  const patch = {};
  allow.forEach((k) => {
    if (req.body[k] !== undefined) patch[k] = req.body[k];
  });
  if (patch.startTime) patch.startTime = new Date(patch.startTime);
  if (patch.endTime) patch.endTime = new Date(patch.endTime);
  await s.update(patch);

  if (Array.isArray(req.body.memberIds)) {
    await ScheduleMember.destroy({ where: { scheduleId: s.id } });
    await ScheduleMember.bulkCreate(
      req.body.memberIds.map((uid) => ({ scheduleId: s.id, userId: uid }))
    );
  }
  await s.reload({ include: [{ model: User, as: 'members' }, { model: User, as: 'creator' }] });

  broadcast(coupleId, 'schedule_update', { action: 'update', data: toDTO(s) });
  res.json(success(toDTO(s)));
};

/**
 * DELETE /api/schedules/:id
 */
exports.remove = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const s = await Schedule.findOne({ where: { id: req.params.id, coupleId } });
  if (!s) throw new BizError('行程不存在', 404);
  await ScheduleMember.destroy({ where: { scheduleId: s.id } });
  await s.destroy();
  broadcast(coupleId, 'schedule_update', { action: 'delete', id: Number(req.params.id) });
  res.json(success(null, '已删除'));
};

/**
 * GET /api/schedules/calendar?year=2026&month=6
 * 返回当月每一天是否有行程的标记（用于月视图）
 * 用 JS 分组保证跨数据库兼容（MySQL/SQLite）
 */
exports.calendar = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const y = parseInt(req.query.year, 10);
  const m = parseInt(req.query.month, 10);
  const first = new Date(y, m - 1, 1);
  const last = new Date(y, m, 1);
  const list = await Schedule.findAll({
    where: { coupleId, isArchived: 0, startTime: { [Op.between]: [first, last] } },
    attributes: ['startTime'],
  });
  const map = {};
  list.forEach((s) => {
    const d = new Date(s.startTime);
    const k = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    map[k] = (map[k] || 0) + 1;
  });
  res.json(
    success(
      Object.entries(map).map(([date, count]) => ({
        date: `${date} 00:00:00`,
        count,
      }))
    )
  );
};
