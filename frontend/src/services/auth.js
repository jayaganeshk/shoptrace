import { fetchAuthSession, signOut, getCurrentUser, fetchUserAttributes } from 'aws-amplify/auth'

export const authService = {
  /**
   * Get current authenticated user
   */
  async getCurrentUser() {
    try {
      const user = await getCurrentUser()
      return user
    } catch {
      return null
    }
  },

  /**
   * Get ID token
   */
  async getIdToken() {
    try {
      const session = await fetchAuthSession()
      return session.tokens?.idToken?.toString()
    } catch {
      return null
    }
  },

  /**
   * Get user attributes
   */
  async getUserAttributes() {
    try {
      const user = await getCurrentUser()
      const attributes = await fetchUserAttributes()
      return {
        username: user.username,
        email: attributes.email,
        sub: attributes.sub
      }
    } catch {
      return null
    }
  },

  /**
   * Sign out user
   */
  async signOut() {
    const signOutres = await signOut()
    console.log("Sign out response:", signOutres)
  }
}
