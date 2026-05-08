---
title: Developer Guide
---

# Developer Guide

> Version: 0.2.x | Integration guide for third-party developers

## 1. Overview

### 1.1 What is TopBridge

TopBridge is a desktop application running on the user's local machine (referred to as the "Tray App" in this document). It manages label printers, templates, and user entitlements. It exposes APIs via the WebSocket protocol locally, allowing browser applications to send print commands.

### 1.2 What Problems Does the SDK Solve

`@appzgatenz/label-print-topbridge-js` is a Headless (no UI) browser SDK that encapsulates all communication details with the TopBridge Tray App:

- **WebSocket Connection Management** — Short-connection model: auto connect, send, receive, and close for each call
- **Tray App Launch & Retry** — Launch orchestration via the `launch` module with automatic retry logic
- **Data Transformation** — Automatically converts flat product data into the nested structure required by the Tray App
- **Structured Errors** — 10 error types, all supporting `instanceof` narrowing
- **Preflight Orchestration** — One-liner to complete "health check → entitlement validation → printer discovery"

The SDK is not bound to any UI framework and can be used in React / Vue / Svelte / vanilla JS.

### 1.3 Architecture Overview

```
Your Browser Application
    │
    ▼
TopBridgeClient (SDK Entry)
    ├── health        Health check
    ├── benefits      Entitlement & quota validation
    ├── printers      Printer list
    ├── templates     Template list + field definitions
    ├── print         Print execution (with data conversion)
    ├── preflight     Orchestration: health → benefits → printers
    └── launch        Tray App launch + retry orchestration
    │
    ▼  WebSocket (fixed ws://localhost:8765/v2)
TopBridge Tray App (Local Desktop Application)
    │
    ▼
Label Printer
```

## 2. Environment Setup

### 2.1 Prerequisites

| Condition | Description |
|-----------|-------------|
| TopBridge Desktop App | User must install and run TopBridge locally (version 1.0.30+) |
| Modern Browser | Supports WebSocket + ES2020 (Chrome / Firefox / Safari / Edge) |
| Printer | At least one label printer with a configured protocol (TSPL / ZPL) |

### 2.2 CSP Configuration

If using the launch feature (`client.launch.trigger()` or `client.launch.ensureRunning()`), the page CSP must allow the `topsale:` custom protocol:

```
Content-Security-Policy: frame-src 'self' topsale:
```

### 2.3 What is TopBridge Tray App

The Tray App is a desktop application running on the user's computer. Its responsibilities include:

- Managing printer connections and protocol configuration
- Managing user login status and print entitlements
- Rendering templates and driving printer output
- Exposing WebSocket APIs via `ws://localhost:8765/v2`

The SDK does not communicate directly with printers; all operations go through the Tray App.

> **Download**: The TopBridge desktop app must be installed by the user. If your users haven't installed it yet, please contact the TopBridge team for the installer or download link.

## 3. Installation & Initialization

### 3.1 Installation

```bash
npm install @appzgatenz/label-print-topbridge-js
```

Zero runtime dependencies. Ready to use after installation.

### 3.2 Creating a Client

```typescript
import { TopBridgeClient } from '@appzgatenz/label-print-topbridge-js'

const client = new TopBridgeClient()
```

Zero configuration required — the SDK connects to `ws://localhost:8765` (internally appending `/v2`). No manual connection address configuration is needed.

### 3.3 Configuration Options

```typescript
const client = new TopBridgeClient({
  debug: false,                    // Enable console logging
  logger: customLogger,            // Custom logger implementation
  timeouts: {
    health: 3000,                  // Health check timeout (ms)
    preflight: 10000,              // Preflight timeout (ms)
    print: 60000,                  // Print timeout (ms)
  },
})
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `debug` | `boolean` | `false` | Quick toggle for console logging |
| `logger` | `Logger` | `null` | Custom logger implementation |
| `timeouts.health` | `number` | `3000` | Health check timeout (ms) |
| `timeouts.preflight` | `number` | `10000` | Preflight timeout (ms) |
| `timeouts.print` | `number` | `60000` | Print timeout (ms) |

**Custom Logger**:

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

`debug: true` is equivalent to using `console` as the logger (all logs prefixed with `[TopBridge]`).

## 4. Core Concepts

### 4.1 Modular Architecture

`TopBridgeClient` contains 7 functional modules, each responsible for an independent business domain:

| Module | Responsibility | Primary Methods |
|--------|----------------|-----------------|
| `health` | Check Tray App running status | `check()` |
| `benefits` | Validate user print entitlements and quota | `check()` |
| `printers` | Get configured printer list | `list()` |
| `templates` | Get template list and field definitions | `list()`, `schema()` |
| `print` | Execute print jobs | `execute()` |
| `preflight` | Orchestrate the full preflight check | `run()` |
| `launch` | Tray App launch & retry orchestration | `trigger()`, `ensureRunning()` |

### 4.2 Short-Connection Model

The SDK uses short WebSocket connections: each API call independently creates a WebSocket connection, sends the request, receives the response, and then closes. You do not need to manually manage the connection lifecycle.

```
client.print.execute(...)
  → Connect to ws://localhost:8765/v2
  → Send { action: "print", payload: {...} }
  → Receive response
  → Close connection
  → Return PrintResponse
