import { useAuthStore } from '@/stores/auth'
import { http } from './http'

export interface DocumentItem {
  doc_id: string
  title: string
  source: string
  chunk_count: number
  created_at: string
}

export interface ChunkItem {
  chunk_id: string
  ordinal: number
  text: string
  token_count: number
}

export function listDocuments() {
  return http.get<DocumentItem[]>('/documents').then((r) => r.data)
}

export function listChunks(docId: string) {
  return http.get<ChunkItem[]>(`/documents/${docId}/chunks`).then((r) => r.data)
}

export async function openRawDocument(docId: string) {
  const auth = useAuthStore()
  const resp = await fetch(`/api/v1/documents/${docId}/raw`, {
    headers: { Authorization: auth.token ? `Bearer ${auth.token}` : '' }
  })
  if (resp.status === 401) {
    auth.logout()
    location.assign('/login')
    return
  }
  if (!resp.ok) {
    throw new Error(`HTTP ${resp.status}`)
  }
  const blob = await resp.blob()
  const url = URL.createObjectURL(blob)
  const win = window.open(url, '_blank')
  if (!win) {
    const a = document.createElement('a')
    a.href = url
    a.target = '_blank'
    a.rel = 'noopener'
    a.click()
  }
  setTimeout(() => URL.revokeObjectURL(url), 60_000)
}
