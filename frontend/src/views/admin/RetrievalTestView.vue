<script setup lang="ts">
import { ref } from 'vue'
import { ElMessage } from 'element-plus'
import { adminApi, type RetrievedChunk } from '@/api/admin'

const query = ref('')
const topK = ref(4)
const loading = ref(false)
const results = ref<RetrievedChunk[]>([])

async function run() {
  if (!query.value.trim()) {
    ElMessage.warning('请输入 query')
    return
  }
  loading.value = true
  try {
    const res = await adminApi.retrievalTest(query.value.trim(), topK.value)
    results.value = res.chunks
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div>
    <el-alert
      type="info"
      :closable="false"
      title="召回测试只执行向量检索,不调用生成 LLM,用于评估检索质量。"
      style="margin-bottom: 12px;"
    />
    <div style="display:flex; gap:8px; margin-bottom: 12px;">
      <el-input v-model="query" placeholder="输入测试 query" @keyup.enter="run" />
      <el-input-number v-model="topK" :min="1" :max="20" />
      <el-button type="primary" :loading="loading" @click="run">检索</el-button>
    </div>
    <el-table v-loading="loading" :data="results" border>
      <el-table-column type="index" label="#" width="50" />
      <el-table-column prop="source" label="来源" width="280" />
      <el-table-column label="score" width="100">
        <template #default="{ row }">{{ row.score.toFixed(4) }}</template>
      </el-table-column>
      <el-table-column label="切片文本">
        <template #default="{ row }">
          <div style="white-space: pre-wrap; max-height: 220px; overflow: auto;">{{ row.text }}</div>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>
