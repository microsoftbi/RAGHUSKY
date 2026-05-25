<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { adminApi, type AdminDocument } from '@/api/admin'

const items = ref<AdminDocument[]>([])
const loading = ref(false)
const q = ref('')

async function load() {
  loading.value = true
  try {
    items.value = await adminApi.listDocuments(q.value || undefined)
  } finally {
    loading.value = false
  }
}

function humanSize(n: number) {
  if (n < 1024) return `${n} B`
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`
  return `${(n / 1024 / 1024).toFixed(1)} MB`
}

onMounted(load)
</script>

<template>
  <div>
    <el-alert
      type="info"
      :closable="false"
      title="本页只读。修改 Documents/ 文件夹后,请运行: cd backend && uv run python -m scripts.ingest"
      style="margin-bottom: 12px;"
    />
    <div style="display:flex; gap:8px; margin-bottom: 12px;">
      <el-input v-model="q" placeholder="按标题或路径搜索" clearable style="max-width: 360px;" @keyup.enter="load" />
      <el-button @click="load">搜索</el-button>
    </div>
    <el-table v-loading="loading" :data="items" border>
      <el-table-column prop="title" label="标题" />
      <el-table-column prop="source" label="路径" />
      <el-table-column prop="mime_type" label="类型" width="160" />
      <el-table-column label="大小" width="100">
        <template #default="{ row }">{{ humanSize(row.size_bytes) }}</template>
      </el-table-column>
      <el-table-column prop="chunk_count" label="切片数" width="100" align="right" />
      <el-table-column label="sha256" width="180">
        <template #default="{ row }">
          <span style="font-family: monospace;">{{ row.sha256.slice(0, 12) }}…</span>
        </template>
      </el-table-column>
      <el-table-column prop="created_at" label="入库时间" width="200" />
    </el-table>
  </div>
</template>
