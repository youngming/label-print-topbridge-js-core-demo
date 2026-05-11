<script setup lang="ts">
import { useSdkType } from '../composables/useSdkType'
import type { SdkType } from '../composables/useSdkType'

const props = defineProps<{
  locale: 'en' | 'zh'
}>()

const sdkType = useSdkType()

const labels = {
  en: {
    'js-core': 'JS Core',
    nextjs: 'Next.js',
    react: 'React',
  },
  zh: {
    'js-core': 'JS Core',
    nextjs: 'Next.js',
    react: 'React',
  },
}

const options: { value: SdkType; badge?: string }[] = [
  { value: 'js-core' },
  { value: 'nextjs', badge: props.locale === 'zh' ? '即将支持' : 'Soon' },
  { value: 'react', badge: props.locale === 'zh' ? '即将支持' : 'Soon' },
]

function isActive(t: SdkType) {
  return sdkType.value === t
}

function switchTo(t: SdkType) {
  sdkType.value = t
  document.documentElement.dataset.sdk = t
}
</script>

<template>
  <div class="sdk-switcher">
    <button
      v-for="opt in options"
      :key="opt.value"
      class="sdk-switcher-btn"
      :class="{ 'sdk-switcher-btn--active': isActive(opt.value) }"
      @click="switchTo(opt.value)"
    >
      {{ labels[locale][opt.value] }}
      <span v-if="opt.badge" class="sdk-switcher-badge">{{ opt.badge }}</span>
    </button>
  </div>
</template>

<style scoped>
.sdk-switcher {
  display: flex;
  align-items: center;
  gap: 2px;
  background: var(--vp-c-bg-soft);
  border-radius: 8px;
  padding: 2px;
  margin-left: 8px;
}

.sdk-switcher-btn {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 4px 12px;
  border: none;
  border-radius: 6px;
  font-size: 13px;
  font-weight: 500;
  font-family: var(--tb-font-display, inherit);
  line-height: 22px;
  color: var(--vp-c-text-2);
  background: transparent;
  cursor: pointer;
  transition: color 0.2s, background-color 0.2s;
  white-space: nowrap;
}

.sdk-switcher-btn:hover {
  color: var(--vp-c-text-1);
}

.sdk-switcher-btn--active {
  color: var(--vp-c-brand-1);
  background: var(--vp-c-bg);
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.sdk-switcher-btn--active:hover {
  color: var(--vp-c-brand-1);
}

.sdk-switcher-badge {
  font-size: 10px;
  font-weight: 600;
  line-height: 1;
  padding: 2px 5px;
  border-radius: 4px;
  background: var(--vp-c-brand-soft);
  color: var(--vp-c-brand-1);
  letter-spacing: 0.02em;
}

.sdk-switcher-btn--active .sdk-switcher-badge {
  background: var(--vp-c-brand-soft);
}

@media (max-width: 640px) {
  .sdk-switcher {
    margin-left: 0;
    margin-top: 4px;
  }
}
</style>
