'use strict';
const path = require('path');
const fs = require('fs');
const ffmpegPath = require('ffmpeg-static');
const { execFile } = require('child_process');
const config = require('../config');

const THUMB_DIR = path.join(config.upload.dir, 'thumbs');
if (!fs.existsSync(THUMB_DIR)) fs.mkdirSync(THUMB_DIR, { recursive: true });

/**
 * 用 ffmpeg 抽取视频首帧
 * @param {string} videoPath 原视频绝对路径
 * @returns {Promise<{ thumbPath: string, thumbUrl: string, width: number, height: number } | null>}
 */
function generateVideoThumb(videoPath) {
  if (!ffmpegPath) return Promise.resolve(null);
  const baseName = path.basename(videoPath, path.extname(videoPath));
  const thumbName = `${baseName}.jpg`;
  const thumbPath = path.join(THUMB_DIR, thumbName);
  return new Promise((resolve) => {
    // -ss 0：取首帧；-vframes 1：只 1 帧；-vf scale：限制最大尺寸为 480px
    const args = [
      '-y',
      '-i', videoPath,
      '-ss', '0',
      '-vframes', '1',
      '-vf', 'scale=min(480\\,iw):-2',
      '-q:v', '4',
      thumbPath,
    ];
    execFile(ffmpegPath, args, { timeout: 15000 }, (err) => {
      if (err || !fs.existsSync(thumbPath)) {
        // 失败不阻塞主流程
        return resolve(null);
      }
      // 用 ffprobe 不现实，直接按原视频尺寸处理；返回时宽高交给调用方用 media.width/height
      resolve({
        thumbPath,
        thumbUrl: `/uploads/thumbs/${thumbName}`,
        width: 0,
        height: 0,
      });
    });
  });
}

module.exports = { generateVideoThumb, THUMB_DIR };
