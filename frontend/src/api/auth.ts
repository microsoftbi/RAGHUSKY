import { http } from './http'

export interface LoginResponse {
  access_token: string
  token_type: 'bearer'
  role: 'user' | 'admin'
  username: string
}

export function login(username: string, password: string) {
  return http.post<LoginResponse>('/auth/login', { username, password }).then((r) => r.data)
}

export function fetchMe() {
  return http.get('/auth/me').then((r) => r.data)
}

export function logout() {
  return http.post('/auth/logout').catch(() => undefined)
}
