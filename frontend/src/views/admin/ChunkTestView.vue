<script setup lang="ts">
import { computed, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { adminApi, type ChunkSplitter, type ChunkTestChunk } from '@/api/admin'

const text = ref('')
const splitter = ref<ChunkSplitter>('recursive')
const chunkSize = ref(800)
const chunkOverlap = ref(120)
const loading = ref(false)
const chunks = ref<ChunkTestChunk[]>([])
const runSplitter = ref<ChunkSplitter | null>(null)

const isRecursive = computed(() => splitter.value === 'recursive')

async function run() {
  const t = text.value.trim()
  if (!t) {
    ElMessage.warning('请输入要切分的文本')
    return
  }
  if (isRecursive.value && chunkOverlap.value >= chunkSize.value) {
    ElMessage.warning('chunk_overlap 必须小于 chunk_size')
    return
  }
  loading.value = true
  try {
    const res = await adminApi.chunkTest({
      text: t,
      splitter: splitter.value,
      chunk_size: chunkSize.value,
      chunk_overlap: chunkOverlap.value
    })
    chunks.value = res.chunks
    runSplitter.value = res.splitter
  } finally {
    loading.value = false
  }
}

function clearAll() {
  text.value = ''
  chunks.value = []
  runSplitter.value = null
}
</script>

<template>
  <div class="chunk-test">
    <el-alert
      type="info"
      :closable="false"
      title="粘贴一段文本,选择切分策略后查看 chunk 结果。Agentic 走 LLM,耗时数秒到数十秒;Recursive 仅按字符规则切分。"
      style="margin-bottom: 12px;"
    />

    <div class="toolbar">
      <el-radio-group v-model="splitter" :disabled="loading">
        <el-radio-button value="recursive">Recursive</el-radio-button>
        <el-radio-button value="agentic">Agentic</el-radio-button>
      </el-radio-group>

      <template v-if="isRecursive">
        <span class="lbl">chunk_size</span>
        <el-input-number v-model="chunkSize" :min="100" :max="4000" :step="50" :disabled="loading" />
        <span class="lbl">chunk_overlap</span>
        <el-input-number v-model="chunkOverlap" :min="0" :max="2000" :step="20" :disabled="loading" />
      </template>

      <div class="spacer" />
      <el-button :disabled="loading" @click="clearAll">清空</el-button>
      <el-button type="primary" :loading="loading" @click="run">切分</el-button>
    </div>

    <div class="panes">
      <div class="pane pane-left">
        <div class="pane-head">
          <span>输入文本</span>
          <span class="meta">{{ text.length }} 字符</span>
        </div>
        <el-input
          v-model="text"
          type="textarea"
          resize="none"
          placeholder="在此粘贴或输入要测试的文本…"
          class="text-area"
          :disabled="loading"
        />
      </div>

      <div class="pane pane-right" v-loading="loading">
        <div class="pane-head">
          <span>切分结果</span>
          <span class="meta">
            <template v-if="runSplitter">
              {{ runSplitter }} · {{ chunks.length }} chunks
            </template>
            <template v-else>尚未运行</template>
          </span>
        </div>
        <div class="chunks-scroll">
          <el-empty v-if="!loading && chunks.length === 0" description="暂无结果" />
          <div
            v-for="c in chunks"
            :key="c.ordinal"
            class="chunk-card"
          >
            <div class="chunk-head">
              <span class="chunk-idx">#{{ c.ordinal + 1 }}</span>
              <span class="chunk-len">{{ c.char_count }} 字符</span>
            </div>
            <div class="chunk-body">{{ c.text }}</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.chunk-test {
  display: flex;
  flex-direction: column;
  height: calc(100vh - 120px);
  min-height: 480px;
}

.toolbar {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 12px;
  flex-wrap: wrap;
}

.toolbar .lbl {
  color: var(--color-text-muted);
  font-size: 13px;
  margin-left: 6px;
}

.toolbar .spacer {
  flex: 1;
}

.panes {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  flex: 1;
  min-height: 0;
}

.pane {
  display: flex;
  flex-direction: column;
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  overflow: hidden;
  min-height: 0;
}

.pane-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  background: var(--color-surface-2);
  border-bottom: 1px solid var(--color-border);
  font-weight: 600;
  font-size: 13px;
  color: var(--color-text);
}

.pane-head .meta {
  color: var(--color-text-muted);
  font-weight: 400;
  font-size: 12px;
}

.pane-left .text-area {
  flex: 1;
  display: flex;
}

.pane-left :deep(.el-textarea__inner) {
  height: 100%;
  border: none;
  border-radius: 0;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-size: 13px;
  line-height: 1.55;
  box-shadow: none;
}

.chunks-scroll {
  flex: 1;
  overflow: auto;
  padding: 12px;
  background: var(--color-surface);
}

.chunk-card {
  background: var(--color-bg);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  margin-bottom: 10px;
  overflow: hidden;
}

.chunk-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 6px 10px;
  background: var(--color-primary-light);
  color: var(--color-primary-active);
  font-size: 12px;
  font-weight: 600;
}

.chunk-body {
  padding: 10px 12px;
  white-space: pre-wrap;
  word-break: break-word;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-size: 13px;
  line-height: 1.55;
  color: var(--color-text);
}
</style>
