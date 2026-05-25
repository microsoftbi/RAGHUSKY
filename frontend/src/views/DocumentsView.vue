<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { listChunks, listDocuments, type ChunkItem, type DocumentItem } from '@/api/documents'

const items = ref<DocumentItem[]>([])
const loading = ref(false)

const drawerOpen = ref(false)
const drawerLoading = ref(false)
const drawerDoc = ref<DocumentItem | null>(null)
const drawerChunks = ref<ChunkItem[]>([])

const activeTab = ref<string>('all')

async function load() {
  loading.value = true
  try {
    items.value = await listDocuments()
  } finally {
    loading.value = false
  }
}

async function openChunks(doc: DocumentItem) {
  drawerDoc.value = doc
  drawerOpen.value = true
  drawerLoading.value = true
  drawerChunks.value = []
  try {
    drawerChunks.value = await listChunks(doc.doc_id)
  } finally {
    drawerLoading.value = false
  }
}

function splitterOf(source: string): 'agentic' | 'normal' | 'other' {
  const top = source.split('/')[0] || ''
  if (top === 'Agentic') return 'agentic'
  if (top === 'Normal') return 'normal'
  return 'other'
}

const groups = computed(() => {
  const acc = { normal: [] as DocumentItem[], agentic: [] as DocumentItem[], other: [] as DocumentItem[] }
  for (const it of items.value) {
    acc[splitterOf(it.source)].push(it)
  }
  return acc
})

const filteredItems = computed(() => {
  if (activeTab.value === 'normal') return groups.value.normal
  if (activeTab.value === 'agentic') return groups.value.agentic
  if (activeTab.value === 'other') return groups.value.other
  return items.value
})

const tabHelp = computed(() => {
  switch (activeTab.value) {
    case 'normal':
      return '位于 Documents/Normal/ 下,使用配置的字符切分器(默认 recursive,800/120)入库。'
    case 'agentic':
      return '位于 Documents/Agentic/ 下,由 LLM 进行语义切分入库(单独 collection)。'
    case 'other':
      return '不在 Normal/ 或 Agentic/ 子目录下的文档,使用默认切分器。'
    default:
      return '所有已入库文档。Agentic/ 走 LLM 切分,Normal/ 走字符切分,二者向量分别存放于独立 collection,检索时合并 top_k。'
  }
})

onMounted(load)
</script>

<template>
  <div style="padding: 16px; max-width: 1100px; margin: 0 auto;">
    <h2>知识库文档</h2>
    <p style="color: var(--color-text-muted); margin-top:-4px;">
      由运维通过把文件放入仓库根目录的 <code>Documents/</code> 文件夹并运行
      <code>python -m scripts.ingest</code> 维护。
    </p>

    <el-tabs v-model="activeTab" style="margin-top: 8px;">
      <el-tab-pane name="all">
        <template #label>
          全部 <el-tag size="small" type="info" effect="plain" style="margin-left:6px;">{{ items.length }}</el-tag>
        </template>
      </el-tab-pane>
      <el-tab-pane name="normal">
        <template #label>
          Normal · 字符切分 <el-tag size="small" type="primary" effect="plain" style="margin-left:6px;">{{ groups.normal.length }}</el-tag>
        </template>
      </el-tab-pane>
      <el-tab-pane name="agentic">
        <template #label>
          Agentic · LLM 切分 <el-tag size="small" type="success" effect="plain" style="margin-left:6px;">{{ groups.agentic.length }}</el-tag>
        </template>
      </el-tab-pane>
      <el-tab-pane v-if="groups.other.length > 0" name="other">
        <template #label>
          其它 <el-tag size="small" type="warning" effect="plain" style="margin-left:6px;">{{ groups.other.length }}</el-tag>
        </template>
      </el-tab-pane>
    </el-tabs>

    <p style="color: var(--color-text-muted); font-size:12px; margin-top:-8px;">{{ tabHelp }}</p>

    <el-table v-loading="loading" :data="filteredItems" border>
      <el-table-column prop="title" label="标题" />
      <el-table-column prop="source" label="路径">
        <template #default="{ row }">
          <span>{{ row.source }}</span>
          <el-tag
            v-if="splitterOf(row.source) === 'agentic'"
            size="small"
            type="success"
            effect="plain"
            style="margin-left:8px;"
          >agentic</el-tag>
          <el-tag
            v-else-if="splitterOf(row.source) === 'normal'"
            size="small"
            type="primary"
            effect="plain"
            style="margin-left:8px;"
          >recursive</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="chunk_count" label="切片数" width="100" align="right" />
      <el-table-column prop="created_at" label="入库时间" width="200" />
      <el-table-column label="操作" width="120" align="center">
        <template #default="{ row }">
          <el-button type="primary" link @click="openChunks(row)">查看切片</el-button>
        </template>
      </el-table-column>
    </el-table>
    <div style="margin-top: 12px;">
      <el-button @click="load">刷新</el-button>
    </div>

    <el-drawer
      v-model="drawerOpen"
      :title="drawerDoc ? `切片预览 · ${drawerDoc.title}` : '切片预览'"
      direction="rtl"
      size="60%"
    >
      <div v-if="drawerDoc" style="color: var(--color-text-muted); font-size:12px; margin-bottom:12px;">
        路径:{{ drawerDoc.source }} · 共 {{ drawerDoc.chunk_count }} 个切片
      </div>
      <div v-loading="drawerLoading">
        <el-empty v-if="!drawerLoading && drawerChunks.length === 0" description="无切片" />
        <div
          v-for="c in drawerChunks"
          :key="c.chunk_id"
          style="border:1px solid var(--color-border); border-radius: var(--radius-md);
                 padding: 10px 12px; margin-bottom: 10px; background:#fff;"
        >
          <div style="display:flex; justify-content:space-between; align-items:center;
                      font-size:12px; color: var(--color-text-muted); margin-bottom:6px;">
            <span>#{{ c.ordinal }} · {{ c.chunk_id.slice(0, 8) }}</span>
            <span>{{ c.text.length }} chars · ~{{ c.token_count }} tokens</span>
          </div>
          <div style="white-space: pre-wrap; line-height:1.6; font-size:14px;">{{ c.text }}</div>
        </div>
      </div>
    </el-drawer>
  </div>
</template>
