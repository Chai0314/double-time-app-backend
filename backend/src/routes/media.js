'use strict';
const router = require('express').Router();
const { authMiddleware } = require('../middleware/auth');
const ah = require('../middleware/async_handler');
const ctl = require('../controllers/mediaController');
const {
  imageUploader,
  videoUploader,
  mediaUploader,
  handleUploadError,
} = require('../middleware/upload');

router.use(authMiddleware);

router.get('/media', ah(ctl.list));
router.get('/media/group-by-schedule', ah(ctl.groupBySchedule));
// 单文件：向后兼容
router.post('/media', imageUploader.single('file'), handleUploadError, ah(ctl.create));
router.post('/media/video', videoUploader.single('file'), handleUploadError, ah(ctl.create));
// 批量：图片+视频混合，字段名 'files'，最多 20 个
router.post(
  '/media/batch',
  mediaUploader.array('files', 20),
  handleUploadError,
  ah(ctl.createBatch)
);
router.put('/media/:id', ah(ctl.update));
router.delete('/media/:id', ah(ctl.remove));

module.exports = router;
