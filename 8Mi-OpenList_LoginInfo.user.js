// ==UserScript==
// @name         8Mi-OpenList_LoginInfo
// @namespace    http://tampermonkey.net/
// @version      2025-08-30
// @description  获取云盘登录信息
// @author       8Mi-Tech
// @match        https://yun.139.com/w/*
// @match        https://pan.wo.cn/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=8mi.tech
// @grant        none
// ==/UserScript==

(function () {
  "use strict";

  // 加载界面库
  var script = document.createElement("script");
  script.src = "https://cdn.jsdelivr.net/gh/layui/layui@main/dist/layui.js";
  document.head.appendChild(script);

  // 在界面库加载完成后执行
  script.onload = function () {
    // 根据不同的域名执行不同的操作
    if (window.location.hostname === "yun.139.com") {
      // 139云盘处理逻辑
      handle139Cloud();
    } else if (window.location.hostname === "pan.wo.cn") {
      // 沃云盘处理逻辑
      handleWoCloud();
    }

    function handle139Cloud() {
      layer.msg('8Mi-OpenList_LoginInfo for 139Cloud');
      setTimeout(function() {
        layer.open({
          type: 0,
          title: "8Mi-OpenList_LoginInfo for 移动云盘",
          offset: 'auto',
          closeBtn: 0,
          content: create139CloudContent()
        });
      }, 1000);
    }

    function create139CloudContent() {
      return `
        <head>
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/layui/layui@main/dist/css/layui.css">
        </head>
        <body>
          <div class="layui-form-item layui-form-pane">
            <label class="layui-form-label" width="50px">Authorization：</label>
            <div class="layui-input-block">
              <input type="text" name="Authorization" lay-verify="required" placeholder="" autocomplete="off" class="layui-input" value="${getCookie("authorization")}">
            </div>
          </div>
          <div class="layui-form-item layui-form-pane">
            <label class="layui-form-label">验证令牌</label>
            <div class="layui-input-block">
              <input type="text" name="auth_token" lay-verify="required" placeholder="" autocomplete="off" class="layui-input" value="${getCookie("auth_token")}">
            </div>
          </div>
        </body>`;
    }

    function handleWoCloud() {
      layer.msg('8Mi-OpenList_LoginInfo for WoPan');

      // 检查WoCloud-Web-Token是否存在
      const woCloudToken = getCookie("WoCloud-Web-Token");

      if (!woCloudToken) {
        // 如果WoCloud-Web-Token不存在，清除保存的token
        deleteCookie("8Mi-Access-Token");
        deleteCookie("8Mi-Refresh-Token");
        layer.msg('已清除保存的Token信息');
        // 拦截特定URL请求
        interceptWoCloudRequests();
      } else {
        // 如果WoCloud-Web-Token存在，显示之前保存的token信息
        const accessToken = getCookie("8Mi-Access-Token");
        const refreshToken = getCookie("8Mi-Refresh-Token");

        if (accessToken && refreshToken) {
          showTokenInfo(accessToken, refreshToken);
        }
      }


    }

    function interceptWoCloudRequests() {
      // 保存原始XMLHttpRequest
      const originalXHROpen = XMLHttpRequest.prototype.open;
      const originalXHRSend = XMLHttpRequest.prototype.send;

      // 重写XMLHttpRequest的open方法
      XMLHttpRequest.prototype.open = function(method, url) {
        this._url = url;
        return originalXHROpen.apply(this, arguments);
      };

      // 重写XMLHttpRequest的send方法
      XMLHttpRequest.prototype.send = function(body) {
        // 添加readystatechange事件监听器
        this.addEventListener("readystatechange", function() {
          if (this.readyState === 4 && this.status === 200) {
            // 检查是否为目标URL
            if (this._url && this._url.startsWith("https://panservice.mail.wo.cn/wohome/open/v1/QRCode/query?uuid=")) {
              try {
                const response = JSON.parse(this.responseText);
                if (response && response.result && response.result.state === 3) {
                  // 保存token到Cookie
                  setCookie("8Mi-Access-Token", response.result.token, 7);
                  setCookie("8Mi-Refresh-Token", response.result.refreshToken, 7);

                  // 显示成功消息
                  layer.msg('成功获取Token并保存到Cookie');

                  // 显示token信息
                  showTokenInfo(response.result.token, response.result.refreshToken);
                }
              } catch (e) {
                console.error("解析响应数据失败:", e);
              }
            }
          }
        });

        return originalXHRSend.apply(this, arguments);
      };
    }

    function showTokenInfo(token, refreshToken) {
      layer.open({
        type: 0,
        title: "8Mi-OpenList_LoginInfo for 联通云盘",
        offset: 'auto',
        closeBtn: 0,
        content: createTokenContent(token, refreshToken)
      });
    }

    function createTokenContent(token, refreshToken) {
      return `
        <head>
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/layui/layui@main/dist/css/layui.css">
        </head>
        <body>
          <div class="layui-form-item">
            <label class="layui-form-label">访问令牌:</label>
            <div class="layui-input-block" width="100%">
              <input type="text" name="access_token" lay-verify="required" placeholder="" autocomplete="off" class="layui-input" value="${token}">
            </div>
          </div>
          <div class="layui-form-item">
            <label class="layui-form-label">刷新令牌:</label>
            <div class="layui-input-block" width="100%">
              <input type="text" name="refresh_token" lay-verify="required" placeholder="" autocomplete="off" class="layui-input" value="${refreshToken}">
            </div>
          </div>
        </body>`;
    }

    function getCookie(cookieName) {
      const cookies = document.cookie.split(";");
      for (let i = 0; i < cookies.length; i++) {
        const cookie = cookies[i].trim();
        if (cookie.startsWith(cookieName + "=")) {
          return cookie.substring(cookieName.length + 1);
        }
      }
      return null;
    }

    function setCookie(name, value, days) {
      const date = new Date();
      date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
      const expires = "expires=" + date.toUTCString();
      document.cookie = name + "=" + value + ";" + expires + ";path=/";
    }

    function deleteCookie(name) {
      document.cookie = name + "=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/;";
    }
  };
})();
