'use strict';
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { Op } = require('sequelize');
const { User, Couple } = require('../models');
const { sign } = require('../middleware/auth');
const { success, fail, BizError } = require('../utils/response');
const config = require('../config');

const genInviteCode = () =>
  crypto.randomBytes(3).toString('hex').toUpperCase().slice(0, 6);

const USER_INCLUDE = [{ model: Couple, as: 'couple' }];

const publicUser = (u) => ({
  id: u.id,
  nickname: u.nickname,
  avatar: u.avatar,
  gender: u.gender,
  bio: u.bio,
  anniversary: u.anniversary,
  account: u.account,
  phone: u.phone,
  workStart: u.workStart,
  workEnd: u.workEnd,
  coupleId: u.coupleId,
  coupleStatus: u.couple ? u.couple.status : null,
  createdAt: u.createdAt,
});

/**
 * POST /api/auth/register
 * body: { account, password, nickname, avatar? }
 */
exports.register = async (req, res) => {
  const { account, password, nickname, avatar = '' } = req.body || {};
  if (!account || !password) throw new BizError('账号和密码必填');
  if (password.length < 6) throw new BizError('密码至少 6 位');

  const exists = await User.findOne({ where: { account } });
  if (exists) throw new BizError('账号已存在');

  const passwordHash = await bcrypt.hash(password, 10);
  const user = await User.create({ account, passwordHash, nickname: nickname || account, avatar });
  await user.reload({ include: USER_INCLUDE });
  const token = sign({ id: user.id, coupleId: null });
  res.json(success({ token, user: publicUser(user) }));
};

/**
 * POST /api/auth/login
 * body: { account, password }  |  { openid }
 */
exports.login = async (req, res) => {
  const { account, password, openid } = req.body || {};
  let user;
  if (openid) {
    user = await User.findOne({ where: { openid }, include: USER_INCLUDE });
  } else {
    if (!account || !password) throw new BizError('账号和密码必填');
    user = await User.findOne({ where: { account }, include: USER_INCLUDE });
    if (!user) throw new BizError('账号或密码错误');
    const ok = await bcrypt.compare(password, user.passwordHash || '');
    if (!ok) throw new BizError('账号或密码错误');
  }
  if (!user) throw new BizError('用户不存在');
  if (user.status === 0) throw new BizError('账号已被禁用');

  await user.update({ lastLoginAt: new Date() });
  const token = sign({ id: user.id, coupleId: user.coupleId });
  res.json(success({ token, user: publicUser(user) }));
};

/**
 * POST /api/auth/wx-login
 * 简化版：App/小程序传入 wx code 即可（开发期直接传 openid 模拟）
 * body: { openid, nickname?, avatar? }
 */
exports.wxLogin = async (req, res) => {
  const { openid, nickname, avatar } = req.body || {};
  if (!openid) throw new BizError('openid 必填');
  let user = await User.findOne({ where: { openid }, include: USER_INCLUDE });
  if (!user) {
    user = await User.create({
      openid,
      nickname: nickname || `用户${openid.slice(-4)}`,
      avatar: avatar || '',
    });
    await user.reload({ include: USER_INCLUDE });
  }
  await user.update({ lastLoginAt: new Date() });
  const token = sign({ id: user.id, coupleId: user.coupleId });
  res.json(success({ token, user: publicUser(user) }));
};

/**
 * GET /api/auth/me
 */
exports.me = async (req, res) => {
  let user = await User.findByPk(req.user.id, { include: USER_INCLUDE });
  if (!user) throw new BizError('用户不存在', 404);
  // 自愈：用户是某已绑定情侣对的 creator 但 coupleId 仍为 null（历史脏数据）
  if (!user.coupleId) {
    const created = await Couple.findOne({
      where: { creatorId: user.id, status: 1 },
    });
    if (created) {
      await user.update({ coupleId: created.id });
      await user.reload({ include: USER_INCLUDE });
    }
  }
  res.json(success(publicUser(user)));
};

/**
 * PUT /api/auth/me
 * body: nickname?, avatar?, gender?, bio?, anniversary?, workStart?, workEnd?, phone?
 */
