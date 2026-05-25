import { defineStore } from 'pinia'

interface AuthState {
  token: string | null
  username: string | null
  role: 'user' | 'admin' | null
}

const STORAGE_KEY = 'ragusky.auth'

export const useAuthStore = defineStore('auth', {
  state: (): AuthState => ({ token: null, username: null, role: null }),
  getters: {
    isAuthenticated: (s) => !!s.token,
    isAdmin: (s) => s.role === 'admin'
  },
  actions: {
    init() {
      const raw = localStorage.getItem(STORAGE_KEY)
      if (raw) {
        try {
          const parsed = JSON.parse(raw)
          this.token = parsed.token
          this.username = parsed.username
          this.role = parsed.role
        } catch {
          localStorage.removeItem(STORAGE_KEY)
        }
      }
    },
    setSession(token: string, username: string, role: 'user' | 'admin') {
      this.token = token
      this.username = username
      this.role = role
      localStorage.setItem(STORAGE_KEY, JSON.stringify({ token, username, role }))
    },
    logout() {
      this.token = null
      this.username = null
      this.role = null
      localStorage.removeItem(STORAGE_KEY)
    }
  }
})
