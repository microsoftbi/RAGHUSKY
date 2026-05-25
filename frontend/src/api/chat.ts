import { useAuthStore } from '@/stores/auth'

export interface RetrievedChunkLite {
  chunk_id: string
  doc_id: string
  source: string
  score: number
  snippet: string
}

export interface ChatStreamCallbacks {
  onSession?: (sessionId: string) => void
  onRetrieved?: (chunks: RetrievedChunkLite[]) => void
  onToken?: (delta: string) => void
  onDone?: (data: { session_id: string; answer: string; citations: string[]; status: string }) => void
  onError?: (msg: string) => void
}

interface ChatRequest {
  session_id?: string | null
  query: string
  top_k?: number
  filters?: Record<string, unknown> | null
}

export async function streamChat(
  req: ChatRequest,
  cb: ChatStreamCallbacks,
  signal?: AbortSignal
) {
  const auth = useAuthStore()
  const resp = await fetch('/api/v1/chat', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: auth.token ? `Bearer ${auth.token}` : ''
    },
    body: JSON.stringify(req),
    signal
  })

  if (resp.status === 401) {
    auth.logout()
    location.assign('/login')
    return
  }
  if (!resp.ok || !resp.body) {
    const text = await resp.text().catch(() => '')
    throw new Error(text || `HTTP ${resp.status}`)
  }

  const reader = resp.body.getReader()
  const decoder = new TextDecoder('utf-8')
  let buffer = ''

  while (true) {
    const { value, done } = await reader.read()
    if (done) break
    buffer += decoder.decode(value, { stream: true }).replace(/\r\n/g, '\n')

    let idx: number
    while ((idx = buffer.indexOf('\n\n')) !== -1) {
      const raw = buffer.slice(0, idx)
      buffer = buffer.slice(idx + 2)
      handleEvent(raw, cb)
    }
  }
}

function handleEvent(raw: string, cb: ChatStreamCallbacks) {
  let event = 'message'
  const dataLines: string[] = []
  for (const line of raw.split('\n')) {
    if (line.startsWith('event:')) event = line.slice(6).trim()
    else if (line.startsWith('data:')) dataLines.push(line.slice(5).trim())
  }
  if (dataLines.length === 0) return
  const dataStr = dataLines.join('\n')
  let data: any
  try { data = JSON.parse(dataStr) } catch { return }

  switch (event) {
    case 'session': cb.onSession?.(data.session_id); break
    case 'retrieved': cb.onRetrieved?.(data.chunks ?? []); break
    case 'token': cb.onToken?.(data.delta ?? ''); break
    case 'error': cb.onError?.(data.message ?? 'error'); break
    case 'done': cb.onDone?.(data); break
  }
}
