import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { authService } from '@/services/auth'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)
  const idToken = ref(null)

  const isAuthenticated = computed(() => !!user.value)

  async function checkAuth() {
    try {
      const currentUser = await authService.getCurrentUser()
      if (currentUser) {
        const [token, attributes] = await Promise.all([
          authService.getIdToken(),
          authService.getUserAttributes()
        ])
        idToken.value = token
        user.value = {
          username: attributes.username,
          email: attributes.email,
          sub: attributes.sub
        }
        return true
      }
    } catch (err) {
      console.error('Auth check failed:', err)
    }
    user.value = null
    idToken.value = null
    return false
  }

  async function logout() {
    await authService.signOut()
    user.value = null
    idToken.value = null
  }

  return {
    user,
    idToken,
    isAuthenticated,
    logout,
    checkAuth
  }
})
