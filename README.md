# TopBridge SDK Platform

[![npm](https://img.shields.io/npm/v/@appzgatenz/label-print-topbridge-js)](https://www.npmjs.com/package/@appzgatenz/label-print-topbridge-js)

Documentation and interactive examples for the **TopBridge** label printing SDK platform. Built with [VitePress](https://vitepress.dev).

## SDK Types

| SDK | Status | Description |
|-----|--------|-------------|
| **JS Core** | ✅ Available | Framework-agnostic SDK for browser environments |
| **Next.js** | 🔜 Coming Soon | Optimized integration for Next.js applications |
| **React** | 🔜 Coming Soon | Hooks-based SDK for React applications |

The site includes a **SDK type switcher** in the navigation bar. JS Core shows full documentation and examples; Next.js and React display a Coming Soon page.

## Quick Start (JS Core)

### Installation

```bash
npm install @appzgatenz/label-print-topbridge-js
```

### Usage

```ts
import { TopBridgeClient } from '@appzgatenz/label-print-topbridge-js'

const client = new TopBridgeClient({ debug: true })

// Ensure the Tray App is running and run preflight checks
const preflight = await client.launch.ensureRunning(
  () => client.preflight.run()
)

// Print a label
await client.print.execute({
  template: 'PRICE_LABEL',
  printer: preflight.printers.data.defaultPrinter,
  products: [
    { name: 'Example', price: 9.99, currency: '$', copies: 1 },
  ],
  fieldTypes: { price: 'price' },
})
```

See the [full documentation](https://github.com/youngming/label-print-topbridge-js-SDK-demo) for complete API reference.

## Local Development

```bash
pnpm install
pnpm dev
```

Open `http://localhost:5173` in your browser.

## Build

```bash
pnpm build
```

Static output goes to `.vitepress/dist`.

## Deploy

```bash
pnpm deploy           # Deploy to Cloudflare Pages
pnpm deploy:dry       # Pre-check only
```

## Project Structure

```
├── .vitepress/
│   ├── config.ts          # VitePress configuration
│   └── theme/             # Custom theme (SDK switcher, homepage)
├── guide/                 # English documentation
├── examples/              # Example pages
├── public/demos/          # Standalone HTML demos
├── zh/                    # Chinese documentation (mirrors English)
└── scripts/deploy.sh      # Cloudflare Pages deploy script
```

## Links

- [GitHub](https://github.com/youngming/label-print-topbridge-js-SDK-demo)
- [NPM Package](https://www.npmjs.com/package/@appzgatenz/label-print-topbridge-js)
- [SDK Source](https://github.com/topsale/label-print-topbridge-js)

## License

Private — All rights reserved.
