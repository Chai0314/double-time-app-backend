'use strict';
const { Op, fn, col, literal } = require('sequelize');
const { Todo, User, Schedule } = require('../models');
const { success, BizError } = require('../utils/response');
const { broadcast } = require('../sockets');
const { createMessage } = require('../services/messageService');

const LEVEL_ORDER = { 1: 0, 2: 1, 3: 2 };
const STATUS_TEXT = { 0: '待处理', 1: '进行中', 2: '已完成', 3: '逾期', 4: '作废' };

const toDTO = (t) => {
  const j = t.toJSON();
  const isOverdue =
    j.status !== 2 &&
    j.status !== 4 &&
    j.deadline &&
    new Date(j.deadline).getTime() < Date.now();
  return {
    id: j.id,
    title: j.title,
    category: j.category,
    level: j.level,
    levelText: ['高', '中', '低'][j.level - 1] || '中',
    executor: j.executor
      ? { id: j.executor.id, nickname: j.executor.nickname, avatar: j.executor.avatar }
      : null,
    schedule: j.schedule ? { id: j.schedule.id, title: j.schedule.title } : null,
    deadline: j.deadline,
    remindOffset: j.remindOffset,
    repeatType: j.repeatType,
    remark: j.remark,
    status: j.status,
    statusText: STATUS_TEXT[isOverdue ? 3 : j.status] || '待处理',
    isOverdue,
    completedAt: j.completedAt,
    creator: j.creator
      ? { id: j.creator.id, nickname: j.creator.nickname, avatar: j.creator.avatar }
      : null,
    createdAt: j.createdAt,
  };
};

const ensureCouple = (user) => {
  if (!user.coupleId) throw new BizError('请先绑定伴侣', 400);
  return user.coupleId;
};

/**
 * GET /api/todos?filter=mine|partner|all|overdue
 * 默认按优先级 + 是否逾期 + deadline 排序
 */
exports.list = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const where = { coupleId };
  const filter = req.query.filter || 'all';
  if (filter === 'mine') where.executorId = me.id;
  else if (filter === 'partner')
    where.executorId = { [Op.ne]: me.id };
  if (req.query.status !== undefined) where.status = Number(req.query.status);

  const list = await Todo.findAll({
    where,
    include: [
      { model: User, as: 'executor', attributes: ['id', 'nickname', 'avatar'] },
      { model: User, as: 'creator', attributes: ['id', 'nickname', 'avatar'] },
      { model: Schedule, as: 'schedule', attributes: ['id', 'title'] },
    ],
  });
  const dtos = list.map(toDTO);
  // 排序：逾期 > 优先级(1最高) > deadline
  dtos.sort((a, b) => {
    if (a.isOverdue !== b.isOverdue) return a.isOverdue ? -1 : 1;
    if (a.level !== b.level) return LEVEL_ORDER[a.level] - LEVEL_ORDER[b.level];
    if (a.deadline && b.deadline)
      return new Date(a.deadline) - new Date(b.deadline);
    return 0;
  });
  res.json(success(dtos));
};

/**
 * GET /api/todos/:id
 */
exports.detail = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const t = await Todo.findOne({
    where: { id: req.params.id, coupleId },
    include: [
      { model: User, as: 'executor' },
      { model: User, as: 'creator' },
      { model: Schedule, as: 'schedule' },
    ],
  });
  if (!t) throw new BizError('任务不存在', 404);
  res.json(success(toDTO(t)));
};

/**
 * POST /api/todos
 */
exports.create = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const b = req.body || {};
  if (!b.title) throw new BizError('标题必填');
  if (!b.deadline) throw new BizError('截止时间必填');

  const t = await Todo.create({
    coupleId,
    creatorId: me.id,
    title: b.title,
    category: b.category || 'daily',
    level: b.level || 1,
    executorId: b.executorId || null,
    scheduleId: b.scheduleId || null,
    deadline: new Date(b.deadline),
    remindOffset: b.remindOffset || 0,
    repeatType: b.repeatType || 'none',
    remark: b.remark || '',
    status: 0,
  });
  await t.reload({
    include: [
      { model: User, as: 'executor' },
      { model: User, as: 'creator' },
      { model: Schedule, as: 'schedule' },
    ],
  });
  // 通知执行人
  if (t.executorId && t.executorId !== me.id) {
    await createMessage({
      coupleId,
      senderId: me.id,
      receiverId: t.executorId,
      type: 'todo',
      title: '新待办',
      content: `${me.nickname} 指派了一个待办：${t.title}`,
      refType: 'todo',
      refId: t.id,
    });
  }
  broadcast(coupleId, 'todo_update', { action: 'create', data: toDTO(t) });
  res.json(success(toDTO(t)));
};

