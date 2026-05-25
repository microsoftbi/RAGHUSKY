import { http } from './http'

export interface AdminUser {
  user_id: string
  username: string
  role: 'user' | 'admin'
  is_active: boolean
  created_at: string
  last_login_at: string | null
}

export interface AdminDocument {
  doc_id: string
  title: string
  source: string
  mime_type: string
  sha256: string
  size_bytes: number
  chunk_count: number
  created_at: string
  updated_at: string
}

export interface RetrievedChunk {
  chunk_id: string
  doc_id: string
  source: string
  score: number
  text: string
}

export interface IngestConfig {
  chunk_size: number
  chunk_overlap: number
  splitter: 'recursive' | 'markdown_aware'
  updated_at: string
  updated_by: string | null
}

export interface IngestConfigHistoryItem extends IngestConfig {
  history_id: string
  changed_at: string
  changed_by: string | null
}

export const adminApi = {
  listUsers: () => http.get<AdminUser[]>('/admin/users').then((r) => r.data),
  createUser: (p: { username: string; password: string; role: 'user' | 'admin' }) =>
    http.post<AdminUser>('/admin/users', p).then((r) => r.data),
  updateUser: (id: string, p: Partial<Pick<AdminUser, 'role' | 'is_active'>>) =>
    http.patch<AdminUser>(`/admin/users/${id}`, p).then((r) => r.data),
  resetPassword: (id: string, new_password: string) =>
    http.post(`/admin/users/${id}/reset-password`, { new_password }),
  deleteUser: (id: string) => http.delete(`/admin/users/${id}`),

  listDocuments: (q?: string) =>
    http.get<AdminDocument[]>('/admin/documents', { params: q ? { q } : {} }).then((r) => r.data),

  retrievalTest: (query: string, top_k = 4) =>
    http
      .post<{ chunks: RetrievedChunk[] }>('/admin/retrieval-test', { query, top_k })
      .then((r) => r.data),

  getIngestConfig: () => http.get<IngestConfig>('/admin/ingest-config').then((r) => r.data),
  updateIngestConfig: (p: { chunk_size: number; chunk_overlap: number; splitter: string }) =>
    http
      .put<IngestConfig & { requires_rebuild: boolean }>('/admin/ingest-config', p)
      .then((r) => r.data),
  getIngestConfigHistory: () =>
    http.get<IngestConfigHistoryItem[]>('/admin/ingest-config/history').then((r) => r.data)
}
