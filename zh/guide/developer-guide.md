---
title: 开发者指南
---

# 开发者指南

> 版本：0.2.x | 面向第三方开发者的集成手册

## 1. 概述

### 1.1 什么是 TopBridge

TopBridge 是一个运行在用户本地的桌面应用（本文档中简称为「Tray App」），负责管理标签打印机、模板和用户权益。它通过 WebSocket 协议在本地暴露 API，让浏览器应用能够发送打印指令。

### 1.2 SDK 解决什么问题

`@appzgatenz/label-print-topbridge-js` 是一个 Headless（无 UI）浏览器 SDK，封装了与 TopBridge Tray App 的全部通信细节：

- **WebSocket 连接管理** — 短连接模型，每次调用自动建立、发送、接收、关闭
- **Tray App 唤起与重试** — 通过 `launch` 模块显式触发唤起，含自动重试编排
- **数据转换** — 将扁平的产品数据自动转换为 Tray App 所需的嵌套结构
- **结构化错误** — 10 种错误类型，全部支持 `instanceof` 类型窄化
- **预检编排** — 一行代码完成「健康检查 → 权益验证 → 打印机获取」

SDK 不绑定任何 UI 框架，可在 React / Vue / Svelte / 原生 JS 中使用。

### 1.3 架构概览

```
你的浏览器应用
    │
    ▼
TopBridgeClient (SDK 入口)
    ├── health        健康检查
    ├── benefits      权益与配额验证
    ├── printers      打印机列表
    ├── templates     模板列表 + 字段定义
    ├── print         打印执行（含数据转换）
    ├── preflight     编排：health → benefits → printers
    └── launch        Tray App 唤起 + 重试编排
    │
    ▼  WebSocket (固定 ws://localhost:8765/v2)
TopBridge Tray App (本地桌面应用)
    │
    ▼
标签打印机
```

## 2. 环境准备

### 2.1 前置条件

| 条件 | 说明 |
|------|------|
| TopBridge 桌面应用 | 用户需在本地安装并运行 TopBridge（版本 1.0.30+） |
| 现代浏览器 | 支持 WebSocket + ES2020（Chrome / Firefox / Safari / Edge） |
| 打印机 | 至少一台已配置协议（TSPL / ZPL）的标签打印机 |

### 2.2 CSP 配置

如果使用唤起功能（`client.launch.trigger()` 或 `client.launch.ensureRunning()`），页面 CSP 需允许 `topsale:` 自定义协议：

```
Content-Security-Policy: frame-src 'self' topsale:
```

### 2.3 TopBridge Tray App 是什么

Tray App 是运行在用户电脑上的桌面应用，职责包括：

- 管理打印机连接和协议配置
- 管理用户的登录状态和打印权益
- 渲染模板并驱动打印机输出标签
- 通过 `ws://localhost:8765/v2` 暴露 WebSocket API

SDK 本身不直接与打印机通信，所有操作通过 Tray App 中转。

> **下载**：TopBridge 桌面应用需由用户自行安装。如果你的用户还没有安装，请联系 TopBridge 团队获取安装包或下载链接。

## 3. 安装与初始化

### 3.1 安装

```bash
npm install @appzgatenz/label-print-topbridge-js
```

零运行时依赖，安装后即可使用。

### 3.2 创建客户端

```typescript
import { TopBridgeClient } from '@appzgatenz/label-print-topbridge-js'

const client = new TopBridgeClient()
```

零配置即可使用——SDK 固定连接 `ws://localhost:8765`（内部自动拼接 `/v2`），无需手动配置连接地址。

### 3.3 配置选项

