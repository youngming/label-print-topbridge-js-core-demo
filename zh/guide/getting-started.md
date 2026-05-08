---
title: 安装与初始化
---

# 快速开始

## 安装

```bash
npm install @appzgatenz/label-print-topbridge-js
```

## 前置条件

- TopBridge 桌面应用已安装并运行在本地
- 浏览器支持 WebSocket（所有现代浏览器均支持）
- 如果使用 `launch.trigger()`，页面 CSP 需允许 `topsale:` 自定义协议（`frame-src topsale:`）
- TopBridge Tray App 支持 WebSocket API V2（统一入口 `/v2`）

## 初始化

```typescript
import { TopBridgeClient } from '@appzgatenz/label-print-topbridge-js'

const client = new TopBridgeClient()
```

SDK 固定连接 `ws://localhost:8765`（内部自动拼接 `/v2`），无需配置连接地址。

## 完整打印流程

```typescript
// 0. 可选：确保 Tray App 已启动
const { printers } = await client.launch.ensureRunning(
  () => client.preflight.run({
    onStepChange: (step) => console.log(`Checking ${step}...`)
  })
)

// 或者直接运行预检（不自动唤起 Tray App）
// const { printers } = await client.preflight.run()

// 1. 获取可用模板
const templates = await client.templates.list()

// 2. 可选：获取模板字段定义
const schema = await client.templates.schema('PRICE_LABEL')

// 3. 执行打印
const result = await client.print.execute({
  template: 'PRICE_LABEL',       // 模板 ID 或 Code
  printer: 'TSC DA220',          // 打印机名称
  products: [
    { name: 'Apple', price: 3.99, currency: '$', unit: '/kg', copies: 2 },
    { name: 'Banana', price: 1.99, currency: '$', copies: 1 },
  ],
  fieldTypes: { price: 'price' }, // 标记 price 为结构化字段
})

console.log(`Printed ${result.data.printedCopies} copies`)
```

## 配置选项

```typescript
const client = new TopBridgeClient({
  debug: true,                     // 开启日志输出
  timeouts: {
    health: 3000,                  // 健康检查超时（ms）
    preflight: 10000,              // 预检超时（ms）
    print: 60000,                  // 打印超时（ms）
  },
})
```

## 错误处理

```typescript
import {
  TopBridgeConnectionError,
  TopBridgeAuthError,
  TopBridgeQuotaError,
  TopBridgePrintError,
  TopBridgePrinterError,
  TopBridgeTemplateError,
  TopBridgeNetworkError,
  TopBridgeSourceError,
} from '@appzgatenz/label-print-topbridge-js'

try {
  await client.print.execute({ /* ... */ })
} catch (err) {
  if (err instanceof TopBridgeConnectionError) {
    // Tray App 未运行或连接超时
  } else if (err instanceof TopBridgeAuthError) {
    // 未登录或需要更新
    if (err.code === 'UPDATE_REQUIRED') {
      window.open(err.storeUrl) // 引导用户更新
    }
  } else if (err instanceof TopBridgeQuotaError) {
    // 权益无效或配额耗尽
  } else if (err instanceof TopBridgePrinterError) {
    // 打印机离线或未配置协议
  } else if (err instanceof TopBridgeTemplateError) {
    // 模板不存在或无权限
  } else if (err instanceof TopBridgeNetworkError) {
    // Tray App 在线，但云端网络断开
  } else if (err instanceof TopBridgeSourceError) {
    // source 不在白名单中
  } else if (err instanceof TopBridgePrintError) {
    // 打印失败
  }
}
```

## fieldTypes 配置

`fieldTypes` 用于告诉 SDK 哪些字段需要结构化转换（price → `{value, currency, unit}`）。

### 简单模式（字符串）

SDK 内置约定：`price` 自动关联 `currency` 和 `unit` 子字段。

```typescript
fieldTypes: { price: 'price', weight: 'weight' }
```

### 显式模式（对象）

当有多个同类型字段或子字段命名不标准时：

```typescript
fieldTypes: {
  price: { type: 'price', subFields: ['priceCurrency', 'priceUnit'] },
  weight: { type: 'weight', subFields: ['weightUnit'] },
}
```

### 无 fieldTypes

不提供 `fieldTypes` 时，所有字段以原始格式发送（text 模式）。
