import { defineConfig } from 'vitepress'

export default defineConfig({
  srcExclude: ['AGENTS.md', 'CLAUDE.md'],
  head: [
    ['script', {}, `
      (function() {
        window.addEventListener('message', function(e) {
          if (e.data && e.data.type === 'resize-iframe') {
            document.querySelectorAll('iframe[src^="/demos/"]').forEach(function(iframe) {
              if (iframe.contentWindow === e.source) {
                iframe.style.height = e.data.height + 'px'
              }
            })
          }
        })
      })()
    `]
  ],
  locales: {
    root: {
      label: 'English',
      lang: 'en',
      title: 'TopBridge SDK',
      description: 'Developer documentation and examples for @appzgatenz/label-print-topbridge-js',
      themeConfig: {
        nav: [
          { text: 'Guide', link: '/guide/getting-started' },
          { text: 'Examples', link: '/examples/basic' },
          { text: 'NPM Package', link: 'https://www.npmjs.com/package/@appzgatenz/label-print-topbridge-js' },
        ],
        sidebar: {
          '/guide/': [
            {
              text: 'Getting Started',
              items: [
                { text: 'Installation & Setup', link: '/guide/getting-started' },
              ],
            },
            {
              text: 'Deep Dive',
              items: [
                { text: 'Developer Guide', link: '/guide/developer-guide' },
                { text: 'Security Model', link: '/guide/security' },
              ],
            },
          ],
          '/examples/': [
            {
              text: 'Examples',
              items: [
                { text: 'Basic Printing', link: '/examples/basic' },
                { text: 'Error Handling', link: '/examples/error-handling' },
                { text: 'Template Schema', link: '/examples/template-schema' },
                { text: 'Multi-Product', link: '/examples/multi-product' },
                { text: 'Preflight Only', link: '/examples/preflight-only' },
              ],
            },
          ],
        },
      },
    },
    zh: {
      label: '简体中文',
      lang: 'zh-CN',
      title: 'TopBridge SDK',
      description: '开发者文档与示例 — @appzgatenz/label-print-topbridge-js',
      link: '/zh/',
      themeConfig: {
        nav: [
          { text: '指南', link: '/zh/guide/getting-started' },
          { text: '示例', link: '/zh/examples/basic' },
          { text: 'NPM 包', link: 'https://www.npmjs.com/package/@appzgatenz/label-print-topbridge-js' },
        ],
        sidebar: {
          '/zh/guide/': [
            {
              text: '快速开始',
              items: [
                { text: '安装与初始化', link: '/zh/guide/getting-started' },
              ],
            },
            {
              text: '深入指南',
              items: [
                { text: '开发者指南', link: '/zh/guide/developer-guide' },
                { text: '安全模型', link: '/zh/guide/security' },
              ],
            },
          ],
          '/zh/examples/': [
            {
              text: '示例',
              items: [
                { text: '基础打印', link: '/zh/examples/basic' },
                { text: '错误处理', link: '/zh/examples/error-handling' },
                { text: '模板查询', link: '/zh/examples/template-schema' },
                { text: '批量打印', link: '/zh/examples/multi-product' },
                { text: '仅预检', link: '/zh/examples/preflight-only' },
              ],
            },
          ],
        },
      },
    },
  },
  base: '/',
  themeConfig: {
    socialLinks: [
      { icon: 'github', link: 'https://github.com/youngming/label-print-topbridge-js-core-demo' },
    ],
    search: {
      provider: 'local',
    },
  },
})