```

### 4.3 Response Structure

All SDK methods return a unified response envelope:

```typescript
interface SdkResponse<T> {
  status: 'ok' | 'warning'    // Request result status
  requestId?: string           // Request trace ID
  data: T                      // Business data
  warnings?: SdkWarning[]      // Data format warnings (optional)
}
```

- `status: 'ok'` — Request succeeded, `data` contains business data
- `status: 'warning'` — Request succeeded with additional hints (e.g., network disconnected during health check). You can use `data` normally, and check `message` for details
- `warnings` — Non-fatal data format hint array. The SDK adds these when potential issues are found during data conversion, without blocking print execution

**SdkWarning Structure**:

```typescript
interface SdkWarning {
  code: string      // Category identifier, e.g., 'DATA_FORMAT'
  reason: string    // Precise identifier, e.g., 'newline_truncated'
  message: string   // Human-readable description
}
```

## 5. Complete Integration Tutorial

This section walks through an end-to-end example, demonstrating how to integrate label printing from scratch.

### 5.1 Step 1: Ensure Tray App is Running + Preflight

Before printing, confirm three things: the Tray App is running and the user is logged in, entitlements are valid, and printers are available. `preflight.run()` completes these checks in one go.

> `preflight` is the recommended best practice but not mandatory — you can also call `print.execute()` directly. The Tray App still performs authentication and entitlement checks. However, using preflight allows you to discover and handle issues before printing, providing a better user experience.
>
> Note: `preflight.run()` does not automatically launch the Tray App. For auto-launch, wrap it with `client.launch.ensureRunning()`.

```typescript
try {
  // Use ensureRunning wrapper for automatic Tray App launch and retry
  const preflight = await client.launch.ensureRunning(
    () => client.preflight.run({
      onStepChange: (step) => {
        console.log(`Checking: ${step}`)  // health → benefits → printers
      }
    }),
    { onLaunching: () => console.log('Launching TopBridge...') }
  )

  const { health, benefits, printers } = preflight
} catch (err) {
  // Preflight failed, handle according to error type (see Section 7)
}
```

**Preflight Execution Flow**:

```
preflight.run()
  ├─ health.check()                   ← Pure health check, no auto-launch
  │    ├─ Success → Continue
  │    └─ Failure → Throw TopBridgeConnectionError / TopBridgeAuthError
  ├─ benefits.check()                 ← Entitlement validation
  │    ├─ Valid → Continue
  │    └─ Invalid → Throw TopBridgeQuotaError
  └─ printers.list()                  ← Get printers
       ├─ Has printers → Return PreflightResult
       └─ No printers → Throw TopBridgePrinterError
```

### 5.2 Step 2: Get Templates

After preflight passes, get available label templates:

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

Optional: get detailed field definitions for a template to understand what data is required:

```typescript
const schema = await client.templates.schema('PRICE_LABEL')

