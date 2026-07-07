'use strict';
const { Op, fn, col, literal } = require('sequelize');
const { Schedule, Media, Todo, User } = require('../models');
const { success, BizError } = require('../utils/response');

const ensureCouple = (user) => {
  if (!user.coupleId) throw new BizError('请先绑定伴侣', 400);
  return user.coupleId;
};

/**
 * GET /api/stats/overview
 * 首页概览用：
 *  - 今日行程数
 *  - 今日待办完成率
 *  - 本月共同行程数
 *  - 双人完成率
 *  - 倒计时：纪念日天数
 */
exports.overview = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const start = new Date();
  start.setHours(0, 0, 0, 0);
  const end = new Date(start.getTime() + 86400000);

  // 今日行程
  const todaySchedules = await Schedule.count({
    where: { coupleId, isArchived: 0, startTime: { [Op.between]: [start, end] } },
  });

  // 今日待办（截止时间在今日 + 今日创建）
  const todayTodoAll = await Todo.count({
    where: {
      coupleId,
      [Op.or]: [
        { deadline: { [Op.between]: [start, end] } },
        { created_at: { [Op.between]: [start, end] } },
      ],
    },
  });
  const todayTodoDone = await Todo.count({
    where: {
      coupleId,
      status: 2,
      [Op.or]: [
        { completed_at: { [Op.between]: [start, end] } },
        { deadline: { [Op.between]: [start, end] }, completed_at: null },
      ],
    },
  });

  // 本月共同行程
  const now = new Date();
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
  const monthEnd = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  const monthSchedules = await Schedule.count({
    where: { coupleId, startTime: { [Op.between]: [monthStart, monthEnd] } },
  });

  // 双人完成率（最近 30 天）
  const since = new Date(Date.now() - 30 * 86400000);
  const partners = await User.findAll({ where: { coupleId } });
  const userA = partners[0];
  const userB = partners[1];
  const completion = [];
  for (const u of partners) {
    const all = await Todo.count({ where: { coupleId, executorId: u.id, created_at: { [Op.gte]: since } } });
    const done = await Todo.count({ where: { coupleId, executorId: u.id, status: 2, created_at: { [Op.gte]: since } } });
    completion.push({
      user: { id: u.id, nickname: u.nickname, avatar: u.avatar },
      total: all, done,
      rate: all > 0 ? Math.round((done / all) * 100) : 0,
    });
  }

  // 倒计时
  let anniversaryDays = null;
  if (me.anniversary) {
    const a = new Date(me.anniversary);
    a.setHours(0, 0, 0, 0);
    const next = new Date(a);
    next.setFullYear(now.getFullYear());
    if (next < now) next.setFullYear(now.getFullYear() + 1);
    anniversaryDays = Math.ceil((next - now) / 86400000);
  }

  res.json(
    success({
      today: { schedules: todaySchedules, todoAll: todayTodoAll, todoDone: todayTodoDone },
      monthSchedules,
      completion,
      anniversaryDays,
      userA: userA && { id: userA.id, nickname: userA.nickname, avatar: userA.avatar },
      userB: userB && { id: userB.id, nickname: userB.nickname, avatar: userB.avatar },
    })
  );
};
