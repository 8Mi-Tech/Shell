// ==UserScript==
// @name         8Mi-AListGetToken
// @namespace    http://tampermonkey.net/
// @version      2024-04-03
// @description  try to take over the world!
// @author       You
// @match        https://yun.139.com/w/*
// @match        https://pan.wo.cn/*
// @match https://pan.wo.cn/pan/file_list/all
// @icon         https://www.google.com/s2/favicons?sz=64&domain=8mi.tech
// @grant        none
// ==/UserScript==

(function () {
  "use strict";

  // 当前页面的URL
  var currentURL = window.location.href;

  // 加载界面库
  var script = document.createElement("script");
  script.src = "https://cdn.jsdelivr.net/gh/layui/layui@main/dist/layui.js";
  document.head.appendChild(script);

  // 在界面库加载完成后执行你的操作
  script.onload = function () {
    // 根据不同的URL执行不同的操作
    function getCookie(cookieName) {
      var cookies = document.cookie.split(";");
      var cookieValue = null;

      for (var i = 0; i < cookies.length; i++) {
        var cookie = cookies[i].trim();
        if (cookie.startsWith(cookieName + "=")) {
          cookieValue = cookie.substring(cookieName.length + 1);
          break;
        }
      }
      return cookieValue;
    }

    console.log("window.location.hostname", window.location.hostname);

    if (window.location.hostname == "yun.139.com") {
        layer.msg('8Mi-AListGetToken for 139Cloud');
        layer.open({
          type: 0, // page 层类型，其他类型详见「基础属性」
          title: "8Mi-AListGetToken for 移动云盘",
          offset: 'auto',
          closeBtn: 0,
          //area: '520px',
          content:
                `<head>
                    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/layui/layui@main/dist/css/layui.css">
                </head>
                <body>
                    <div class="layui-form-item layui-form-pane">
                        <label class="layui-form-label" width="50px">Authorization：</label>
                        <div class="layui-input-block">
                            <input type="text" name="Authorization" lay-verify="required" placeholder="" autocomplete="off" class="layui-input" value="` + getCookie("authorization") + `">
                        </div>
                    </div>
                    <div class="layui-form-item layui-form-pane">
                        <label class="layui-form-label">Auth-Token</label>
                        <div class="layui-input-block">
                            <input type="text" name="auth_token" lay-verify="required" placeholder="" autocomplete="off" class="layui-input" value="` + getCookie("auth_token") + `">
                        </div>
                    </div>
                </body>`,
        });
    }

    if (window.location.hostname == "pan.wo.com") {
        layer.msg('8Mi-AListGetToken for WoPan');
        if (getCookie("WoCloud-Web-Token") !== null && getCookie("WoCloud-Web-Token") !== "") {
          // 信息窗口
          layer.open({
            type: 0, // page 层类型，其他类型详见「基础属性」
            title: "8Mi-AListGetToken for 联通云盘",
            offset: 'auto',
            closeBtn: 0,
            content:
                `<head>
                    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/layui/layui@main/dist/css/layui.css">
                </head>
                <body>
                    <div class="layui-form-item"><label class="layui-form-label">access_token*:</label>
                        <div class="layui-input-block" width="100%">
                            <input type="text" name="access_token_cookie" lay-verify="required" placeholder="" autocomplete="off" class="layui-input" value="` + getCookie("WoCloud-Web-Token") + `">
                        </div>
                    </div>
                </body>`,
          });
          return;
        }

        // 存储正在等待响应的请求
        var pendingRequests = {};

        // 重写fetch函数以添加请求标识
        var originalFetch = window.fetch;
        window.fetch = function (request, options) {
          // 生成一个唯一的请求标识
          var requestId = Math.random().toString(36).substring(7);
          // 将请求标识添加到请求头中
          var modifiedOptions = options || {};
          modifiedOptions.headers = modifiedOptions.headers || {};
          modifiedOptions.headers["request-id"] = requestId;
          // 发送请求
          var promise = originalFetch(request, modifiedOptions);
          // 存储请求以便后续处理响应
          pendingRequests[requestId] = request;
          return promise;
        };

        // 监听响应
        window.addEventListener("fetch", async function (event) {
          var requestId = event.request.headers.get("request-id");
          if (requestId && pendingRequests[requestId]) {
            // 检查请求的类型和地址
            if (
              event.request.method === "POST" &&
              event.request.url ===
                "https://panservice.mail.wo.cn/api-user/dispatcher"
            ) {
              // 读取请求体JSON数据
              var requestBody;
              try {
                requestBody = await pendingRequests[requestId].json();
              } catch (error) {
                console.error("Failed to parse request body JSON:", error);
                return new Response(null, { status: 500 });
              }

              // 检查请求体是否包含关键词
              if (
                requestBody &&
                requestBody.header &&
                requestBody.header.key === "PcLoginVerifyCode"
              ) {
                try {
                  // 返回原始的请求响应
                  var response = await fetch(event.request);

                  // 读取响应的JSON数据
                  var responseData = await response.json();

                  // 检查响应数据中是否包含access_token
                  if (
                    responseData &&
                    responseData.RSP &&
                    responseData.RSP.DATA &&
                    responseData.RSP.DATA.access_token
                  ) {
                    // 提取access_token和refresh_token
                    var accessToken = responseData.RSP.DATA.access_token;
                    var refreshToken = responseData.RSP.DATA.refresh_token;
                    // 显示access_token和refresh_token
                    console.log("Access Token (from response):", accessToken);
                    console.log("Refresh Token (from response):", refreshToken);
                    // 信息窗口
                    layer.open({
                      type: 0, // page 层类型，其他类型详见「基础属性」
                      title: "8Mi-AListGetToken for 联通云盘",
                      content:
                        `<head>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/layui/layui@main/dist/css/layui.css">
</head>
<body>
    <div class="layui-form-item"><label class="layui-form-label">access_token*:</label>
        <div class="layui-input-block" width="100%">
            <input type="text" name="access_token_cookie" lay-verify="required" placeholder="" autocomplete="off" class="layui-input" value="` +
                        getCookie("WoCloud-Web-Token") +
                        `">
        </div>
    </div>
    <div class="layui-form-item"><label class="layui-form-label">access_token:</label>
        <div class="layui-input-block" width="100%">
            <input type="text" name="access_token" lay-verify="required" placeholder="" autocomplete="off" class="layui-input" value="` +
                        accessToken +
                        `">
        </div>
    </div>
    <div class="layui-form-item"><label class="layui-form-label">refresh_token:</label>
        <div class="layui-input-block" width="100%">
            <input type="text" name="refresh_token" lay-verify="required" placeholder="" autocomplete="off" class="layui-input" value="` +
                        refreshToken +
                        `">
        </div>
    </div>
</body>`,
                    });
                    // 这里你可以根据需要进行进一步操作，例如将token存储起来
                    // 在这里你可以进行进一步的处理，例如存储token等
                  }
                  // 处理完响应后移除该请求
                  delete pendingRequests[requestId];
                  return response;
                } catch (error) {
                  console.error("Failed to fetch response:", error);
                  return new Response(null, { status: 500 });
                }
              }
            }
          }
        });
    }

  };
})();