// schema.data:
// {
//   templateId: 'template-id-1',
//   code: 'PRICE_LABEL',
//   name: 'Price Label',
//   fields: [
//     { name: 'name', type: 'text', required: true },
//     { name: 'price', type: 'price', required: true, subFields: [...] },
//     { name: 'barcode', type: 'barcode', required: false },
//     { name: 'copies', type: 'integer', required: false, default: 1 }
//   ]
// }
```

> `templates.schema()` is an explicit call; `print.execute()` does not automatically call it. Use it when you need to dynamically build print forms.

### 5.3 Step 3: Execute Print

Use the printer and template information from preflight to build the print request:

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

**Key Points**:

- `products` is a flat JSON object; the SDK automatically converts it to the nested structure required by the Tray App based on `fieldTypes`
- `template` accepts a template ID (`'1'`) or Code (`'PRICE_LABEL'`)
- `printer` is a printer name string
- `copies` defaults to 1, range [1, 9999]

### 5.4 Complete Example

Here is a complete example that can run directly in the browser:

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
    // 1. Ensure Tray App is running + preflight
    const preflight = await client.launch.ensureRunning(
      () => client.preflight.run({
        onStepChange: (step) => console.log(`Checking: ${step}`)
      }),
      { onLaunching: () => console.log('Launching TopBridge...') }
    )

    // 2. Execute print
    const result = await client.print.execute({
      template: 'PRICE_LABEL',
      printer: preflight.printers.data.defaultPrinter,
      products: [
        { name: 'Apple', price: 3.99, currency: '$', unit: '/kg', copies: 2 },
        { name: 'Banana', price: 1.99, currency: '$', copies: 1 },
      ],
      fieldTypes: { price: 'price' },
    })

    console.log(`Print success: ${result.data.printedCopies} copies`)

  } catch (err) {
    if (err instanceof TopBridgeConnectionError) {
      console.error('Cannot connect to TopBridge, please confirm the desktop app is running')
    } else if (err instanceof TopBridgeAuthError) {
      if (err.code === 'UPDATE_REQUIRED') {
        console.error('TopBridge version is too low, please update')
        const updateUrl = err.storeUrl ?? err.downloadUrl
        if (updateUrl) window.open(updateUrl)
      } else {
        console.error('Please log in to the TopBridge desktop app first')
      }
    } else if (err instanceof TopBridgeQuotaError) {
      console.error('Print quota insufficient:', err.reason)
    } else if (err instanceof TopBridgePrinterError) {
      console.error('Printer error, please check printer configuration in TopBridge')
    } else if (err instanceof TopBridgePrintError) {
      console.error('Print failed:', err.message)
    } else {
      console.error('Unknown error:', err)
    }
  }
}

printPriceLabels()
```

## 6. Data Transformation (fieldTypes)

One of the core capabilities of the SDK is automatically converting the **flat product data** you provide into the **nested structure** required by the Tray App. Tell the SDK how to convert via `fieldTypes` configuration.

### 6.1 Conversion Rules

| fieldTypes Value | Input | Output |
|------------------|-------|--------|
| `'price'` | `price: 3.99, currency: '$', unit: '/kg'` | `price: { value: 3.99, currency: '$', unit: '/kg' }` |
| `'weight'` | `weight: 0.5, unit: 'kg'` | `weight: { value: 0.5, unit: 'kg' }` |
| `'barcode'` | `barcode: 12345` | `barcode: '12345'` (forced to string) |
| `'qrcode'` | `qrcode: 'https://...'` | `qrcode: 'https://...'` |
| `'text'` or undeclared | `name: 'Apple'` | `name: 'Apple'` (unchanged) |

> **Text Widget Newline Handling**: The TSPL protocol parses instructions line by line. Newline characters (`\n`, `\r`, `\r\n`) in text field values will break the TSPL instruction structure and cause print failures.
>
> When a field explicitly declared as `'text'` in `fieldTypes` contains newlines, the SDK automatically truncates to the first line and notifies the caller via the `warnings` array in the response. This only applies to fields explicitly declared as `'text'` in `fieldTypes`. It does not trigger when `fieldTypes` is not provided (implicit text mode) or when using `rawProducts`.

### 6.2 Simple Mode (string)

The most common usage. The SDK automatically associates built-in sub-fields:

- `price` type automatically associates `currency` and `unit`
- `weight` type automatically associates `unit`

```typescript
{
  products: [
    { name: 'Apple', price: 3.99, currency: '$', unit: '/kg', weight: 0.5 },
  ],
  fieldTypes: { price: 'price', weight: 'weight' }
}
// SDK output:
// { name: 'Apple', price: { value: 3.99, currency: '$', unit: '/kg' }, weight: { value: 0.5 } }
```

### 6.3 Explicit Mode (object)

When there are multiple fields of the same type or sub-field names are non-standard, use the object form to specify custom sub-field names:

> **Sub-field Mapping Rule**: `subFields` maps to target properties in order. For `price` type, the first sub-field maps to `currency`, the second to `unit`; for `weight` type, the first sub-field maps to `unit`.

