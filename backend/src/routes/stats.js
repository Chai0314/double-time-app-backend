'use strict';
const router = require('express').Router();
const { authMiddleware } = require('../middleware/auth');
const ah = require('../middleware/async_handler');
const statsCtl = require('../controllers/statsController');
const msgCtl = require('../controllers/messageController');

router.use(authMiddleware);

router.get('/stats/overview', ah(statsCtl.overview));

router.get('/messages', ah(msgCtl.list));
router.get('/messages/unread-count', ah(msgCtl.unreadCount));
router.put('/messages/read-all', ah(msgCtl.readAll));
router.put('/messages/:id/read', ah(msgCtl.read));

module.exports = router;
