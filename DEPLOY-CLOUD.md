# 云端部署（cloud 分支）

此分支用于把 OptionWorkstation 部署到 **腾讯云 CloudBase CloudRun 容器**。
本地部署的主线在 `main` 分支；本分支只是部署配置差异（`.env.example` 的云端模板 + 本说明）。

## 部署目标

- 环境：`space-d9gig1bg3d7b37c1a`（上海 `ap-shanghai`）
- 容器服务：`optionworkstation`
- 公网域名：`https://optionworkstation-287683-5-1253873819.sh.run.tcloudbase.com/`

## 必须注入的环境变量（部署时设置，不要写进 .env 提交）

| 变量 | 值 | 说明 |
|------|-----|------|
| `OW_OAUTH_REDIRECT_BASE` | `https://optionworkstation-287683-5-1253873819.sh.run.tcloudbase.com` | 后端据此生成 `/api/oauth/callback` 回调地址 |
| `OPTION_WORKSTATION_HOST` | `0.0.0.0` | 容器内监听所有网卡 |
| `OPTION_WORKSTATION_PORT` | `7311` | 服务端口 |
| `OPTION_WORKSTATION_FRONTEND_DIST` | `./frontend/dist` | 前端静态目录 |

> `OW_OAUTH_REDIRECT_BASE` 在 `main` 分支不设置，因此本地版自动走 `http://localhost:60355/callback`，无需长桥白名单。

## 长桥 OAuth 白名单（必须做）

在长桥开发者中心（https://open.longbridge.com）给你的 OAuth 应用加入回调白名单：

```
https://optionworkstation-287683-5-1253873819.sh.run.tcloudbase.com/api/oauth/callback
```

否则授权后浏览器被长桥拒回（之前 502 / 验证失败的根因就是这里没加）。

## 部署记录

- 部署 #008：status=normal，FlowRatio=100，MinNum=1，已注入 `OW_OAUTH_REDIRECT_BASE`。
- 容器到 `openapi.longbridge.com:443` / `openapi.longbridge.cn:443` 的 TCP 连通性已验证为通（`/api/debug/connectivity` 返回 true），之前的 502 纯属本地回调收不到，非网络阻断。

## 与 main 分支的关系

源码完全一致（含 `vendor/longbridge-oauth` 的云端 OAuth 改造、`rust-backend/src/live.rs` 的
云端分支）。云能力通过 `OW_OAUTH_REDIRECT_BASE` 环境变量开关，本地不设即走 localhost，设了即走公网回调。
日常开发在 `main` 进行，本分支只维护部署配置。
