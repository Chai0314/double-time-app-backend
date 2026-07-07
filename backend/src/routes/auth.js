'use strict';
const router = require('express').Router();
const { authMiddleware } = require('../middleware/auth');
const ah = require('../middleware/async_handler');
const ctl = require('../controllers/authController');
const { avatarUploader, handleUploadError } = require('../middleware/upload');

// 用户认证
router.post('/auth/register', ah(ctl.register));
router.post('/auth/login', ah(ctl.login));
router.post('/auth/wx-login', ah(ctl.wxLogin));
router.get('/auth/me', authMiddleware, ah(ctl.me));
router.put('/auth/me', authMiddleware, ah(ctl.updateMe));
router.post(
  '/auth/avatar',
  authMiddleware,
  avatarUploader.single('file'),
  handleUploadError,
  ah(ctl.uploadAvatar)
);
router.post('/auth/change-password', authMiddleware, ah(ctl.changePassword));

// 情侣绑定
router.post('/couple/invite', authMiddleware, ah(ctl.createInvite));
router.post('/couple/bind', authMiddleware, ah(ctl.bind));
router.post('/couple/unbind', authMiddleware, ah(ctl.unbind));
router.get('/couple/info', authMiddleware, ah(ctl.coupleInfo));
router.get('/couple/members', authMiddleware, ah(ctl.members));

module.exports = router;
