'use strict';
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const config = require('../config');
const { fail } = require('../utils/response');

// 通用：按类型分子目录
const storage = (sub) =>
  multer.diskStorage({
    destination: (req, file, cb) => {
      const dir = path.join(config.upload.dir, sub);
      if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
      cb(null, dir);
    },
    filename: (req, file, cb) => {
      // 时间戳 + 随机数 + 原扩展名
      const ext = path.extname(file.originalname) || '';
      const name = `${Date.now()}_${Math.random().toString(36).slice(2, 8)}${ext}`;
      cb(null, name);
    },
  });

const imageFilter = (req, file, cb) => {
  if (!/^image\//.test(file.mimetype)) return cb(new Error('仅支持图片'));
  cb(null, true);
};
const videoFilter = (req, file, cb) => {
  if (!/^video\//.test(file.mimetype)) return cb(new Error('仅支持视频'));
  cb(null, true);
};

const imageUploader = multer({
  storage: storage('images'),
  fileFilter: imageFilter,
  limits: { fileSize: config.upload.maxMB * 1024 * 1024 },
});
const videoUploader = multer({
  storage: storage('videos'),
  fileFilter: videoFilter,
  limits: { fileSize: config.upload.maxMB * 1024 * 1024 },
});
// 头像：单独存到 avatars 子目录，便于清理
const avatarUploader = multer({
  storage: storage('avatars'),
  fileFilter: imageFilter,
  limits: { fileSize: 2 * 1024 * 1024 }, // 头像限制 2MB
});

// 批量上传：图片 + 视频混合（用 fileFilter 区分存到不同子目录）
// 注意：multer.array 的 fieldName 与上传端约定为 'files'
const mixedStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const sub = file.mimetype.startsWith('video/') ? 'videos' : 'images';
    const dir = path.join(config.upload.dir, sub);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname) || '';
    const name = `${Date.now()}_${Math.random().toString(36).slice(2, 8)}${ext}`;
    cb(null, name);
  },
});
const mixedFilter = (req, file, cb) => {
  if (/^image\//.test(file.mimetype) || /^video\//.test(file.mimetype)) {
    return cb(null, true);
  }
  cb(new Error('仅支持图片或视频'));
};
const MAX_FILES_PER_UPLOAD = 20;
const mediaUploader = multer({
  storage: mixedStorage,
  fileFilter: mixedFilter,
  limits: {
    fileSize: config.upload.maxMB * 1024 * 1024,
    files: MAX_FILES_PER_UPLOAD,
  },
});

// 错误处理中间件（捕获 multer 错误并返回统一结构）
const handleUploadError = (err, req, res, next) => {
  if (err instanceof multer.MulterError || err) {
    return res.status(400).json(fail(err.message || '上传失败', 400));
  }
  next();
};

module.exports = {
  imageUploader,
  videoUploader,
  avatarUploader,
  mediaUploader,
  MAX_FILES_PER_UPLOAD,
  handleUploadError,
};
