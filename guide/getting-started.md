---
title: Installation & Setup
---

# Getting Started

## Installation

```bash
npm install @appzgatenz/label-print-topbridge-js
```

## Prerequisites

- TopBridge desktop app is installed and running locally
- Browser supports WebSocket (all modern browsers)
- If using `launch.trigger()`, page CSP must allow `topsale:` custom protocol (`frame-src topsale:`)
- TopBridge Tray App supports WebSocket API V2 (unified endpoint `/v2`)

## Initialization

```typescript
import { TopBridgeClient } from '@appzgatenz/label-print-topbridge-js'

const client = new TopBridgeClient()
```

The SDK connects to `ws://localhost:8765` (internally appends `/v2`) with no configuration required.

## Complete Print Workflow

```typescript
// 0. Optional: ensure Tray App is running
const { printers } = await client.launch.ensureRunning(
  () => client.preflight.run({
    onStepChange: (step) => console.log(`Checking ${step}...`)
  })
)

// Or run preflight directly (without auto-launching Tray App)
// const { printers } = await client.preflight.run()

// 1. Get available templates
const templates = await client.templates.list()

// 2. Optional: get template field definitions
const schema = await client.templates.schema('PRICE_LABEL')

// 3. Execute print
const result = await client.print.execute({
  template: 'PRICE_LABEL',       // Template ID or Code
  printer: 'TSC DA220',          // Printer name
  products: [
    { name: 'Apple', price: 3.99, currency: '$', unit: '/kg', copies: 2 },
    { name: 'Banana', price: 1.99, currency: '$', copies: 1 },
  ],
  fieldTypes: { price: 'price' }, // Mark price as a structured field
})

console.log(`Printed ${result.data.printedCopies} copies`)
```

## Configuration Options

```typescript
const client = new TopBridgeClient({
  debug: true,                     // Enable logging
  timeouts: {
    health: 3000,                  // Health check timeout (ms)
    preflight: 10000,              // Preflight timeout (ms)
    print: 60000,                  // Print timeout (ms)
  },
})
```

## Error Handling

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
    // Tray App is not running or connection timed out
  } else if (err instanceof TopBridgeAuthError) {
    // Not logged in or update required
    if (err.code === 'UPDATE_REQUIRED') {
      window.open(err.storeUrl) // Guide user to update
    }
  } else if (err instanceof TopBridgeQuotaError) {
    // Benefit invalid or quota exhausted
  } else if (err instanceof TopBridgePrinterError) {
    // Printer offline or protocol not configured
  } else if (err instanceof TopBridgeTemplateError) {
    // Template does not exist or no permission
  } else if (err instanceof TopBridgeNetworkError) {
    // Tray App is online, but cloud network is disconnected
  } else if (err instanceof TopBridgeSourceError) {
    // Source is not in the allowlist
  } else if (err instanceof TopBridgePrintError) {
    // Print failed
  }
}
```

## fieldTypes Configuration

`fieldTypes` tells the SDK which fields need structured conversion (price → `{value, currency, unit}`).

### Simple Mode (string)

Built-in convention: `price` automatically associates `currency` and `unit` sub-fields.

```typescript
fieldTypes: { price: 'price', weight: 'weight' }
```

### Explicit Mode (object)

When there are multiple fields of the same type or sub-field names are non-standard:

```typescript
fieldTypes: {
  price: { type: 'price', subFields: ['priceCurrency', 'priceUnit'] },
  weight: { type: 'weight', subFields: ['weightUnit'] },
}
```

### Without fieldTypes

When `fieldTypes` is not provided, all fields are sent in raw format (text mode).
