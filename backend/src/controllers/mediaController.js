'use strict';
const path = require('path');
const { Op } = require('sequelize');
const { Media, User, Schedule, Couple } = require('../models');
const { success, BizError } = require('../utils/response');
const { broadcast } = require('../sockets');
const { createMessage } = require('../services/messageService');
const { generateVideoThumb } = require('../utils/thumbnail');
const config = require('../config');
const logger = require('../utils/logger');

const toDTO = (m) => {
  const j = m.toJSON();
  // 注意：Media 模型在定义时把 createdAt/updatedAt 写成了字符串
  // 'created_at'/'updated_at'，所以 toJSON() 出来的键是 created_at / updated_at
  return {
    id: j.id,
    coupleId: j.coupleId,
    scheduleId: j.scheduleId,
    uploaderId: j.uploaderId,
    mediaType: j.mediaType,
    url: j.url,
    thumbUrl: j.thumbUrl,
    duration: j.duration,
    width: j.width,
    height: j.height,
    size: j.size,
    remark: j.remark,
    isStar: j.isStar,
    takenAt: j.takenAt,
    createdAt: j.created_at,
    updatedAt: j.updated_at,
    uploader: j.uploader
      ? { id: j.uploader.id, nickname: j.uploader.nickname, avatar: j.uploader.avatar }
      : null,
    schedule: j.schedule ? { id: j.schedule.id, title: j.schedule.title } : null,
  };
};

const ensureCouple = (user) => {
  if (!user.coupleId) throw new BizError('请先绑定伴侣', 400);
  return user.coupleId;
};

/**
 * GET /api/media?type=&star=&scheduleId=
 *   - type   all|image|video|star
 *       all   全部
 *       image 仅图片
 *       video 仅视频
 *       star  收藏（不区分图/视频，is_star=1）
 *   - star=1 强制只看收藏（与 type=star 等价，保留兼容）
 *   - scheduleId 过滤行程
 */
exports.list = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const where = { coupleId };
  if (req.query.scheduleId) where.scheduleId = req.query.scheduleId;

  const type = (req.query.type || 'all').toString().toLowerCase();
  if (type === 'image') where.mediaType = 'image';
  else if (type === 'video') where.mediaType = 'video';
  else if (type === 'star' || req.query.star === '1') where.isStar = 1;

  const list = await Media.findAll({
    where,
    include: [
      { model: User, as: 'uploader', attributes: ['id', 'nickname', 'avatar'] },
      { model: Schedule, as: 'schedule', attributes: ['id', 'title', 'startTime'] },
    ],
    order: [['is_star', 'DESC'], ['created_at', 'DESC']],
  });
  res.json(success(list.map(toDTO)));
};

/**
 * POST /api/media  (单文件 / 多个)
 *  - 字段：file、scheduleId?、remark?、takenAt?
 */
// 把表单字段安全转 int（允许 undefined → 0）
const toInt = (v) => {
  if (v === undefined || v === null || v === '') return 0;
  const n = parseInt(v, 10);
  return Number.isFinite(n) && n >= 0 ? n : 0;
};

exports.create = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  if (!req.file) throw new BizError('请上传文件');
  const {
    scheduleId,
    remark = '',
    takenAt = null,
    duration,
    width,
    height,
  } = req.body || {};

  // 验证行程归属
  if (scheduleId) {
    const s = await Schedule.findOne({ where: { id: scheduleId, coupleId } });
    if (!s) throw new BizError('行程不存在', 404);
  }

  const type = req.file.mimetype.startsWith('video/') ? 'video' : 'image';
  // URL：相对路径，前端拼 host
  const url = `/uploads/${type === 'video' ? 'videos' : 'images'}/${req.file.filename}`;

  // 视频：生成首帧缩略图（失败时回落为 url）
  let thumbUrl = url;
  if (type === 'video') {
    const absPath = path.join(config.upload.dir, 'videos', req.file.filename);
    const r = await generateVideoThumb(absPath);
    if (r) thumbUrl = r.thumbUrl;
  }

  const media = await Media.create({
    coupleId,
    scheduleId: scheduleId ? Number(scheduleId) : null,
    uploaderId: me.id,
    mediaType: type,
    url,
    thumbUrl,
    duration: toInt(duration),
    width: toInt(width),
    height: toInt(height),
    size: req.file.size,
    remark,
    takenAt: takenAt ? new Date(takenAt) : null,
  });
  await media.reload({
    include: [
      { model: User, as: 'uploader', attributes: ['id', 'nickname', 'avatar'] },
      { model: Schedule, as: 'schedule', attributes: ['id', 'title'] },
    ],
  });
  await notifyPartner(me, coupleId, type, media);
  res.json(success(toDTO(media)));
};

/**
 * POST /api/media/batch  (多文件，图片+视频混合)
 *  - 字段：files(多)、scheduleId?、remark?、takenAt?
 *  - 上传成功返回数组
 */