```typescript
const client = new TopBridgeClient({
  debug: false,                    // 开启 console 日志
  logger: customLogger,            // 自定义日志实现
  timeouts: {
    health: 3000,                  // 健康检查超时（ms）
    preflight: 10000,              // 预检超时（ms）
    print: 60000,                  // 打印超时（ms）
  },
})
```

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `debug` | `boolean` | `false` | 快捷开启 console 日志 |
| `logger` | `Logger` | `null` | 自定义日志实现 |
| `timeouts.health` | `number` | `3000` | 健康检查超时（ms） |
| `timeouts.preflight` | `number` | `10000` | 预检超时（ms） |
| `timeouts.print` | `number` | `60000` | 打印超时（ms） |

**自定义 Logger**：

```typescript
import type { Logger } from '@appzgatenz/label-print-topbridge-js'

const logger: Logger = {
  debug: (...args) => myAnalytics.track('debug', args),
  info: (...args) => myAnalytics.track('info', args),
  warn: (...args) => myAnalytics.track('warn', args),
  error: (...args) => Sentry.captureException(args[0]),
}

const client = new TopBridgeClient({ logger })
```

`debug: true` 等价于使用 `console` 作为 logger（所有日志带 `[TopBridge]` 前缀）。

## 4. 核心概念

### 4.1 模块化架构

`TopBridgeClient` 包含 7 个功能模块，每个模块负责一个独立的业务域：

| 模块 | 职责 | 主要方法 |
|------|------|---------|
| `health` | 检查 Tray App 运行状态 | `check()` |
| `benefits` | 验证用户打印权益和配额 | `check()` |
| `printers` | 获取已配置的打印机列表 | `list()` |
| `templates` | 获取模板列表和字段定义 | `list()`, `schema()` |
| `print` | 执行打印任务 | `execute()` |
| `preflight` | 编排前三步的完整预检 | `run()` |
| `launch` | Tray App 唤起与重试编排 | `trigger()`, `ensureRunning()` |

### 4.2 短连接模型

SDK 采用短连接通信：每次 API 调用都会独立创建一个 WebSocket 连接，发送请求，接收响应，然后关闭。你无需手动管理连接生命周期。

```
client.print.execute(...)
  → 连接 ws://localhost:8765/v2
  → 发送 { action: "print", payload: {...} }
  → 接收响应
  → 关闭连接
  → 返回 PrintResponse
```

### 4.3 响应结构

所有 SDK 方法返回统一的响应信封：

```typescript
interface SdkResponse<T> {
  status: 'ok' | 'warning'    // 请求结果状态
  requestId?: string           // 请求追踪 ID
  data: T                      // 业务数据
  warnings?: SdkWarning[]      // 数据格式警告（可选）
}
```

- `status: 'ok'` — 请求成功，`data` 包含业务数据
- `status: 'warning'` — 请求成功但有附加提示（例如健康检查时网络断开）。可正常使用 `data`，同时检查 `message` 获取提示详情
- `warnings` — 非致命的数据格式提示数组。SDK 会在数据转换过程中发现潜在问题时添加，不会阻止打印执行

**SdkWarning 结构**：

```typescript
interface SdkWarning {
  code: string      // 大类标识，如 'DATA_FORMAT'
  reason: string    // 精确标识，如 'newline_truncated'
  message: string   // 人类可读描述
}
```

## 5. 完整集成教程

本节通过一个端到端的示例，逐步演示如何从零集成标签打印功能。

### 5.1 第一步：确保 Tray App 运行 + 预检（Preflight）

在执行打印之前，需要确认三件事：Tray App 在运行且用户已登录、权益有效、打印机可用。`preflight.run()` 一次性完成这些检查。

> `preflight` 是推荐的最佳实践但非强制——你也可以直接调用 `print.execute()`，Tray App 端仍会进行认证和权益校验。不过，使用 preflight 可以在打印前提前发现并处理问题，提供更好的用户体验。
>
> 注意：`preflight.run()` 不再自动唤起 Tray App。如需自动唤起，使用 `client.launch.ensureRunning()` 包装。

