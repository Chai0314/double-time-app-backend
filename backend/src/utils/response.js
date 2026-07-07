'use strict';

/**
 * 统一接口返回结构
 */
const success = (data = null, msg = 'success') => ({ code: 0, msg, data });
const fail = (msg = 'fail', code = 1, data = null) => ({ code, msg, data });

class BizError extends Error {
  constructor(msg, code = 1) {
    super(msg);
    this.code = code;
  }
}

module.exports = { success, fail, BizError };
