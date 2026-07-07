'use strict';
const router = require('express').Router();
const { authMiddleware } = require('../middleware/auth');
const ah = require('../middleware/async_handler');
const ctl = require('../controllers/scheduleController');

router.use(authMiddleware);

router.get('/schedules', ah(ctl.list));
router.get('/schedules/today', ah(ctl.today));
router.get('/schedules/calendar', ah(ctl.calendar));
router.get('/schedules/:id', ah(ctl.detail));
router.post('/schedules', ah(ctl.create));
router.put('/schedules/:id', ah(ctl.update));
router.delete('/schedules/:id', ah(ctl.remove));

module.exports = router;