```typescript
try {
  // 使用 ensureRunning 包装，自动处理 Tray App 唤起和重试
  const preflight = await client.launch.ensureRunning(
    () => client.preflight.run({
      onStepChange: (step) => {
        console.log(`正在检查: ${step}`)  // health → benefits → printers
      }
    }),
    { onLaunching: () => console.log('正在启动 TopBridge...') }
  )

  const { health, benefits, printers } = preflight
} catch (err) {
  // 预检失败，根据错误类型处理（见第 7 节）
}
```

**预检执行流程**：

```
preflight.run()
  ├─ health.check()                   ← 纯健康检查，不自动唤起
  │    ├─ 成功 → 继续
  │    └─ 失败 → 抛 TopBridgeConnectionError / TopBridgeAuthError
  ├─ benefits.check()                 ← 权益验证
  │    ├─ 有效 → 继续
  │    └─ 无效 → 抛 TopBridgeQuotaError
  └─ printers.list()                  ← 获取打印机
       ├─ 有打印机 → 返回 PreflightResult
       └─ 无打印机 → 抛 TopBridgePrinterError
```

### 5.2 第二步：获取模板

预检通过后，获取可用的标签模板：

```typescript
const templatesResult = await client.templates.list()

// templatesResult.data:
// {
//   count: 2,
//   templates: [
//     { id: '1', code: 'PRICE_LABEL', name: 'Price Label 40x30', isEnabled: true },
//     { id: '2', code: 'SHIPPING_LABEL', name: 'Shipping Label 100x150', isEnabled: true }
//   ]
// }
```

可选：获取模板的详细字段定义，了解需要提供哪些数据：

```typescript
const schema = await client.templates.schema('PRICE_LABEL')

// schema.data:
// {
//   templateId: 'template-id-1',
//   code: 'PRICE_LABEL',
//   name: '价格标签',
//   fields: [
//     { name: 'name', type: 'text', required: true },
//     { name: 'price', type: 'price', required: true, subFields: [...] },
//     { name: 'barcode', type: 'barcode', required: false },
//     { name: 'copies', type: 'integer', required: false, default: 1 }
//   ]
// }
```

> `templates.schema()` 是显式调用，`print.execute()` 不会自动调用它。你可以在需要动态构建打印表单时使用它。

### 5.3 第三步：执行打印

使用预检获得的打印机和模板信息，构建打印请求：

```typescript
const result = await client.print.execute({
  template: 'PRICE_LABEL',
  printer: preflight.printers.data.defaultPrinter,
  products: [
    { name: 'Apple', price: 3.99, currency: '$', unit: '/kg', copies: 2 },
    { name: 'Banana', price: 1.99, currency: '$', copies: 1 },
  ],
  fieldTypes: { price: 'price' },
})

// result:
// {
//   status: 'ok',
//   message: 'Printed successfully',
//   data: {
//     printedCopies: 3,
//     jobId: 'job-123',
//     templateName: 'Price Label 40x30'
//   }
// }
```

**关键点**：

- `products` 是扁平的 JSON 对象，SDK 自动根据 `fieldTypes` 转换为 Tray App 所需的嵌套结构
- `template` 可以传模板 ID（`'1'`）或 Code（`'PRICE_LABEL'`）
- `printer` 传打印机名称字符串
- `copies` 默认为 1，范围 [1, 9999]

### 5.4 完整示例

以下是一个可以在浏览器中直接运行的完整示例：

