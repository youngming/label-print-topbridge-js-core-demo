import { ref, provide, inject, type Ref, type InjectionKey } from 'vue'

export type SdkType = 'js-core' | 'nextjs' | 'react'

export const SDK_TYPE_KEY: InjectionKey<Ref<SdkType>> = Symbol('sdkType')

export function provideSdkType() {
  const sdkType = ref<SdkType>('js-core')

  function setSdkType(t: SdkType) {
    sdkType.value = t
    document.documentElement.dataset.sdk = t
  }

  provide(SDK_TYPE_KEY, sdkType)

  return { sdkType, setSdkType }
}

export function useSdkType() {
  const sdkType = inject(SDK_TYPE_KEY, ref<SdkType>('js-core'))
  return sdkType
}
