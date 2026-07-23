// CORS 预检 + 真实请求统一注入 CORS 响应头的 Service Worker
// 版本：v2 - 2026-07-09
//
// 背景：
// 1) 后端 cors() 默认会把 Access-Control-Allow-Origin: * 加到响应上，
//    但错误响应（比如 media/batch multer 抛错时的 400）有时拿不到这个头，
//    浏览器就会把响应拦掉。
// 2) 之前预检 (OPTIONS) 又被 SW 回了一份 Access-Control-Allow-Origin: <origin>，
//    浏览器/抓包工具在跨请求链路里把这两处都展示出来，看着像"两个"。
//
// 这里由 SW 接管所有打到 /double-time-app-backend-api 的请求：
//   - OPTIONS 直接合成 204 响应
//   - 其他请求代为 fetch 一遍，**主动**把 Access-Control-Allow-Origin: *
//     注入到响应头里（无论后端有没有回、状态码是什么），保证浏览器一定能读到。

const API_PREFIX = '/double-time-app-backend-api';
const SW_VERSION = 'v2-20260709';

self.addEventListener('install', (event) => {
  console.log('[SW]', SW_VERSION, 'installing');
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  console.log('[SW]', SW_VERSION, 'activating');
  event.waitUntil(self.clients.claim());
});

function isApiRequest(url) {
  return url.indexOf(API_PREFIX) !== -1;
}

function withCors(headers, request) {
  // 直接覆盖，保证只有一份、值稳定为 *
  headers.set('Access-Control-Allow-Origin', '*');
  headers.set('Vary', 'Origin');
  return headers;
}

self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = request.url;

  // 非后端 API 的请求（Flutter 自身资源、CDN 等）放行
  if (!isApiRequest(url)) {
    return;
  }

  // 预检：由 SW 直接应答，不再发到网络
  if (request.method === 'OPTIONS') {
    event.respondWith(
      new Response(null, {
        status: 204,
        headers: withCors(new Headers(), request),
      })
    );
    return;
  }

  // 真实请求：代为转发并**强制**补 CORS 头
  event.respondWith(
    (async () => {
      try {
        const fetched = await fetch(request);
        // 不管后端有没有回 / 回什么，这里都覆盖为 *，确保唯一且存在
        const newHeaders = withCors(new Headers(fetched.headers), request);
        return new Response(fetched.body, {
          status: fetched.status,
          statusText: fetched.statusText,
          headers: newHeaders,
        });
      } catch (err) {
        // fetch 自己就因为 CORS 挂了时，构造一个带 CORS 头的兜底响应
        return new Response(
          JSON.stringify({ code: -1, msg: 'sw fetch failed: ' + (err && err.message) }),
          {
            status: 502,
            headers: withCors(new Headers({ 'Content-Type': 'application/json' }), request),
          }
        );
      }
    })()
  );
});