```typescript
{
  products: [
    { productName: 'Apple', basePrice: 3.99, priceCurrency: '$', priceUnit: '/kg' },
  ],
  fieldTypes: {
    basePrice: { type: 'price', subFields: ['priceCurrency', 'priceUnit'] },
  }
}
// SDK output:
// { productName: 'Apple', basePrice: { value: 3.99, currency: '$', unit: '/kg' } }
```

### 6.4 No fieldTypes (Text Mode)

When `fieldTypes` is not provided, all fields are passed as raw values (text mode):

```typescript
{
  products: [
    { name: 'Apple', barcode: '12345' },
  ]
  // No fieldTypes
}
// SDK output:
// { name: 'Apple', barcode: '12345' }
```

### 6.5 Raw Mode (rawProducts)

If you need full control over the data structure sent to the Tray App, use `rawProducts` to skip all conversion:

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

> **Note**: `rawProducts` and `products` are mutually exclusive and cannot be used together. `rawProducts` must be a non-empty array.

### 6.6 copies Rules

| Rule | Description |
|------|-------------|
| Range | [1, 9999], values outside the range are automatically clamped |
| Default | 1 (not included in output when value equals default) |
| Invalid Values | Non-numeric, null, NaN, etc. automatically fall back to 1 |
| Decimals | Automatically rounded (Math.round) |

## 7. Error Handling

### 7.1 Error Class Hierarchy

All SDK errors inherit from the `TopBridgeError` base class:

```
TopBridgeError (Base)
├── TopBridgeConnectionError     Connection failed / timed out / Tray App not running
├── TopBridgeAuthError           Authentication or version issue
│     .code: 'NOT_AUTHENTICATED' | 'UPDATE_REQUIRED'
│     .storeUrl?: string         Update link (UPDATE_REQUIRED only)
│     .downloadUrl?: string      Download link (UPDATE_REQUIRED only)
├── TopBridgeQuotaError          Entitlement invalid / quota exhausted
│     .reason?: string           Specific reason
├── TopBridgePrintError          Print failed (when no specific error code matches)
│     .details?: unknown         Error details
├── TopBridgeConfigError         Configuration error
├── TopBridgeValidationError     Input validation failed
│     .field?: string            Field name that caused the error
├── TopBridgePrinterError        Printer offline / protocol not configured
├── TopBridgeTemplateError       Template does not exist or no permission
├── TopBridgeNetworkError        Cloud network disconnected
└── TopBridgeSourceError         Source missing or not in allowlist
```

### 7.2 Type-Safe Handling with instanceof

All error classes support `instanceof` checks. TypeScript will automatically narrow the type:

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
    // Tray App is not running or network is unreachable
  }
  else if (err instanceof TopBridgeAuthError) {
    if (err.code === 'NOT_AUTHENTICATED') {
      // User is not logged in
    }
    if (err.code === 'UPDATE_REQUIRED') {
      // Tray App version is too low
      if (err.storeUrl) window.open(err.storeUrl)
    }
  }
  else if (err instanceof TopBridgeQuotaError) {
    // Entitlement invalid or quota exhausted
  }
  else if (err instanceof TopBridgePrinterError) {
    // Printer offline or protocol not configured
  }
  else if (err instanceof TopBridgeTemplateError) {
    // Template does not exist or no permission
  }
  else if (err instanceof TopBridgeNetworkError) {
    // Tray App is online, but cloud network is disconnected
  }
  else if (err instanceof TopBridgeSourceError) {
    // Source is not in the allowlist
  }
  else if (err instanceof TopBridgeValidationError) {
    // Input validation failed
  }
  else if (err instanceof TopBridgePrintError) {
    // Other print failures
  }
}
```

### 7.3 Error-to-Scenario Mapping

| Scenario | Error Type | Suggested Handling |
|----------|------------|--------------------|
| Tray App not installed / not running | `TopBridgeConnectionError` | Use `client.launch.ensureRunning()` for auto-launch and retry |
| User not logged in | `TopBridgeAuthError(NOT_AUTHENTICATED)` | Guide user to log in to TopBridge |
| Tray App version too low | `TopBridgeAuthError(UPDATE_REQUIRED)` | Use `err.storeUrl` to guide update |
| Print quota exhausted | `TopBridgeQuotaError` | Display `err.reason`, guide to renew |
| Printer offline | `TopBridgePrinterError` | Check printer connection and protocol configuration |
| Template does not exist | `TopBridgeTemplateError` | Check if template ID/Code is correct |
| Cloud network disconnected | `TopBridgeNetworkError` | Check network connection |
| products is empty | `TopBridgeValidationError` | `err.field` indicates the problematic field |
| Print failed (other) | `TopBridgePrintError` | Check `err.details` for details |

## 8. Tray App Launch (LaunchModule)

The `launch` module is responsible for launching the Tray App and orchestrating connection retries.

### 8.1 trigger()

Triggers the Tray App launch. Loads the `topsale://callback` custom protocol via a hidden iframe. This method is fire-and-forget and does not return a Promise.

