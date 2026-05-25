<script setup lang="ts">
import { ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { login } from '@/api/auth'
import { useAuthStore } from '@/stores/auth'

const username = ref('admin')
const password = ref('')
const loading = ref(false)
const router = useRouter()
const route = useRoute()
const auth = useAuthStore()

async function onSubmit() {
  if (!username.value || !password.value) {
    ElMessage.warning('请输入用户名和密码')
    return
  }
  loading.value = true
  try {
    const res = await login(username.value, password.value)
    auth.setSession(res.access_token, res.username, res.role)
    const redirect = (route.query.redirect as string) || '/chat'
    router.push(redirect)
  } catch {
    // interceptor showed the toast
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div
    style="height:100%; display:flex; align-items:center; justify-content:center;
           background: linear-gradient(135deg, #dbeafe 0%, #ffffff 100%);"
  >
    <el-card style="width: 360px;">
      <h2 style="margin: 4px 0 24px; color: var(--color-primary);">RAGUSKY 登录</h2>
      <el-form @submit.prevent="onSubmit" label-position="top">
        <el-form-item label="用户名">
          <el-input v-model="username" autocomplete="username" />
        </el-form-item>
        <el-form-item label="密码">
          <el-input v-model="password" type="password" show-password autocomplete="current-password" @keyup.enter="onSubmit" />
        </el-form-item>
        <el-button type="primary" :loading="loading" style="width:100%;" @click="onSubmit">登录</el-button>
      </el-form>
    </el-card>
  </div>
</template>
