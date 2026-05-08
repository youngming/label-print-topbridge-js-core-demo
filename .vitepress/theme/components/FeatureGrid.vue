<script setup lang="ts">
import { ref } from 'vue'
import FeatureCard from './FeatureCard.vue'
import { useScrollReveal } from '../composables/useScrollReveal'

defineProps<{
  locale: 'en' | 'zh'
}>()

const gridRef = ref<HTMLElement | null>(null)
useScrollReveal(gridRef)

const features = {
  en: [
    { icon: 'headless', title: 'Headless Architecture', desc: 'No UI bindings. Works with React, Vue, Svelte, or vanilla JS.' },
    { icon: 'package', title: 'Zero Dependencies', desc: 'Pure browser-native APIs. npm install and go.' },
    { icon: 'shield', title: 'Structured Errors', desc: '10 error types with instanceof narrowing for precise diagnostics.' },
    { icon: 'rocket', title: 'Preflight Orchestration', desc: 'One-liner: health check → quota validation → printer discovery.' },
    { icon: 'lock', title: 'Security First', desc: 'Fixed local connection, source allowlist, input sanitization, build obfuscation.' },
    { icon: 'zap', title: 'Auto Launch & Retry', desc: 'Automatically detect and launch Tray App with built-in retry orchestration.' },
  ],
  zh: [
    { icon: 'headless', title: 'Headless 架构', desc: '无 UI 绑定，适配 React / Vue / Svelte / 原生 JS。' },
    { icon: 'package', title: '零依赖', desc: '纯浏览器原生 API，npm install 即用。' },
    { icon: 'shield', title: '结构化错误', desc: '10 种错误类型，instanceof 类型窄化，精准定位问题。' },
    { icon: 'rocket', title: '预检编排', desc: '一行代码完成健康检查 → 权益验证 → 打印机获取。' },
    { icon: 'lock', title: '安全优先', desc: '固定本地连接 + Source 白名单 + 输入清洗 + 构建混淆。' },
    { icon: 'zap', title: '自动启动与重试', desc: '自动检测并启动 Tray App，内置连接重试编排。' },
  ],
}
</script>

<template>
  <section class="tb-features" :aria-label="locale === 'zh' ? '核心特性' : 'Features'">
    <div ref="gridRef" class="tb-features-grid">
      <div
        v-for="(f, i) in features[locale]"
        :key="f.icon"
        class="tb-reveal-item"
        :style="{ transitionDelay: `${i * 80}ms` }"
      >
        <FeatureCard :icon="f.icon" :title="f.title" :desc="f.desc" />
      </div>
    </div>
  </section>
</template>

<style scoped>
.tb-features {
  position: relative;
  padding: 48px 24px 80px;
  max-width: 1100px;
  margin: 0 auto;
}

.tb-features-grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 16px;
}

@media (min-width: 640px) {
  .tb-features-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 20px;
  }
}

@media (min-width: 960px) {
  .tb-features-grid {
    grid-template-columns: repeat(3, 1fr);
    gap: 24px;
  }
}

.tb-reveal-item {
  opacity: 0;
  transform: translateY(30px);
  transition: opacity 0.5s cubic-bezier(0.16, 1, 0.3, 1),
              transform 0.5s cubic-bezier(0.16, 1, 0.3, 1);
}

.tb-reveal-item.tb-revealed {
  opacity: 1;
  transform: translateY(0);
}
</style>