```typescript
import {
  TopBridgeClient,
  TopBridgeConnectionError,
  TopBridgeAuthError,
  TopBridgeQuotaError,
  TopBridgePrinterError,
  TopBridgePrintError,
} from '@appzgatenz/label-print-topbridge-js'

const client = new TopBridgeClient({ debug: true })

async function printPriceLabels() {
  try {
    // 1. 确保 Tray App 运行 + 预检
    const preflight = await client.launch.ensureRunning(
      () => client.preflight.run({
        onStepChange: (step) => console.log(`检查: ${step}`)
      }),
      { onLaunching: () => console.log('正在启动 TopBridge...') }
    )

    // 2. 执行打印
    const result = await client.print.execute({
      template: 'PRICE_LABEL',
      printer: preflight.printers.data.defaultPrinter,
      products: [
        { name: 'Apple', price: 3.99, currency: '$', unit: '/kg', copies: 2 },
        { name: 'Banana', price: 1.99, currency: '$', copies: 1 },
      ],
      fieldTypes: { price: 'price' },
    })

    console.log(`打印成功: ${result.data.printedCopies} 份`)

  } catch (err) {
    if (err instanceof TopBridgeConnectionError) {
      console.error('无法连接到 TopBridge，请确认桌面应用已启动')
    } else if (err instanceof TopBridgeAuthError) {
      if (err.code === 'UPDATE_REQUIRED') {
        console.error('TopBridge 版本过低，请更新')
        const updateUrl = err.storeUrl ?? err.downloadUrl
        if (updateUrl) window.open(updateUrl)
      } else {
        console.error('请先登录 TopBridge 桌面应用')
      }
    } else if (err instanceof TopBridgeQuotaError) {
      console.error('打印配额不足:', err.reason)
    } else if (err instanceof TopBridgePrinterError) {
      console.error('打印机错误，请在 TopBridge 中检查打印机配置')
    } else if (err instanceof TopBridgePrintError) {
      console.error('打印失败:', err.message)
    } else {
      console.error('未知错误:', err)
    }
  }
}

printPriceLabels()
```

## 6. 数据转换（fieldTypes）

SDK 的核心能力之一是将你提供的**扁平产品数据**自动转换为 Tray App 所需的**嵌套结构**。通过 `fieldTypes` 配置告诉 SDK 如何转换。

### 6.1 转换规则

| fieldTypes 值 | 输入 | 输出 |
|---------------|------|------|
| `'price'` | `price: 3.99, currency: '$', unit: '/kg'` | `price: { value: 3.99, currency: '$', unit: '/kg' }` |
| `'weight'` | `weight: 0.5, unit: 'kg'` | `weight: { value: 0.5, unit: 'kg' }` |
| `'barcode'` | `barcode: 12345` | `barcode: '12345'`（强制转为字符串） |
| `'qrcode'` | `qrcode: 'https://...'` | `qrcode: 'https://...'` |
| `'text'` 或不声明 | `name: 'Apple'` | `name: 'Apple'`（保持原值） |

> **Text Widget 换行符处理**：TSPL 协议按行解析指令，text 字段值中的换行符（`\n`、`\r`、`\r\n`）会破坏 TSPL 指令结构导致打印失败。
>
> 当 `fieldTypes` 中显式声明为 `'text'` 的字段值包含换行符时，SDK 会自动截取第一行内容，并在响应的 `warnings` 数组中通知调用者。仅处理 `fieldTypes` 中显式声明为 `'text'` 的字段，未提供 `fieldTypes`（隐式 text mode）或使用 `rawProducts` 时不会触发此处理。

### 6.2 简单模式（字符串）

最常用的方式。SDK 自动关联内置约定的子字段：

- `price` 类型自动关联 `currency` 和 `unit`
- `weight` 类型自动关联 `unit`

```typescript
{
  products: [
    { name: 'Apple', price: 3.99, currency: '$', unit: '/kg', weight: 0.5 },
  ],
  fieldTypes: { price: 'price', weight: 'weight' }
}
// SDK 输出:
// { name: 'Apple', price: { value: 3.99, currency: '$', unit: '/kg' }, weight: { value: 0.5 } }
```

### 6.3 显式模式（对象）

当有多个同类型字段或子字段命名不标准时，使用对象形式指定自定义子字段名：

> **子字段映射规则**：`subFields` 按顺序映射到目标属性。对于 `price` 类型，第一个子字段对应 `currency`，第二个对应 `unit`；对于 `weight` 类型，第一个子字段对应 `unit`。

