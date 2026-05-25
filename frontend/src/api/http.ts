import axios from 'axios'
import { ElMessage } from 'element-plus'
import { useAuthStore } from '@/stores/auth'

export const http = axios.create({ baseURL: '/api/v1', timeout: 30000 })

http.interceptors.request.use((cfg) => {
  const auth = useAuthStore()
  if (auth.token) cfg.headers.Authorization = `Bearer ${auth.token}`
  return cfg
})

http.interceptors.response.use(
  (r) => r,
  (err) => {
    const status = err?.response?.status
    const msg = err?.response?.data?.detail || err?.message || 'Request failed'
    if (status === 401) {
      const auth = useAuthStore()
      auth.logout()
      if (location.pathname !== '/login') location.assign('/login')
    } else if (status && status !== 204) {
      ElMessage.error(String(msg))
    }
    return Promise.reject(err)
  }
)