exports.createBatch = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const files = req.files || [];
  if (files.length === 0) throw new BizError('请上传文件');
  const {
    scheduleId,
    remark = '',
    takenAt = null,
    metadata = null,
  } = req.body || {};

  // 验证行程归属
  if (scheduleId) {
    const s = await Schedule.findOne({ where: { id: scheduleId, coupleId } });
    if (!s) throw new BizError('行程不存在', 404);
  }

  // 解析前端传的每文件元数据（JSON 字符串）
  // 形如：'[{"duration":5000,"width":1920,"height":1080}, ...]'
  let metaList = [];
  if (metadata) {
    try {
      const parsed = typeof metadata === 'string' ? JSON.parse(metadata) : metadata;
      if (Array.isArray(parsed)) metaList = parsed;
    } catch (_) {
      // 解析失败时忽略，按 0 处理
    }
  }

  // 逐个建记录；任意失败回滚
  const created = [];
  try {
    for (let i = 0; i < files.length; i++) {
      const f = files[i];
      const meta = metaList[i] || {};
      const type = f.mimetype.startsWith('video/') ? 'video' : 'image';
      const url = `/uploads/${type === 'video' ? 'videos' : 'images'}/${f.filename}`;
      const m = await Media.create({
        coupleId,
        scheduleId: scheduleId ? Number(scheduleId) : null,
        uploaderId: me.id,
        mediaType: type,
        url,
        thumbUrl: url, // 先占位，视频稍后生成完再 update
        duration: toInt(meta.duration),
        width: toInt(meta.width),
        height: toInt(meta.height),
        size: f.size,
        remark,
        takenAt: takenAt ? new Date(takenAt) : null,
      });
      created.push(m);
    }
  } catch (e) {
    // 回滚已创建的
    for (const m of created) await m.destroy().catch(() => {});
    throw e;
  }

  // 视频：并行生成首帧缩略图，成功后回写 thumbUrl
  await Promise.all(
    created.map(async (m) => {
      if (m.mediaType !== 'video') return;
      const f = files.find((x) => x.filename === path.basename(m.url));
      if (!f) return;
      const absPath = f.path;
      const r = await generateVideoThumb(absPath);
      if (r) await m.update({ thumbUrl: r.thumbUrl });
    })
  );

  // 给首条素材发伴侣通知 + 广播
  const firstType = created[0].mediaType;
  try {
    await notifyPartner(me, coupleId, firstType, created[0]);
    for (const m of created) {
      await m.reload({
        include: [
          { model: User, as: 'uploader', attributes: ['id', 'nickname', 'avatar'] },
          { model: Schedule, as: 'schedule', attributes: ['id', 'title'] },
        ],
      });
      broadcast(coupleId, 'media_update', { action: 'create', data: toDTO(m) });
    }
  } catch (e) {
    // 忽略通知失败
    logger.warn('notifyPartner failed:', e);
  }
  res.json(success(created.map(toDTO)));
};

const notifyPartner = async (me, coupleId, type, media) => {
  const partner = await User.findOne({ where: { coupleId, id: { [Op.ne]: me.id } } });
  if (partner) {
    await createMessage({
      coupleId,
      senderId: me.id,
      receiverId: partner.id,
      type: 'media',
      title: '新素材',
      content: `${me.nickname} 上传了${type === 'video' ? '一段视频' : '一张图片'}`,
      refType: 'media',
      refId: media.id,
    });
  }
  broadcast(coupleId, 'media_update', { action: 'create', data: toDTO(media) });
};

/**
 * PUT /api/media/:id  (改 remark / isStar)
 */
exports.update = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const m = await Media.findOne({ where: { id: req.params.id, coupleId } });
  if (!m) throw new BizError('素材不存在', 404);
  const patch = {};
  ['remark', 'isStar', 'scheduleId'].forEach((k) => {
    if (req.body[k] !== undefined) patch[k] = req.body[k];
  });
  await m.update(patch);
  await m.reload({
    include: [
      { model: User, as: 'uploader', attributes: ['id', 'nickname', 'avatar'] },
      { model: Schedule, as: 'schedule', attributes: ['id', 'title'] },
    ],
  });
  broadcast(coupleId, 'media_update', { action: 'update', data: toDTO(m) });
  res.json(success(toDTO(m)));
};

/**
 * DELETE /api/media/:id
 */
exports.remove = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const m = await Media.findOne({ where: { id: req.params.id, coupleId } });
  if (!m) throw new BizError('素材不存在', 404);
  await m.destroy();
  // TODO: 实际项目中删除物理文件（fs.unlink）
  broadcast(coupleId, 'media_update', { action: 'delete', id: Number(req.params.id) });
  res.json(success(null, '已删除'));
};

/**
 * GET /api/media/group-by-schedule?type=all|image|video|star
 *  按行程分组返回素材（首页相册用）
 *  - type=star 仅返回收藏的
 *  - type=image/video 仅返回对应类型
 */
exports.groupBySchedule = async (req, res) => {
  const me = await User.findByPk(req.user.id);
  const coupleId = ensureCouple(me);
  const where = { coupleId };

  const type = (req.query.type || 'all').toString().toLowerCase();
  if (type === 'image') where.mediaType = 'image';
  else if (type === 'video') where.mediaType = 'video';
  else if (type === 'star') where.isStar = 1;

  const list = await Media.findAll({
    where,
    include: [
      { model: User, as: 'uploader', attributes: ['id', 'nickname', 'avatar'] },
      { model: Schedule, as: 'schedule', attributes: ['id', 'title', 'startTime'] },
    ],
    order: [['is_star', 'DESC'], ['created_at', 'DESC']],
  });
  const groups = {};
  list.forEach((m) => {
    const key = m.scheduleId || 0;
    if (!groups[key]) {
      groups[key] = {
        scheduleId: m.scheduleId,
        scheduleTitle: m.schedule ? m.schedule.title : '未分类',
        scheduleDate: m.schedule ? m.schedule.startTime : null,
        items: [],
      };
    }
    groups[key].items.push(toDTO(m));
  });
  res.json(success(Object.values(groups)));
};
