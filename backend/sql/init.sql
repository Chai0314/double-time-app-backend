-- 双人时光 · 建表脚本（MySQL 8.0 / utf8mb4）
-- 容器首次启动时会自动执行

CREATE DATABASE IF NOT EXISTS couple_space CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE couple_space;

-- ----------------------------
-- 1. 情侣对表（绑定关系）
-- ----------------------------
CREATE TABLE IF NOT EXISTS couple (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  invite_code  VARCHAR(12)  NOT NULL COMMENT '邀请码',
  status       TINYINT      NOT NULL DEFAULT 0 COMMENT '0=待对方确认 1=已绑定 2=已解绑',
  creator_id   BIGINT UNSIGNED NULL COMMENT '邀请码创建者（未绑定时记录是谁生成的）',
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_invite_code (invite_code),
  KEY idx_creator (creator_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='情侣对';

-- ----------------------------
-- 2. 用户表
-- ----------------------------
CREATE TABLE IF NOT EXISTS user (
  id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  couple_id      BIGINT UNSIGNED NULL COMMENT '所属情侣对',
  nickname       VARCHAR(64)  NOT NULL DEFAULT '' COMMENT '昵称',
  avatar         VARCHAR(255) NOT NULL DEFAULT '' COMMENT '头像URL',
  account        VARCHAR(64)  NULL COMMENT '账号（App登录用）',
  password_hash  VARCHAR(255) NULL COMMENT '密码哈希',
  openid         VARCHAR(64)  NULL COMMENT '微信openid',
  phone          VARCHAR(20)  NULL,
  gender         TINYINT      NOT NULL DEFAULT 0 COMMENT '0未知 1男 2女',
  bio            VARCHAR(255) NOT NULL DEFAULT '' COMMENT '个性签名',
  anniversary    DATE         NULL COMMENT '纪念日',
  work_start     TIME         NULL COMMENT '作息开始',
  work_end       TIME         NULL COMMENT '作息结束',
  status         TINYINT      NOT NULL DEFAULT 1 COMMENT '1正常 0禁用',
  last_login_at  DATETIME     NULL,
  created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_account (account),
  UNIQUE KEY uk_openid (openid),
  KEY idx_couple (couple_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户';

-- ----------------------------
-- 3. 行程表
-- ----------------------------
CREATE TABLE IF NOT EXISTS schedule (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  couple_id     BIGINT UNSIGNED NOT NULL,
  creator_id    BIGINT UNSIGNED NOT NULL COMMENT '创建人',
  title         VARCHAR(128) NOT NULL,
  category      VARCHAR(32)  NOT NULL DEFAULT 'other' COMMENT 'date/travel/home/festival/errand/other',
  address       VARCHAR(255) NOT NULL DEFAULT '',
  longitude     DECIMAL(10,6) NULL,
  latitude      DECIMAL(10,6) NULL,
  start_time    DATETIME     NOT NULL,
  end_time      DATETIME     NULL COMMENT '空=临时行程',
  repeat_type   VARCHAR(16)  NOT NULL DEFAULT 'none' COMMENT 'none/daily/weekly/monthly',
  repeat_end    DATE         NULL,
  remind_offset INT          NOT NULL DEFAULT 0 COMMENT '提前分钟数 0=不提醒',
  budget        DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '预算',
  actual_cost   DECIMAL(10,2) NOT NULL DEFAULT 0 COMMENT '实际花费',
  remark        TEXT         NULL,
  status        TINYINT      NOT NULL DEFAULT 0 COMMENT '0待开始 1进行中 2已完成 3已取消',
  is_archived   TINYINT      NOT NULL DEFAULT 0,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_couple_start (couple_id, start_time),
  KEY idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='行程';

-- ----------------------------
-- 4. 行程参与人（多对多）
-- ----------------------------
CREATE TABLE IF NOT EXISTS schedule_member (
  schedule_id BIGINT UNSIGNED NOT NULL,
  user_id     BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (schedule_id, user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='行程参与人';

-- ----------------------------
-- 5. 相册素材
-- ----------------------------
CREATE TABLE IF NOT EXISTS media (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  couple_id    BIGINT UNSIGNED NOT NULL,
  schedule_id  BIGINT UNSIGNED NULL COMMENT '绑定行程，空=未绑定',
  uploader_id  BIGINT UNSIGNED NOT NULL,
  media_type   VARCHAR(16)  NOT NULL DEFAULT 'image' COMMENT 'image/video',
  url          VARCHAR(255) NOT NULL,
  thumb_url    VARCHAR(255) NOT NULL DEFAULT '',
  duration     INT          NOT NULL DEFAULT 0 COMMENT '视频秒数',
  width        INT          NOT NULL DEFAULT 0,
  height       INT          NOT NULL DEFAULT 0,
  size         BIGINT       NOT NULL DEFAULT 0,
  remark       VARCHAR(255) NOT NULL DEFAULT '',
  is_star      TINYINT      NOT NULL DEFAULT 0,
  taken_at     DATETIME     NULL COMMENT '拍摄时间',
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_couple_schedule (couple_id, schedule_id),
  KEY idx_couple_created (couple_id, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='素材';

-- ----------------------------
-- 6. Todo
-- ----------------------------
CREATE TABLE IF NOT EXISTS todo (
  id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  couple_id       BIGINT UNSIGNED NOT NULL,
  creator_id      BIGINT UNSIGNED NOT NULL,
  title           VARCHAR(128) NOT NULL,
  category        VARCHAR(32)  NOT NULL DEFAULT 'daily' COMMENT 'daily/short/middle/long/divided',
  level           TINYINT      NOT NULL DEFAULT 1 COMMENT '1高 2中 3低',
  executor_id     BIGINT UNSIGNED NULL COMMENT '单人执行人；null=双人共同',
  schedule_id     BIGINT UNSIGNED NULL,
  deadline        DATETIME     NULL,
  remind_offset   INT          NOT NULL DEFAULT 0,
  repeat_type     VARCHAR(16)  NOT NULL DEFAULT 'none',
  remark          TEXT         NULL,
  status          TINYINT      NOT NULL DEFAULT 0 COMMENT '0待处理 1进行中 2已完成 3逾期 4作废',
  completed_at    DATETIME     NULL,
  created_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_couple_deadline (couple_id, deadline),
  KEY idx_couple_status (couple_id, status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='待办';

-- ----------------------------
-- 7. 消息通知
-- ----------------------------
CREATE TABLE IF NOT EXISTS message (
  id           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  couple_id    BIGINT UNSIGNED NOT NULL,
  sender_id    BIGINT UNSIGNED NULL,
  receiver_id  BIGINT UNSIGNED NOT NULL,
  type         VARCHAR(32)  NOT NULL COMMENT 'schedule/todo/media/couple',
  title        VARCHAR(128) NOT NULL DEFAULT '',
  content      VARCHAR(512) NOT NULL DEFAULT '',
  ref_type     VARCHAR(32)  NOT NULL DEFAULT '' COMMENT '关联资源类型',
  ref_id       BIGINT UNSIGNED NULL,
  is_read      TINYINT      NOT NULL DEFAULT 0,
  created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_receiver (receiver_id, is_read, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='消息';
