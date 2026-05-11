<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vitepress'
import ComingSoon from './ComingSoon.vue'
import type { SdkType } from '../composables/useSdkType'

const props = defineProps<{
  sdkType: SdkType
  locale: 'en' | 'zh'
}>()

const route = useRoute()

const isHome = computed(() => {
  return route.path === '/' || route.path === '/zh/' || route.path === '/zh'
})

const show = computed(() => props.sdkType !== 'js-core' && !isHome.value)
</script>

<template>
  <div v-if="show" class="coming-soon-overlay">
    <ComingSoon :sdk-type="sdkType" :locale="locale" />
  </div>
</template>

<style scoped>
.coming-soon-overlay {
  position: fixed;
  inset: 0;
  z-index: 999;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--tb-bg-primary);
  opacity: 0.97;
  backdrop-filter: blur(8px);
}
</style>