```typescript
client.launch.trigger()
```

Use cases:
- You want to manually control the launch timing
- Proactively launch when detecting the Tray App is not running
- Custom retry logic

### 8.2 ensureRunning(fn, options?)

Ensures the Tray App is running before executing the specified operation. Encapsulates the complete launch → wait → retry flow.

```typescript
const result = await client.launch.ensureRunning(
  () => client.health.check(),
  { onLaunching: () => showLaunchingUI() }
)
```

**Execution Flow**:

```
ensureRunning(fn)
  ├─ fn() succeeds → Return result
  ├─ fn() throws non-ConnectionError → Throw immediately
  └─ fn() throws ConnectionError
       ├─ options.onLaunching() callback
       ├─ trigger() launches Tray App
       ├─ Wait 3 seconds
       ├─ fn() retry → succeeds → Return result
       ├─ fn() retry → non-ConnectionError → Throw
       └─ fn() retry → ConnectionError
            ├─ Wait 2 seconds
            ├─ fn() final retry (1 time)
            └─ All failed → Throw TopBridgeConnectionError
```

**Common Usage**:

```typescript
// Wrap preflight (most common)
const { printers } = await client.launch.ensureRunning(
  () => client.preflight.run(),
  { onLaunching: () => console.log('Launching...') }
)

// Wrap health check
const health = await client.launch.ensureRunning(
  () => client.health.check()
)

// Wrap any operation
const result = await client.launch.ensureRunning(
  async () => {
    const h = await client.health.check()
    if (!h.data.isLoggedIn) throw new Error('Not logged in')
    return h
  }
)
```

## 9. Debugging & Logging

### 9.1 Quick Debug

Set `debug: true` in development to view all SDK communication logs in the browser console:

```typescript
const client = new TopBridgeClient({ debug: true })
```

Log format: `[TopBridge] [ModuleName] Message`

### 9.2 Custom Logger

Integrate SDK logs into monitoring systems (Sentry / Datadog, etc.):

```typescript
import type { Logger } from '@appzgatenz/label-print-topbridge-js'

const logger: Logger = {
  debug: (...args) => { /* dev output */ },
  info: (...args) => { /* record info */ },
  warn: (...args) => { /* record warning */ },
  error: (...args) => Sentry.captureException(args[0]),
}

const client = new TopBridgeClient({ logger })
```

### 9.3 Production Recommendations

- **Do not set `debug: true`** — Keep all logs off by default in production
- **Use a custom logger** — Send only error-level logs to monitoring systems to avoid leaking communication details
- **Do not display raw error messages in user-visible UI** — Use the mapping table in Section 7.3 to convert errors into user-friendly prompts

## 10. Troubleshooting

### Q: TopBridgeConnectionError thrown when calling API

**Cause**: Cannot connect to TopBridge Tray App. The SDK connects to `ws://localhost:8765` (internally appending `/v2`).

**Troubleshooting**:
1. Confirm TopBridge desktop app is installed and running
2. Check if the app is blocked by firewall
3. Confirm app version >= 1.0.30 (supports V2 API)
4. Use `client.launch.ensureRunning()` to automatically handle Tray App launch and retry

### Q: TopBridgeAuthError(code: 'NOT_AUTHENTICATED') thrown

**Cause**: TopBridge is running but the user is not logged in.

**Handling**: Guide the user to open the TopBridge desktop app and complete login, then retry.

### Q: TopBridgeAuthError(code: 'UPDATE_REQUIRED') thrown

**Cause**: The installed TopBridge version is below the minimum requirement.

**Handling**: Use `err.storeUrl` (Microsoft Store) or `err.downloadUrl` (direct download) to guide the user to update.

### Q: price field not converted correctly in print data

**Cause**: `fieldTypes` configuration may be missing.

