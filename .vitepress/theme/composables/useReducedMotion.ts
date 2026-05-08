import { ref, onMounted, onBeforeUnmount } from 'vue'

export function useReducedMotion() {
  const prefersReducedMotion = ref(false)
  let mql: MediaQueryList | null = null

  const handler = (e: MediaQueryListEvent) => {
    prefersReducedMotion.value = e.matches
  }

  onMounted(() => {
    mql = window.matchMedia('(prefers-reduced-motion: reduce)')
    prefersReducedMotion.value = mql.matches
    mql.addEventListener('change', handler)
  })

  onBeforeUnmount(() => {
    mql?.removeEventListener('change', handler)
  })

  return prefersReducedMotion
}
