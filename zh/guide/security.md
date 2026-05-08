---
title: 安全模型
---

# 安全模型

## 概述

`@appzgatenz/label-print-topbridge-js` 采用多层安全防御机制，防止未授权调用和数据泄露。

## 1. 固定本地连接

SDK 固定连接 `ws://localhost:8765`（内部自动拼接 `/v2`），不提供任何连接地址配置。这从根本上防止了将 SDK 配置为连接远程服务器的可能性。

## 2. source 字段白名单

V2 `print` 请求自动注入白名单内的 `source` 字段。TopBridge Tray App 端维护完整白名单：

| source 值 | 允许的调用方 |
|-----------|-------------|
| `Excel` | self-service Web 应用 |
| `Odoo` | Odoo ERP 插件 |
| `Core-SDK` | 第三方 SDK（本 SDK） |
| `React-SDK` | 后续 React SDK |
| `Nextjs-SDK` | 后续 Next.js SDK |

不在白名单中的 source 值会被 Tray App 拒绝。

本 core SDK 只允许配置 `Core-SDK` / `React-SDK` / `Nextjs-SDK`。`Excel` / `Odoo` 是 Tray App 端保留给 self-service 和 Odoo 插件的来源，不通过本 npm 包暴露。

## 3. 构建时混淆

生产构建（`tsup`）启用以下保护：

- `minify: true` — 代码压缩混淆
- `treeshake: true` — 移除未使用代码
- 无 source map 发布（npm 包不包含 `.map` 文件）

这增加了反编译和修改 SDK 代码的成本。

## 4. URL 安全校验

SDK 在展示来自 Tray App 错误响应的外部链接（`storeUrl` / `downloadUrl`）前，通过 `isSafeUrl()` 校验：

```typescript
// 仅允许以下协议
'https://' ✅
'ms-windows-store://' ✅
'http://' ❌
'javascript:' ❌
'data:' ❌
```

## 5. 输入净化

`coerceToString()` 函数自动剥离公式注入前缀（`=` 和 `=@`），防止通过打印数据注入。

## 已知限制

| 限制 | 说明 | 缓解措施 |
|------|------|---------|
| 客户端校验可被绕过 | 修改 SDK 源码可移除连接限制 | 构建混淆增加成本 + Tray App 端限制 |
| 浏览器端无法防止页面模拟 | 恶意网页可以自己实现 WS 协议 | Tray App source 白名单 + 服务端验证 |
| WS 协议无加密 | localhost 通信默认不加密 | 本地通信不需要加密（不存在网络传输风险） |