```typescript
{
  products: [
    { productName: 'Apple', basePrice: 3.99, priceCurrency: '$', priceUnit: '/kg' },
  ],
  fieldTypes: {
    basePrice: { type: 'price', subFields: ['priceCurrency', 'priceUnit'] },
  }
}
// SDK 输出:
// { productName: 'Apple', basePrice: { value: 3.99, currency: '$', unit: '/kg' } }
```

### 6.4 无 fieldTypes（Text 模式）

不提供 `fieldTypes` 时，所有字段以原始值直传（text 模式）：

```typescript
{
  products: [
    { name: 'Apple', barcode: '12345' },
  ]
  // 无 fieldTypes
}
// SDK 输出:
// { name: 'Apple', barcode: '12345' }
```

### 6.5 Raw 模式（rawProducts）

如果需要完全控制发送给 Tray App 的数据结构，可以使用 `rawProducts` 跳过所有转换：

```typescript
await client.print.execute({
  template: 'PRICE_LABEL',
  printer: 'TSC DA220',
  rawProducts: [
    {
      name: 'Apple',
      price: { value: 3.99, currency: '$', unit: '/kg' },
      barcode: '9300645123456',
      copies: 2
    }
  ]
})
```

> **注意**：`rawProducts` 和 `products` 互斥，不能同时使用。`rawProducts` 必须是非空数组。

### 6.6 copies 规则

| 规则 | 说明 |
|------|------|
| 范围 | [1, 9999]，超出范围自动截断 |
| 默认值 | 1（值为默认值时不包含在输出中） |
| 无效值 | 非数字、null、NaN 等自动回退到 1 |
| 小数 | 自动取整（Math.round） |

## 7. 错误处理

### 7.1 错误类层次

所有 SDK 错误继承自 `TopBridgeError` 基类：

```
TopBridgeError (基类)
├── TopBridgeConnectionError     连接失败 / 超时 / Tray App 未运行
├── TopBridgeAuthError           认证或版本问题
│     .code: 'NOT_AUTHENTICATED' | 'UPDATE_REQUIRED'
│     .storeUrl?: string         更新链接（仅 UPDATE_REQUIRED）
│     .downloadUrl?: string      下载链接（仅 UPDATE_REQUIRED）
├── TopBridgeQuotaError          权益无效 / 配额耗尽
│     .reason?: string           具体原因
├── TopBridgePrintError          打印失败（未命中特定错误码时）
│     .details?: unknown         错误详情
├── TopBridgeConfigError         配置错误
├── TopBridgeValidationError     输入校验失败
│     .field?: string            出错的字段名
├── TopBridgePrinterError        打印机离线 / 未配置协议
├── TopBridgeTemplateError       模板不存在或无权限
├── TopBridgeNetworkError        云端网络断开
└── TopBridgeSourceError         source 缺失或不在白名单
```

### 7.2 使用 instanceof 进行类型安全处理

所有错误类支持 `instanceof` 检查，TypeScript 会自动窄化类型：

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
  TopBridgeValidationError,
} from '@appzgatenz/label-print-topbridge-js'

