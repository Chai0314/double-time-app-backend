'use strict';
const { sequelize } = require('../config/database');
const { User, Couple } = require('./user');
const { Schedule, ScheduleMember } = require('./schedule');
const { Media } = require('./media');
const { Todo } = require('./todo');
const { Message } = require('./message');

module.exports = {
  sequelize,
  User,
  Couple,
  Schedule,
  ScheduleMember,
  Media,
  Todo,
  Message,
};
