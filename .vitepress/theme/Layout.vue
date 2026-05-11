<script setup lang="ts">
import DefaultTheme from 'vitepress/theme'
import SdkSwitcher from './components/SdkSwitcher.vue'
import ComingSoonOverlay from './components/ComingSoonOverlay.vue'
import { provideSdkType } from './composables/useSdkType'
import { useData } from 'vitepress'
import { computed } from 'vue'

const { Layout } = DefaultTheme
const { lang } = useData()

const { sdkType, setSdkType } = provideSdkType()

const locale = computed(() => lang.value === 'zh-CN' ? 'zh' as const : 'en' as const)
</script>

<template>
  <Layout>
    <template #nav-bar-content-after>
      <SdkSwitcher :locale="locale" />
    </template>
    <template #layout-top>
      <ComingSoonOverlay :sdk-type="sdkType" :locale="locale" />
    </template>
  </Layout>
</template>