/**
 * PUT /api/todos/:id
 */
exports.update = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const t = await Todo.findOne({ where: { id: req.params.id, coupleId } });
  if (!t) throw new BizError('任务不存在', 404);
  const allow = [
    'title', 'category', 'level', 'executorId', 'scheduleId',
    'deadline', 'remindOffset', 'repeatType', 'remark', 'status',
  ];
  const patch = {};
  allow.forEach((k) => {
    if (req.body[k] !== undefined) patch[k] = req.body[k];
  });
  if (patch.deadline) patch.deadline = new Date(patch.deadline);
  if (patch.status === 2 && !t.completedAt) patch.completedAt = new Date();
  await t.update(patch);
  await t.reload({
    include: [
      { model: User, as: 'executor' },
      { model: User, as: 'creator' },
      { model: Schedule, as: 'schedule' },
    ],
  });
  broadcast(coupleId, 'todo_update', { action: 'update', data: toDTO(t) });
  res.json(success(toDTO(t)));
};

/**
 * DELETE /api/todos/:id
 */
exports.remove = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const t = await Todo.findOne({ where: { id: req.params.id, coupleId } });
  if (!t) throw new BizError('任务不存在', 404);
  await t.destroy();
  broadcast(coupleId, 'todo_update', { action: 'delete', id: Number(req.params.id) });
  res.json(success(null, '已删除'));
};

/**
 * GET /api/todos/stats
 *  今日总数 / 已完成 / 未完成 / 逾期 / 完成率
 *  双方分工：分别统计
 *  优先级：7/30 天高/中/低完成情况
 */
exports.stats = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);

  const start = new Date();
  start.setHours(0, 0, 0, 0);
  const end = new Date(start.getTime() + 86400000);

  // 今日
  const todayAll = await Todo.count({ where: { coupleId, created_at: { [Op.between]: [start, end] } } });
  const todayDone = await Todo.count({
    where: { coupleId, status: 2, completed_at: { [Op.between]: [start, end] } },
  });
  const todayOverdue = await Todo.count({
    where: { coupleId, status: { [Op.ne]: 2 }, deadline: { [Op.lt]: new Date() } },
  });

  // 双方分工（近 30 天）
  const since = new Date(Date.now() - 30 * 86400000);
  const partners = await User.findAll({ where: { coupleId } });
  const division = [];
  for (const p of partners) {
    const all = await Todo.count({
      where: { coupleId, executorId: p.id, created_at: { [Op.gte]: since } },
    });
    const done = await Todo.count({
      where: { coupleId, executorId: p.id, status: 2, created_at: { [Op.gte]: since } },
    });
    const overdue = await Todo.count({
      where: {
        coupleId, executorId: p.id, status: { [Op.ne]: 2 },
        deadline: { [Op.lt]: new Date() }, created_at: { [Op.gte]: since },
      },
    });
    division.push({
      user: { id: p.id, nickname: p.nickname, avatar: p.avatar },
      total: all, done, overdue,
      completionRate: all > 0 ? Math.round((done / all) * 100) : 0,
    });
  }

  // 优先级分布（近 30 天）
  const levelStats = [1, 2, 3].map((lv) => ({
    level: lv,
    levelText: ['高', '中', '低'][lv - 1],
    total: 0, done: 0,
  }));
  const rows = await Todo.findAll({
    where: { coupleId, created_at: { [Op.gte]: since } },
    attributes: ['level', 'status'],
  });
  rows.forEach((r) => {
    const s = levelStats.find((x) => x.level === r.level);
    if (s) {
      s.total++;
      if (r.status === 2) s.done++;
    }
  });

  res.json(
    success({
      today: { total: todayAll, done: todayDone, overdue: todayOverdue },
      completionRate:
        todayAll > 0 ? Math.round((todayDone / todayAll) * 100) : 0,
      division,
      levelStats,
    })
  );
};