try {
  await client.print.execute({ /* ... */ })
} catch (err) {
  if (err instanceof TopBridgeConnectionError) {
    // Tray App 未运行或网络不通
  }
  else if (err instanceof TopBridgeAuthError) {
    if (err.code === 'NOT_AUTHENTICATED') {
      // 用户未登录
    }
    if (err.code === 'UPDATE_REQUIRED') {
      // Tray App 版本过低
      if (err.storeUrl) window.open(err.storeUrl)
    }
  }
  else if (err instanceof TopBridgeQuotaError) {
    // 权益无效或配额耗尽
  }
  else if (err instanceof TopBridgePrinterError) {
    // 打印机离线或未配置协议
  }
  else if (err instanceof TopBridgeTemplateError) {
    // 模板不存在或无权限
  }
  else if (err instanceof TopBridgeNetworkError) {
    // Tray App 在线，但云端网络断开
  }
  else if (err instanceof TopBridgeSourceError) {
    // source 不在白名单
  }
  else if (err instanceof TopBridgeValidationError) {
    // 输入校验失败
  }
  else if (err instanceof TopBridgePrintError) {
    // 其他打印失败
  }
}
```

### 7.3 错误与场景对照

| 场景 | 错误类型 | 处理建议 |
|------|---------|---------|
| Tray App 未安装/未运行 | `TopBridgeConnectionError` | 使用 `client.launch.ensureRunning()` 自动唤起重试 |
| 用户未登录 | `TopBridgeAuthError(NOT_AUTHENTICATED)` | 引导用户登录 TopBridge |
| Tray App 版本过低 | `TopBridgeAuthError(UPDATE_REQUIRED)` | 使用 `err.storeUrl` 引导更新 |
| 打印配额耗尽 | `TopBridgeQuotaError` | 展示 `err.reason`，引导续费 |
| 打印机离线 | `TopBridgePrinterError` | 检查打印机连接和协议配置 |
| 模板不存在 | `TopBridgeTemplateError` | 检查模板 ID/Code 是否正确 |
| 云端网络断开 | `TopBridgeNetworkError` | 检查网络连接 |
| products 为空 | `TopBridgeValidationError` | `err.field` 指明问题字段 |
| 打印失败（其他） | `TopBridgePrintError` | 查看 `err.details` 获取详情 |

## 8. Tray App 唤起（LaunchModule）

`launch` 模块负责 Tray App 的唤起和连接重试编排。

### 8.1 trigger()

触发 Tray App 启动。通过隐藏 iframe 加载 `topsale://callback` 自定义协议。该方法为即发即忘（fire-and-forget），不返回 Promise。

```typescript
client.launch.trigger()
```

适用场景：
- 你想手动控制唤起时机
- 在检测到 Tray App 未运行时主动唤起
- 自定义重试逻辑

### 8.2 ensureRunning(fn, options?)

确保 Tray App 在运行后执行指定操作。封装了完整的唤起 → 等待 → 重试流程。

```typescript
const result = await client.launch.ensureRunning(
  () => client.health.check(),
  { onLaunching: () => showLaunchingUI() }
)
```

**执行流程**：

```
ensureRunning(fn)
  ├─ fn() 成功 → 返回结果
  ├─ fn() 非 ConnectionError → 直接抛出
  └─ fn() ConnectionError
       ├─ options.onLaunching() 回调
       ├─ trigger() 唤起 Tray App
       ├─ 等待 3 秒
       ├─ fn() 重试 → 成功 → 返回结果
       ├─ fn() 重试 → 非 ConnectionError → 抛出
       └─ fn() 重试 → ConnectionError
            ├─ 等待 2 秒
            ├─ fn() 最终重试（1 次）
            └─ 全部失败 → 抛 TopBridgeConnectionError
```

**常见用法**：

```typescript
// 包装预检（最常见）
const { printers } = await client.launch.ensureRunning(
  () => client.preflight.run(),
  { onLaunching: () => console.log('正在启动...') }
)

// 包装健康检查
const health = await client.launch.ensureRunning(
  () => client.health.check()
)

// 包装任意操作
const result = await client.launch.ensureRunning(
  async () => {
    const h = await client.health.check()
    if (!h.data.isLoggedIn) throw new Error('Not logged in')
    return h
  }
)
```

## 9. 调试与日志

### 9.1 快速调试

开发环境设置 `debug: true` 即可在浏览器控制台查看所有 SDK 通信日志：

```typescript
const client = new TopBridgeClient({ debug: true })
```

日志格式：`[TopBridge] [模块名] 消息内容`

