<template>
  <v-app>
    <router-view />
  </v-app>
</template>

<script setup>
import { onMounted } from 'vue'
import { Hub } from 'aws-amplify/utils'
import { useAuthStore } from '@/stores/auth'

const authStore = useAuthStore()

// Listen to Amplify auth events
onMounted(() => {
  Hub.listen('auth', async ({ payload }) => {
    switch (payload.event) {
      case 'signedIn':
        await authStore.checkAuth()
        break
      case 'signedOut':
        authStore.logout()
        break
    }
  })

  // Check initial auth state
  authStore.checkAuth()
})
</script>