**Troubleshooting**:
- Confirm `fieldTypes: { price: 'price' }` is correctly set
- In simple mode, the SDK automatically associates `currency` and `unit` sub-fields. Ensure these fields are present in the product data
- If sub-field names are non-standard, use explicit mode: `{ type: 'price', subFields: ['myCurrency', 'myUnit'] }`

### Q: TopBridgeQuotaError but user confirms quota is sufficient

**Troubleshooting**:
- Check if `benefits.data.expiresAt` has expired
- Check if `benefits.data.hasPrintBenefit` is `true`
- `err.reason` contains the specific cause

### Q: TopBridgePrinterError thrown but user confirms printer is connected

**Cause**: TopBridge requires the printer to have a communication protocol (TSPL / ZPL) configured. Simply connecting is not enough.

**Troubleshooting**:
1. Confirm the printer is synced in TopBridge
2. Confirm a TSPL or ZPL protocol has been configured for the printer
3. Printers without a configured protocol will not appear in `printers.list()` results

### Q: Error when using in Next.js SSR

**Cause**: The SDK depends on the browser-native `WebSocket` API, which does not exist in the Node.js server.

**Solution**: Ensure SDK is only called on the client side. Use dynamic imports:

```typescript
// In a Next.js page component
useEffect(() => {
  import('@appzgatenz/label-print-topbridge-js').then(({ TopBridgeClient }) => {
    const client = new TopBridgeClient()
    // ... use client here
  })
}, [])
```

Or use the `'use client'` directive to ensure the component is only rendered on the client.

### Q: Print succeeded but response contains warnings

**Cause**: The SDK detected non-fatal format issues during data conversion and automatically handled them. Printing still executed normally.

**Current warning types**:

| code | reason | Trigger Condition |
|------|--------|-------------------|
| `DATA_FORMAT` | `newline_truncated` | A field explicitly declared as `'text'` in `fieldTypes` contains newlines; SDK automatically truncated to first line |

**Handling suggestion**:
```typescript
const result = await client.print.execute({ /* ... */ })
if (result.warnings?.length) {
  for (const w of result.warnings) {
    if (w.code === 'DATA_FORMAT' && w.reason === 'newline_truncated') {
      console.warn(`Data format hint: ${w.message}`)
    }
  }
}
```

## 11. API Quick Reference

### 11.1 Module Methods

| Module | Method | Return Type | Description |
|--------|--------|-------------|-------------|
| `health` | `check()` | `Promise<HealthResponse>` | Health check |
| `benefits` | `check()` | `Promise<BenefitsResponse>` | Entitlement validation |
| `printers` | `list()` | `Promise<PrintersResponse>` | Printer list |
| `templates` | `list()` | `Promise<TemplatesListResponse>` | Template list |
| `templates` | `schema(template)` | `Promise<TemplateSchemaResponse>` | Template field definitions |
| `print` | `execute(request)` | `Promise<PrintResponse>` | Execute print |
| `preflight` | `run(options?)` | `Promise<PreflightResult>` | Preflight orchestration |
| `launch` | `trigger()` | `void` | Trigger Tray App launch |
| `launch` | `ensureRunning(fn, options?)` | `Promise<T>` | Launch + retry orchestration |

### 11.2 Response Types

| Type | Key Fields |
|------|------------|
| `HealthResponse` | `type: 'pong'`, `isRunning: true`, `data.isLoggedIn`, `data.version`(optional), `data.networkStatus`(optional) |
| `BenefitsResponse` | `data.isValid`, `data.remainingPrints`, `data.expiresAt`, `data.reason`, `data.hasPrintBenefit`, `data.hasSessionBenefit` |
| `PrintersResponse` | `data.count`, `data.defaultPrinter`, `data.printers[]` |
| `TemplatesListResponse` | `data.count`, `data.templates[]` |
| `TemplateSchemaResponse` | `data.fields[]`, `data.code`, `data.name` |
| `PrintResponse` | `message`(top-level), `data.printedCopies`, `data.jobId`, `data.templateName`, `data.userId`(optional), `details`(optional), `warnings`(optional) |
| `PreflightResult` | `health`, `benefits`, `printers` |

### 11.3 Export List

```typescript
// Classes
import { TopBridgeClient } from '@appzgatenz/label-print-topbridge-js'
import { LaunchModule } from '@appzgatenz/label-print-topbridge-js'

// Error Classes (10 total)
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

// Types (import on demand)
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
