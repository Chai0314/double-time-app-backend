'use strict';
const router = require('express').Router();
const { authMiddleware } = require('../middleware/auth');
const ah = require('../middleware/async_handler');
const ctl = require('../controllers/todoController');

router.use(authMiddleware);

router.get('/todos', ah(ctl.list));
router.get('/todos/stats', ah(ctl.stats));
router.get('/todos/:id', ah(ctl.detail));
router.post('/todos', ah(ctl.create));
router.put('/todos/:id', ah(ctl.update));
router.delete('/todos/:id', ah(ctl.remove));

module.exports = router;
