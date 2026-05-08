<script setup lang="ts">
import { VPLink } from 'vitepress/theme'
import InstallCommand from './InstallCommand.vue'

defineProps<{
  locale: 'en' | 'zh'
}>()

const i18n = {
  en: {
    subtitle: 'Browser-to-Printer, One Bridge Away',
    cta1: 'Get Started',
    cta2: 'View on NPM',
    cta3: 'API Reference',
  },
  zh: {
    subtitle: '浏览器到打印机，一座桥的距离',
    cta1: '快速开始',
    cta2: '查看 NPM',
    cta3: 'API 参考',
  },
}

const links = {
  en: {
    cta1: '/guide/getting-started',
    cta3: '/guide/developer-guide',
  },
  zh: {
    cta1: '/zh/guide/getting-started',
    cta3: '/zh/guide/developer-guide',
  },
}
</script>

<template>
  <section class="tb-hero" aria-label="Hero">
    <div class="tb-hero-inner">
      <div class="tb-hero-logo tb-animate">
        <img
          src="/logo.png"
          alt="TopBridge Logo"
          width="429"
          height="236"
          loading="eager"
        />
      </div>

      <h1 class="tb-hero-title tb-animate">TopBridge JS Core SDK</h1>

      <p class="tb-hero-subtitle tb-animate">{{ i18n[locale].subtitle }}</p>

      <InstallCommand
        class="tb-animate"
        command="npm install @appzgatenz/label-print-topbridge-js"
        :locale="locale"
      />

      <div class="tb-hero-actions tb-animate">
        <VPLink :href="links[locale].cta1" class="tb-btn tb-btn--primary">
          {{ i18n[locale].cta1 }}
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tb-btn-arrow"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
        </VPLink>
        <VPLink
          href="https://www.npmjs.com/package/@appzgatenz/label-print-topbridge-js"
          target="_blank"
          rel="noopener noreferrer"
          no-icon
          class="tb-btn tb-btn--outline"
        >
          {{ i18n[locale].cta2 }}
        </VPLink>
        <VPLink :href="links[locale].cta3" class="tb-btn tb-btn--text">
          {{ i18n[locale].cta3 }}
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="tb-btn-arrow"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
        </VPLink>
      </div>
    </div>

    <div class="tb-scroll-indicator" aria-hidden="true">
      <div class="tb-scroll-dot"></div>
    </div>
  </section>
</template>

<style scoped>
.tb-hero {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: calc(100vh - 64px);
  padding: 64px 24px 48px;
  text-align: center;
}

.tb-hero-inner {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 32px;
}

.tb-hero-logo {
  margin-bottom: 12px;
}

.tb-hero-logo img {
  height: 80px;
  width: auto;
}

.tb-hero-title {
  font-family: var(--tb-font-display);
  font-size: 32px;
  font-weight: 700;
  line-height: 1.15;
  color: var(--tb-text-primary);
  margin: 0;
  letter-spacing: -0.02em;
}

.tb-hero-subtitle {
  font-family: var(--tb-font-display);
  font-size: 16px;
  font-weight: 400;
  line-height: 1.5;
  color: var(--tb-text-secondary);
  margin: 0;
  max-width: 480px;
}

.tb-hero-actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin-top: 16px;
}

/* Buttons */
.tb-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-family: var(--tb-font-display);
  font-size: 14px;
  font-weight: 500;
  padding: 10px 20px;
  border-radius: 8px;
  text-decoration: none;
  transition: all 0.2s ease;
  cursor: pointer;
  border: 1px solid transparent;
}

.tb-btn:focus-visible {
  outline: 2px solid var(--vp-c-brand-1);
  outline-offset: 2px;
}

.tb-btn--primary {
  background: var(--vp-c-brand-1);
  color: #ffffff;
  border-color: var(--vp-c-brand-1);
}

.tb-btn--primary:hover {
  background: var(--vp-c-brand-2);
  transform: scale(1.02);
}

.tb-btn--primary:active {
  transform: scale(0.98);
}

.tb-btn--outline {
  background: transparent;
  color: var(--vp-c-brand-1);
  border-color: var(--tb-border);
}

.tb-btn--outline:hover {
  border-color: var(--vp-c-brand-2);
  background: var(--vp-c-brand-soft);
}

.tb-btn--text {
  background: transparent;
  color: var(--tb-text-secondary);
  padding: 10px 12px;
}

.tb-btn--text:hover {
  color: var(--vp-c-brand-1);
}

.tb-btn-arrow {
  transition: transform 0.2s ease;
}

.tb-btn:hover .tb-btn-arrow {
  transform: translateX(2px);
}

/* Scroll indicator */
.tb-scroll-indicator {
  position: absolute;
  bottom: 32px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
}

.tb-scroll-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--tb-text-tertiary);
  animation: tb-scroll-bounce 3s ease-in-out infinite;
}

/* Stagger animation delays for hero children */
.tb-loaded .tb-hero-logo { animation: tb-fade-up 1.5s cubic-bezier(0.4, 0, 0.2, 1) 0.20s forwards; }
.tb-loaded .tb-hero-title { animation: tb-fade-up 1.5s cubic-bezier(0.4, 0, 0.2, 1) 0.55s forwards; }
.tb-loaded .tb-hero-subtitle { animation: tb-fade-up 1.5s cubic-bezier(0.4, 0, 0.2, 1) 0.90s forwards; }
.tb-loaded .tb-hero .tb-install { animation: tb-fade-up 1.5s cubic-bezier(0.4, 0, 0.2, 1) 1.25s forwards; }
.tb-loaded .tb-hero-actions { animation: tb-fade-up 1.5s cubic-bezier(0.4, 0, 0.2, 1) 1.50s forwards; }

/* Responsive */
@media (min-width: 640px) {
  .tb-hero-logo img { height: 100px; }
  .tb-hero-title { font-size: 42px; }
  .tb-hero-subtitle { font-size: 18px; }
}

@media (min-width: 960px) {
  .tb-hero-logo img { height: 120px; }
  .tb-hero-title { font-size: 52px; }
  .tb-hero-subtitle { font-size: 20px; max-width: 560px; }
  .tb-hero { padding: 64px 48px 48px; }
}
</style>
