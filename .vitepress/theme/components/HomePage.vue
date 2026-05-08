<script setup lang="ts">
import { ref, onMounted } from 'vue'
import HeroSection from './HeroSection.vue'
import FeatureGrid from './FeatureGrid.vue'
import AnimatedBackground from './AnimatedBackground.vue'
import { useReducedMotion } from '../composables/useReducedMotion'

const props = defineProps<{
  lang?: 'en' | 'zh'
}>()

const prefersReducedMotion = useReducedMotion()
const isLoaded = ref(false)

const locale = props.lang || 'en'

onMounted(() => {
  requestAnimationFrame(() => {
    isLoaded.value = true
  })
})
</script>

<template>
  <div
    class="tb-home"
    :class="{
      'tb-loaded': isLoaded,
      'tb-reduced-motion': prefersReducedMotion,
    }"
  >
    <AnimatedBackground />
    <HeroSection :locale="locale" />
    <FeatureGrid :locale="locale" />
  </div>
</template>

<style scoped>
.tb-home {
  position: relative;
  background: linear-gradient(
    135deg,
    var(--tb-hero-gradient-start) 0%,
    var(--tb-hero-gradient-end) 100%
  );
  min-height: 100vh;
  overflow: hidden;
}

.tb-home::after {
  content: '';
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 120px;
  background: linear-gradient(to top, var(--tb-bg-secondary), transparent);
  pointer-events: none;
  z-index: 0;
}
</style>
