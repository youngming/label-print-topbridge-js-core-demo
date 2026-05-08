<script setup lang="ts">
defineProps<{
  icon: string
  title: string
  desc: string
}>()
</script>

<template>
  <div class="tb-card">
    <div class="tb-card-icon" :class="`tb-card-icon--${icon}`">
      <!-- headless -->
      <svg v-if="icon === 'headless'" xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2" ry="2"/><line x1="8" y1="21" x2="16" y2="21"/><line x1="12" y1="17" x2="12" y2="21"/></svg>
      <!-- package -->
      <svg v-else-if="icon === 'package'" xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="16.5" y1="9.4" x2="7.5" y2="4.21"/><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>
      <!-- shield -->
      <svg v-else-if="icon === 'shield'" xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>
      <!-- rocket -->
      <svg v-else-if="icon === 'rocket'" xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91-.09z"/><path d="M12 15l-3-3a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.35 22.35 0 0 1-4 2z"/><path d="M9 12H4s.55-3.03 2-4c1.62-1.08 5 0 5 0"/><path d="M12 15v5s3.03-.55 4-2c1.08-1.62 0-5 0-5"/></svg>
      <!-- lock -->
      <svg v-else-if="icon === 'lock'" xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
      <!-- zap -->
      <svg v-else xmlns="http://www.w3.org/2000/svg" width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg>
    </div>
    <h3 class="tb-card-title">{{ title }}</h3>
    <p class="tb-card-desc">{{ desc }}</p>
  </div>
</template>

<style scoped>
.tb-card {
  position: relative;
  padding: 24px;
  background: var(--tb-bg-card);
  border: 1px solid var(--tb-border);
  border-radius: 12px;
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

.tb-card::before {
  content: '';
  position: absolute;
  left: 0;
  top: 12px;
  bottom: 12px;
  width: 3px;
  border-radius: 0 3px 3px 0;
  background: var(--vp-c-brand-1);
  opacity: 0;
  transform: scaleY(0);
  transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
}

.tb-card:hover {
  transform: translateY(-4px);
  border-color: var(--vp-c-brand-soft);
  box-shadow: var(--tb-shadow-lg);
}

.tb-card:hover::before {
  opacity: 1;
  transform: scaleY(1);
}

.tb-card-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: var(--vp-c-brand-soft);
  color: var(--vp-c-brand-1);
  margin-bottom: 14px;
}

.tb-card-title {
  font-family: var(--tb-font-display);
  font-size: 16px;
  font-weight: 600;
  color: var(--tb-text-primary);
  margin: 0 0 8px;
  line-height: 1.3;
}

.tb-card-desc {
  font-size: 14px;
  line-height: 1.6;
  color: var(--tb-text-secondary);
  margin: 0;
}
</style>