exports.updateMe = async (req, res) => {
  const allow = ['nickname', 'avatar', 'gender', 'bio', 'anniversary', 'workStart', 'workEnd', 'phone'];
  const patch = {};
  allow.forEach((k) => {
    if (req.body[k] !== undefined) patch[k] = req.body[k];
  });
  // 简单校验
  if (patch.nickname !== undefined) {
    patch.nickname = String(patch.nickname).trim();
    if (!patch.nickname) throw new BizError('昵称不能为空');
    if (patch.nickname.length > 24) throw new BizError('昵称最多 24 个字符');
  }
  if (patch.gender !== undefined) {
    const g = Number(patch.gender);
    if (![0, 1, 2].includes(g)) throw new BizError('性别参数非法');
    patch.gender = g;
  }
  if (patch.bio !== undefined && String(patch.bio).length > 200) {
    throw new BizError('个性签名最多 200 个字符');
  }
  if (patch.phone !== undefined && patch.phone) {
    if (!/^1[3-9]\d{9}$/.test(String(patch.phone))) throw new BizError('手机号格式不正确');
  }
  // 时间格式归一（HH:mm 或 HH:mm:ss 都接受）
  ['workStart', 'workEnd'].forEach((k) => {
    if (patch[k] !== undefined && patch[k] !== null && patch[k] !== '') {
      const s = String(patch[k]);
      if (!/^\d{1,2}:\d{2}(:\d{2})?$/.test(s)) throw new BizError(`${k} 时间格式应为 HH:mm`);
      patch[k] = s.length === 5 ? `${s}:00` : s;
    } else if (patch[k] === '') {
      patch[k] = null;
    }
  });

  const user = await User.findByPk(req.user.id, { include: USER_INCLUDE });
  if (!user) throw new BizError('用户不存在', 404);
  await user.update(patch);

  // 纪念日是双方共享的：任一方修改都同步到伴侣，避免两边各填一遍
  if (patch.anniversary !== undefined && user.coupleId) {
    const partner = await User.findOne({
      where: { coupleId: user.coupleId, id: { [Op.ne]: user.id } },
    });
    if (partner) {
      await partner.update({ anniversary: patch.anniversary });
    }
  }

  await user.reload({ include: USER_INCLUDE });
  res.json(success(publicUser(user)));
};

/**
 * POST /api/auth/avatar
 * multipart: file
 * 上传后直接更新当前用户的 avatar 字段
 */
exports.uploadAvatar = async (req, res) => {
  if (!req.file) throw new BizError('请选择头像图片');
  const me = await User.findByPk(req.user.id, { include: USER_INCLUDE });
  if (!me) throw new BizError('用户不存在', 404);

  // 删除旧头像（仅当是本服务器上传的相对路径）
  if (me.avatar && me.avatar.startsWith('/uploads/')) {
    const oldPath = path.join(config.upload.dir, me.avatar.replace('/uploads/', ''));
    fs.promises.unlink(oldPath).catch(() => {});
  }

  const url = `/uploads/avatars/${req.file.filename}`;
  await me.update({ avatar: url });
  await me.reload({ include: USER_INCLUDE });
  res.json(success({ avatar: url, user: publicUser(me) }));
};

/**
 * POST /api/auth/change-password
 * body: { oldPassword, newPassword }
 */
exports.changePassword = async (req, res) => {
  const { oldPassword, newPassword } = req.body || {};
  if (!oldPassword || !newPassword) throw new BizError('请填写原密码和新密码');
  if (newPassword.length < 6) throw new BizError('新密码至少 6 位');
  if (newPassword.length > 32) throw new BizError('新密码最多 32 位');

  const me = await User.findByPk(req.user.id);
  if (!me) throw new BizError('用户不存在', 404);
  if (!me.passwordHash) throw new BizError('当前账号未设置密码，无法修改');
  const ok = await bcrypt.compare(oldPassword, me.passwordHash);
  if (!ok) throw new BizError('原密码不正确');

  const newHash = await bcrypt.hash(newPassword, 10);
  await me.update({ passwordHash: newHash });
  res.json(success(null, '密码已更新'));
};

/**
 * POST /api/couple/invite
 * 生成邀请码：
 * - 优先复用本用户已创建且未绑定的情侣对（status=0）
 * - 否则新建一对，creatorId 指向当前用户
 * - 注意：生成邀请码不修改 user.coupleId，只有对方 bind 后才设置
 */
