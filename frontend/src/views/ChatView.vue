<script setup lang="ts">
import { nextTick, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { streamChat, type RetrievedChunkLite } from '@/api/chat'
import { openRawDocument } from '@/api/documents'

interface Msg {
  role: 'user' | 'assistant'
  content: string
  citations?: string[]
  chunks?: RetrievedChunkLite[]
  status?: string
}

const messages = ref<Msg[]>([])
const input = ref('')
const sessionId = ref<string | null>(null)
const loading = ref(false)
const listEl = ref<HTMLElement | null>(null)

async function scrollToBottom() {
  await nextTick()
  listEl.value?.scrollTo({ top: listEl.value.scrollHeight, behavior: 'smooth' })
}

async function send() {
  const q = input.value.trim()
  if (!q || loading.value) return
  input.value = ''
  messages.value.push({ role: 'user', content: q })
  const aIdx = messages.value.push({ role: 'assistant', content: '', chunks: [] }) - 1
  loading.value = true
  scrollToBottom()
  try {
    await streamChat(
      { session_id: sessionId.value, query: q, top_k: 4 },
      {
        onSession: (s) => (sessionId.value = s),
        onRetrieved: (chunks) => (messages.value[aIdx].chunks = chunks),
        onToken: (delta) => {
          messages.value[aIdx].content += delta
          scrollToBottom()
        },
        onDone: (d) => {
          messages.value[aIdx].citations = d.citations
          messages.value[aIdx].status = d.status
        },
        onError: (msg) => {
          messages.value[aIdx].content += `\n[stream error: ${msg}]`
          messages.value[aIdx].status = 'error'
        }
      }
    )
  } catch (e: any) {
    messages.value[aIdx].content += `\n[request failed: ${e?.message || e}]`
    messages.value[aIdx].status = 'error'
    console.error('[chat] streamChat failed:', e)
  } finally {
    loading.value = false
    scrollToBottom()
  }
}

function chunkOf(m: Msg, id: string) {
  return m.chunks?.find((c) => c.chunk_id === id)
}

async function openRaw(docId: string) {
  try {
    await openRawDocument(docId)
  } catch (e: any) {
    ElMessage.error(`无法打开原文:${e?.message || e}`)
  }
}
</script>

<template>
  <div style="display:flex; flex-direction:column; height:100%; max-width: 960px; margin: 0 auto; padding: 16px;">
    <div ref="listEl" style="flex:1; overflow:auto; padding: 8px;">
      <div v-for="(m, i) in messages" :key="i" style="margin-bottom: 16px;">
        <div
          :style="{
            background: m.role === 'user' ? 'var(--color-primary-light)' : '#fff',
            border: m.role === 'user' ? 'none' : '1px solid var(--color-border)',
            color: 'var(--color-text)',
            borderRadius: 'var(--radius-md)',
            padding: '12px 14px',
            whiteSpace: 'pre-wrap',
            lineHeight: '1.6'
          }"
        >
          {{ m.content || (m.role === 'assistant' && loading ? '…' : '') }}
        </div>
        <div v-if="m.role === 'assistant' && m.citations?.length" style="margin-top:8px; display:flex; flex-wrap:wrap; gap:6px;">
          <el-popover
            v-for="cid in m.citations"
            :key="cid"
            trigger="click"
            placement="top"
            :width="420"
          >
            <template #reference>
              <el-tag size="small" effect="plain">{{ cid.slice(0, 8) }}</el-tag>
            </template>
            <div v-if="chunkOf(m, cid)">
              <div style="font-size:12px; color: var(--color-text-muted); margin-bottom:6px;">
                来源:{{ chunkOf(m, cid)!.source }} · score {{ chunkOf(m, cid)!.score.toFixed(3) }}
              </div>
              <div style="white-space: pre-wrap; max-height: 320px; overflow:auto;">
                {{ chunkOf(m, cid)!.snippet }}
              </div>
              <div style="margin-top:8px; text-align:right;">
                <el-link type="primary" :underline="false" @click="openRaw(chunkOf(m, cid)!.doc_id)">
                  打开原文 ↗
                </el-link>
              </div>
            </div>
            <div v-else>未找到此引用切片。</div>
          </el-popover>
        </div>
      </div>
    </div>

    <el-input
      v-model="input"
      type="textarea"
      :rows="3"
      placeholder="问点什么…  (Enter 发送, Shift+Enter 换行)"
      @keydown.enter.exact.prevent="send"
    />
    <div style="display:flex; justify-content:flex-end; margin-top:8px;">
      <el-button type="primary" :loading="loading" @click="send">发送</el-button>
    </div>
  </div>
</template>
