<script setup lang="ts">
import { useRouter, useRoute } from 'vue-router'
import { computed } from 'vue'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()
auth.init()

const showShell = computed(() => route.name !== 'login')

function logout() {
  auth.logout()
  router.push({ name: 'login' })
}
</script>

<template>
  <div v-if="showShell" style="display:flex; flex-direction:column; height:100%;">
    <el-header
      style="display:flex; align-items:center; justify-content:space-between;
             background: var(--color-primary); color:#fff; padding: 0 24px;"
    >
      <div style="font-weight:600; font-size:18px;">RAGUSKY</div>
      <el-menu
        mode="horizontal"
        :ellipsis="false"
        :default-active="String(route.name ?? '')"
        background-color="transparent"
        text-color="#fff"
        active-text-color="#fff"
        style="border-bottom:none; flex:1; margin-left:24px;"
        @select="(k) => router.push({ name: k })"
      >
        <el-menu-item index="chat">问答</el-menu-item>
        <el-menu-item index="documents">知识库文档</el-menu-item>
        <template v-if="auth.role === 'admin'">
          <el-menu-item index="admin-users">用户管理</el-menu-item>
          <el-menu-item index="admin-documents">文档信息</el-menu-item>
          <el-menu-item index="admin-retrieval">召回测试</el-menu-item>
          <el-menu-item index="admin-chunk-test">Chunking 测试</el-menu-item>
          <el-menu-item index="admin-ingest-config">切分参数</el-menu-item>
        </template>
      </el-menu>
      <div style="display:flex; align-items:center; gap:12px;">
        <span style="opacity:.9;">{{ auth.username }} ({{ auth.role }})</span>
        <el-button size="small" plain @click="logout">退出</el-button>
      </div>
    </el-header>
    <main style="flex:1; overflow:auto; background: var(--color-surface);">
      <router-view />
    </main>
  </div>
  <router-view v-else />
</template>