### 9.2 自定义 Logger

将 SDK 日志接入监控系统（Sentry / Datadog 等）：

```typescript
import type { Logger } from '@appzgatenz/label-print-topbridge-js'

const logger: Logger = {
  debug: (...args) => { /* 开发环境输出 */ },
  info: (...args) => { /* 记录信息 */ },
  warn: (...args) => { /* 记录警告 */ },
  error: (...args) => Sentry.captureException(args[0]),
}

const client = new TopBridgeClient({ logger })
```

### 9.3 生产环境建议

- **不设置 `debug: true`** — 生产环境默认关闭所有日志
- **使用自定义 logger** — 仅将 error 级别日志发送到监控系统，避免泄露通信细节
- **不要在用户可见的 UI 中展示原始错误消息** — 使用第 7.3 节的对照表将错误转换为用户友好的提示

## 10. 故障排查

### Q: 调用 API 时抛出 TopBridgeConnectionError

**原因**：无法连接到 TopBridge Tray App。SDK 固定连接 `ws://localhost:8765`（内部自动拼接 `/v2`）。

**排查步骤**：
1. 确认 TopBridge 桌面应用已安装并正在运行
2. 检查应用是否被防火墙阻止
3. 确认应用版本 >= 1.0.30（支持 V2 API）
4. 使用 `client.launch.ensureRunning()` 自动处理 Tray App 唤起和重试

### Q: 抛出 TopBridgeAuthError(code: 'NOT_AUTHENTICATED')

**原因**：TopBridge 在运行但用户未登录。

**处理**：引导用户打开 TopBridge 桌面应用完成登录，然后重试。

### Q: 抛出 TopBridgeAuthError(code: 'UPDATE_REQUIRED')

**原因**：用户安装的 TopBridge 版本低于最低要求。

**处理**：使用 `err.storeUrl`（Microsoft Store）或 `err.downloadUrl`（直接下载）引导用户更新。

### Q: 打印数据中 price 字段没有正确转换

**原因**：可能缺少 `fieldTypes` 配置。

**排查**：
- 确认 `fieldTypes: { price: 'price' }` 已正确设置
- 简单模式下，SDK 自动关联 `currency` 和 `unit` 子字段，确保产品数据中包含这些字段
- 如果子字段命名不标准，使用显式模式：`{ type: 'price', subFields: ['myCurrency', 'myUnit'] }`

### Q: TopBridgeQuotaError 但用户确认配额充足

**排查**：
- 检查 `benefits.data.expiresAt` 是否已过期
- 检查 `benefits.data.hasPrintBenefit` 是否为 `true`
- `err.reason` 包含具体原因

### Q: 抛出 TopBridgePrinterError 但用户确认打印机已连接

**原因**：TopBridge 要求打印机配置了通信协议（TSPL / ZPL），仅连接不够。

**排查**：
1. 确认打印机在 TopBridge 中已同步
2. 确认已为打印机配置 TSPL 或 ZPL 协议
3. 未配置协议的打印机不会出现在 `printers.list()` 的结果中

### Q: 在 Next.js SSR 中使用报错

**原因**：SDK 依赖浏览器原生 `WebSocket` API，在 Node.js 服务端不存在。

**解决方案**：确保仅在客户端调用 SDK。使用动态导入：

```typescript
// Next.js 页面组件中
useEffect(() => {
  import('@appzgatenz/label-print-topbridge-js').then(({ TopBridgeClient }) => {
    const client = new TopBridgeClient()
    // ... 在这里使用 client
  })
}, [])
```

或使用 `'use client'` 指令确保组件仅在客户端渲染。

### Q: 打印成功但响应中包含 warnings

**原因**：SDK 在数据转换过程中检测到非致命的格式问题并自动处理，打印仍然正常执行。

**当前 warning 类型**：

