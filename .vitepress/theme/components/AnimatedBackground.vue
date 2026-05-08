<script setup lang="ts">
import { useReducedMotion } from '../composables/useReducedMotion'

const prefersReducedMotion = useReducedMotion()
</script>

<template>
  <div v-if="!prefersReducedMotion" class="tb-bg" aria-hidden="true">
    <svg class="tb-bg-grid" xmlns="http://www.w3.org/2000/svg" width="100%" height="100%">
      <defs>
        <pattern id="tb-dot-grid" x="0" y="0" width="24" height="24" patternUnits="userSpaceOnUse">
          <circle cx="12" cy="12" r="0.8" fill="var(--tb-text-tertiary)" opacity="0.25" />
        </pattern>
      </defs>
      <rect width="100%" height="100%" fill="url(#tb-dot-grid)" />
    </svg>
    <div class="tb-bg-beam tb-bg-beam--1"></div>
    <div class="tb-bg-beam tb-bg-beam--2"></div>
    <div class="tb-bg-glow tb-bg-glow--1"></div>
    <div class="tb-bg-glow tb-bg-glow--2"></div>
  </div>
</template>

<style scoped>
.tb-bg {
  position: absolute;
  inset: 0;
  overflow: hidden;
  pointer-events: none;
  z-index: 0;
}

.tb-bg-grid {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}

.tb-bg-beam {
  position: absolute;
  left: 0;
  width: 100%;
  height: 1px;
  background: linear-gradient(
    90deg,
    transparent 0%,
    var(--vp-c-brand-2) 15%,
    var(--vp-c-brand-1) 50%,
    var(--vp-c-brand-2) 85%,
    transparent 100%
  );
  opacity: 0;
  animation: tb-beam-sweep 8s ease-in-out infinite;
}

.tb-bg-beam--1 {
  top: 30%;
}

.tb-bg-beam--2 {
  top: 70%;
  animation-delay: 4s;
  animation-direction: reverse;
}

.tb-bg-glow {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  opacity: 0.08;
  animation: tb-pulse 6s ease-in-out infinite;
}

.tb-bg-glow--1 {
  width: 500px;
  height: 500px;
  top: -100px;
  right: -100px;
  background: var(--vp-c-brand-1);
}

.tb-bg-glow--2 {
  width: 400px;
  height: 400px;
  bottom: -80px;
  left: -80px;
  background: var(--tb-accent);
  animation-delay: 3s;
}
</style>
