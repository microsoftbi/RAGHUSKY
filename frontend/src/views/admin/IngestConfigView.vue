<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage } from 'element-plus'
import { adminApi, type IngestConfigHistoryItem } from '@/api/admin'

const form = reactive({ chunk_size: 800, chunk_overlap: 120, splitter: 'recursive' as 'recursive' | 'markdown_aware' })
const history = ref<IngestConfigHistoryItem[]>([])
const loading = ref(false)
const saving = ref(false)
const justSaved = ref(false)

async function load() {
  loading.value = true
  try {
    const cur = await adminApi.getIngestConfig()
    form.chunk_size = cur.chunk_size
    form.chunk_overlap = cur.chunk_overlap
    form.splitter = cur.splitter
    history.value = await adminApi.getIngestConfigHistory()
  } finally {
    loading.value = false
  }
}

async function save() {
  if (form.chunk_overlap >= form.chunk_size) {
    ElMessage.warning('chunk_overlap 必须小于 chunk_size')
    return
  }
  saving.value = true
  try {
    await adminApi.updateIngestConfig({ ...form })
    justSaved.value = true
    ElMessage.success('已保存')
    history.value = await adminApi.getIngestConfigHistory()
  } finally {
    saving.value = false
  }
}

onMounted(load)
</script>

<template>
  <div>
    <el-alert
      v-if="justSaved"
      type="warning"
      :closable="false"
      title="切分参数已修改,请在后端运行: cd backend && uv run python -m scripts.ingest --rebuild 让存量文档按新参数重建索引。Collection 会自动升版。"
      style="margin-bottom: 12px;"
    />
    <el-card v-loading="loading" style="margin-bottom: 16px;">
      <template #header><b>切分参数</b></template>
      <el-form label-position="top">
        <el-form-item label="chunk_size (100–4000)">
          <el-input-number v-model="form.chunk_size" :min="100" :max="4000" :step="50" />
        </el-form-item>
        <el-form-item label="chunk_overlap (0–chunk_size)">
          <el-input-number v-model="form.chunk_overlap" :min="0" :max="form.chunk_size - 1" :step="10" />
        </el-form-item>
        <el-form-item label="切分器">
          <el-select v-model="form.splitter">
            <el-option value="recursive" label="recursive" />
            <el-option value="markdown_aware" label="markdown_aware" />
          </el-select>
        </el-form-item>
        <el-button type="primary" :loading="saving" @click="save">保存</el-button>
      </el-form>
    </el-card>

    <el-card>
      <template #header><b>变更历史</b></template>
      <el-table :data="history" border>
        <el-table-column prop="changed_at" label="时间" width="200" />
        <el-table-column prop="chunk_size" label="chunk_size" width="120" />
        <el-table-column prop="chunk_overlap" label="chunk_overlap" width="140" />
        <el-table-column prop="splitter" label="splitter" />
        <el-table-column prop="changed_by" label="变更人 user_id" />
      </el-table>
    </el-card>
  </div>
</template>
