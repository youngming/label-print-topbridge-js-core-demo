<script setup lang="ts">
import { computed } from 'vue'
import { useClipboard } from '../composables/useClipboard'

const props = withDefaults(defineProps<{
  command: string
  locale?: 'en' | 'zh'
}>(), {
  locale: 'en',
})

const { copied, copy } = useClipboard()

const labels = {
  en: {
    copy: 'Copy',
    copied: 'Copied!',
    ariaCopy: 'Copy install command',
    ariaCopied: 'Copied install command',
  },
  zh: {
    copy: '复制',
    copied: '已复制',
    ariaCopy: '复制安装命令',
    ariaCopied: '已复制安装命令',
  },
}

const localizedLabels = computed(() => labels[props.locale])
</script>

<template>
  <div
    class="tb-install"
    :class="{ 'tb-install--copied': copied }"
    role="button"
    tabindex="0"
    :aria-label="copied ? localizedLabels.ariaCopied : localizedLabels.ariaCopy"
    @click="copy(command)"
    @keydown.enter="copy(command)"
    @keydown.space.prevent="copy(command)"
  >
    <span class="tb-install-prompt">$</span>
    <code class="tb-install-code">{{ command }}</code>
    <span class="tb-install-hint">
      <svg v-if="!copied" xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2" ry="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
      <svg v-else xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
      {{ copied ? localizedLabels.copied : localizedLabels.copy }}
    </span>
  </div>
</template>

<style scoped>
.tb-install {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  background: var(--tb-bg-card);
  border: 1px solid var(--tb-border);
  border-radius: 10px;
  cursor: pointer;
  transition: all 0.2s ease;
  user-select: none;
  max-width: 100%;
}

.tb-install:hover {
  border-color: var(--vp-c-brand-2);
  box-shadow: var(--tb-shadow-md);
}

.tb-install:active {
  transform: scale(0.98);
}

.tb-install--copied {
  border-color: var(--vp-c-brand-1);
  background: var(--vp-c-brand-soft);
}

.tb-install-prompt {
  color: var(--vp-c-brand-1);
  font-family: var(--tb-font-display);
  font-weight: 600;
  font-size: 14px;
  flex-shrink: 0;
}

.tb-install-code {
  font-family: var(--tb-font-display);
  font-size: 13px;
  color: var(--tb-text-primary);
  white-space: nowrap;
  overflow-x: auto;
}

.tb-install-hint {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: var(--tb-text-tertiary);
  flex-shrink: 0;
  transition: color 0.2s ease;
}

.tb-install:hover .tb-install-hint {
  color: var(--tb-text-secondary);
}

.tb-install--copied .tb-install-hint {
  color: var(--vp-c-brand-1);
}

@media (max-width: 639px) {
  .tb-install-hint {
    display: none;
  }
}
</style>
