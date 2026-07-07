'use strict';
/**
 * 包装 async 控制器，自动捕获异常并传给 next
 * 用法：router.get('/path', asyncHandler(ctl.method))
 */
module.exports = (fn) => (req, res, next) => {
  Promise.resolve(fn(req, res, next)).catch(next);
};