exports.createInvite = async (req, res) => {
  const user = await User.findByPk(req.user.id, { include: USER_INCLUDE });
  // 已真正绑定（status=1）则不能再生成邀请码
  if (user.coupleId && user.couple && user.couple.status === 1) {
    throw new BizError('你已绑定伴侣');
  }
  // 兼容历史脏数据：清空残留的待绑定 coupleId
  if (user.coupleId) {
    await user.update({ coupleId: null });
  }
  // 查找本用户之前是否生成过待绑定邀请码
  const pending = await Couple.findOne({
    where: { creatorId: user.id, status: 0 },
  });
  if (pending) {
    return res.json(
      success({ inviteCode: pending.inviteCode, coupleId: pending.id })
    );
  }
  // 没有则新建一对（status=0 待对方确认），不修改 user.coupleId
  const couple = await Couple.create({
    inviteCode: genInviteCode(),
    status: 0,
    creatorId: user.id,
  });
  res.json(
    success({ inviteCode: couple.inviteCode, coupleId: couple.id })
  );
};

/**
 * POST /api/couple/bind
 * body: { inviteCode }
 */
exports.bind = async (req, res) => {
  const { inviteCode } = req.body || {};
  if (!inviteCode) throw new BizError('邀请码必填');
  const me = await User.findByPk(req.user.id, { include: USER_INCLUDE });
  // 已真正绑定（status=1）才拦截
  if (me.coupleId && me.couple && me.couple.status === 1) {
    throw new BizError('你已绑定伴侣，请先解绑');
  }
  // 兼容历史脏数据：清空残留的待绑定 coupleId
  if (me.coupleId) {
    await me.update({ coupleId: null });
  }

  const couple = await Couple.findOne({
    where: { inviteCode: inviteCode.toUpperCase() },
  });
  if (!couple) throw new BizError('邀请码无效');
  // 不能绑定自己生成的邀请码
  if (couple.creatorId === me.id) {
    throw new BizError('不能绑定自己的邀请码');
  }
  const existMembers = await User.findAll({ where: { coupleId: couple.id } });
  if (existMembers.length >= 2) throw new BizError('该情侣对已满员');

  // 绑定：自己加入对方情侣对，并把对方情侣对置为已绑定
  // 同时把邀请码的创建者（creatorId）也绑定到该情侣对，
  // 否则创建者会一直处于 coupleId=null 状态，看起来像没绑定
  await me.update({ coupleId: couple.id });
  if (couple.creatorId && couple.creatorId !== me.id) {
    const creator = await User.findByPk(couple.creatorId);
    if (creator && !creator.coupleId) {
      await creator.update({ coupleId: couple.id });
    }
  }
  await couple.update({ status: 1 });
  res.json(success({ coupleId: couple.id, memberCount: existMembers.length + 1 }));
};

/**
 * POST /api/couple/unbind
 */
exports.unbind = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  if (!me.coupleId) throw new BizError('你未绑定');
  const couple = await Couple.findByPk(me.coupleId);
  // 解绑：清空本端，标记情侣对解绑
  await me.update({ coupleId: null });
  // 对方解绑由对方操作；本端只清自己
  if (couple) {
    const rest = await User.count({ where: { coupleId: couple.id } });
    if (rest === 0) await couple.update({ status: 2 });
  }
  res.json(success(null, '已解绑'));
};

/**
 * GET /api/couple/info
 * 返回情侣资料：相识天数、共同行程数、甜蜜素材数、双方昵称头像
 */
exports.coupleInfo = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  if (!me.coupleId) throw new BizError('未绑定伴侣', 400);
  const { Schedule, Media, Todo } = require('../models');
  const members = await User.findAll({ where: { coupleId: me.coupleId } });
  const couple = await Couple.findByPk(me.coupleId);
  const earliest = members
    .map((m) => m.createdAt)
    .reduce((a, b) => (a && a < b ? a : b), null);
  const dayCount = earliest
    ? Math.max(1, Math.ceil((Date.now() - new Date(earliest).getTime()) / 86400000))
    : 0;
  const scheduleCount = await Schedule.count({ where: { coupleId: me.coupleId } });
  const mediaCount = await Media.count({ where: { coupleId: me.coupleId } });
  const todoCount = await Todo.count({ where: { coupleId: me.coupleId } });

  res.json(
    success({
      coupleId: me.coupleId,
      boundAt: couple?.createdAt,
      dayCount,
      scheduleCount,
      mediaCount,
      todoCount,
      members: members.map(publicUser),
    })
  );
};

/**
 * GET /api/couple/members
 */
exports.members = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  if (!me.coupleId) throw new BizError('未绑定');
  const list = await User.findAll({ where: { coupleId: me.coupleId } });
  res.json(success(list.map(publicUser)));
};