| code | reason | 触发条件 |
|------|--------|---------|
| `DATA_FORMAT` | `newline_truncated` | `fieldTypes` 中声明为 `'text'` 的字段值包含换行符，SDK 已自动截取第一行 |

**处理建议**：
```typescript
const result = await client.print.execute({ /* ... */ })
if (result.warnings?.length) {
  for (const w of result.warnings) {
    if (w.code === 'DATA_FORMAT' && w.reason === 'newline_truncated') {
      console.warn(`数据格式提示: ${w.message}`)
    }
  }
}
```

## 11. API 速查表

### 11.1 模块方法一览

| 模块 | 方法 | 返回类型 | 说明 |
|------|------|---------|------|
| `health` | `check()` | `Promise<HealthResponse>` | 健康检查 |
| `benefits` | `check()` | `Promise<BenefitsResponse>` | 权益验证 |
| `printers` | `list()` | `Promise<PrintersResponse>` | 打印机列表 |
| `templates` | `list()` | `Promise<TemplatesListResponse>` | 模板列表 |
| `templates` | `schema(template)` | `Promise<TemplateSchemaResponse>` | 模板字段定义 |
| `print` | `execute(request)` | `Promise<PrintResponse>` | 执行打印 |
| `preflight` | `run(options?)` | `Promise<PreflightResult>` | 预检编排 |
| `launch` | `trigger()` | `void` | 触发 Tray App 唤起 |
| `launch` | `ensureRunning(fn, options?)` | `Promise<T>` | 唤起 + 重试编排 |

### 11.2 响应类型一览

| 类型 | 关键字段 |
|------|---------|
| `HealthResponse` | `type: 'pong'`, `isRunning: true`, `data.isLoggedIn`, `data.version`(可选), `data.networkStatus`(可选) |
| `BenefitsResponse` | `data.isValid`, `data.remainingPrints`, `data.expiresAt`, `data.reason`, `data.hasPrintBenefit`, `data.hasSessionBenefit` |
| `PrintersResponse` | `data.count`, `data.defaultPrinter`, `data.printers[]` |
| `TemplatesListResponse` | `data.count`, `data.templates[]` |
| `TemplateSchemaResponse` | `data.fields[]`, `data.code`, `data.name` |
| `PrintResponse` | `message`(顶层), `data.printedCopies`, `data.jobId`, `data.templateName`, `data.userId`(可选), `details`(可选), `warnings`(可选) |
| `PreflightResult` | `health`, `benefits`, `printers` |

### 11.3 导出清单

```typescript
// 类
import { TopBridgeClient } from '@appzgatenz/label-print-topbridge-js'
import { LaunchModule } from '@appzgatenz/label-print-topbridge-js'

// 错误类（10 个）
import {
  TopBridgeError,
  TopBridgeConnectionError,
  TopBridgeAuthError,
  TopBridgeQuotaError,
  TopBridgePrintError,
  TopBridgeConfigError,
  TopBridgeValidationError,
  TopBridgePrinterError,
  TopBridgeTemplateError,
  TopBridgeNetworkError,
  TopBridgeSourceError,
} from '@appzgatenz/label-print-topbridge-js'

// 类型（按需导入）
import type {
  TopBridgeClientConfig,
  TopBridgeSource,
  Logger,
  SdkWarning,
  HealthResponse,
  HealthData,
  BenefitsResponse,
  BenefitsData,
  PrintersResponse,
  PrintersData,
  SyncedPrinter,
  TemplatesListResponse,
  TemplatesListData,
  TemplateItem,
  TemplateSchemaResponse,
  TemplateSchema,
  TemplateFieldSchema,
  PrintResponse,
  PrintData,
  PrintExecuteRequest,
  PrintProductInput,
  RawPrintProduct,
  FieldType,
  FieldTypeConfig,
  PreflightResult,
  PreflightOptions,
  PreflightStep,
  EnsureRunningOptions,
} from '@appzgatenz/label-print-topbridge-js'
```
