---
title: Security Model
---

# Security Model

## Overview

`@appzgatenz/label-print-topbridge-js` employs multiple layers of security defenses to prevent unauthorized calls and data leakage.

## 1. Fixed Local Connection

The SDK connects exclusively to `ws://localhost:8765` (internally appending `/v2`). There is no configuration option for the connection address, which fundamentally prevents redirecting the SDK to a remote server.

## 2. Source Field Allowlist

V2 `print` requests automatically inject a `source` field from an allowlist. The TopBridge Tray App maintains the full allowlist:

| Source Value | Allowed Caller |
|--------------|----------------|
| `Excel` | Self-service Web application |
| `Odoo` | Odoo ERP plugin |
| `Core-SDK` | Third-party SDK (this SDK) |
| `React-SDK` | Future React SDK |
| `Nextjs-SDK` | Future Next.js SDK |

Source values not on the allowlist are rejected by the Tray App.

This core SDK only allows configuring `Core-SDK` / `React-SDK` / `Nextjs-SDK`. `Excel` / `Odoo` are reserved by the Tray App for self-service and Odoo plugins and are not exposed through this npm package.

## 3. Build-Time Obfuscation

Production builds (`tsup`) enable the following protections:

- `minify: true` — Code minification and obfuscation
- `treeshake: true` — Remove unused code
- No source maps published (npm package does not contain `.map` files)

This increases the cost of decompiling and modifying SDK code.

## 4. URL Safety Validation

Before presenting external links (`storeUrl` / `downloadUrl`) from Tray App error responses, the SDK validates them via `isSafeUrl()`:

```typescript
// Only the following protocols are allowed
'https://' ✅
'ms-windows-store://' ✅
'http://' ❌
'javascript:' ❌
'data:' ❌
```

## 5. Input Sanitization

The `coerceToString()` function automatically strips formula injection prefixes (`=` and `=@`) to prevent injection via print data.

## Known Limitations

| Limitation | Description | Mitigation |
|------------|-------------|------------|
| Client-side validation can be bypassed | Modifying SDK source can remove connection restrictions | Build obfuscation increases cost + Tray App-side restrictions |
| Browser cannot prevent page spoofing | Malicious pages can implement the WS protocol themselves | Tray App source allowlist + server-side validation |
| WS protocol is unencrypted | localhost communication is not encrypted by default | Local communication does not require encryption (no network transmission risk) |
