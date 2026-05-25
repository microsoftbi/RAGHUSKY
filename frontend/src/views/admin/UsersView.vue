<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { adminApi, type AdminUser } from '@/api/admin'

const users = ref<AdminUser[]>([])
const loading = ref(false)

const createDlg = ref(false)
const createForm = reactive({ username: '', password: '', role: 'user' as 'user' | 'admin' })

const pwdDlg = ref(false)
const pwdForm = reactive({ user_id: '', new_password: '' })

async function load() {
  loading.value = true
  try {
    users.value = await adminApi.listUsers()
  } finally {
    loading.value = false
  }
}

async function submitCreate() {
  if (!createForm.username || createForm.password.length < 8) {
    ElMessage.warning('用户名必填,密码至少 8 位')
    return
  }
  await adminApi.createUser({ ...createForm })
  ElMessage.success('已创建')
  createDlg.value = false
  Object.assign(createForm, { username: '', password: '', role: 'user' })
  load()
}

async function toggleActive(u: AdminUser) {
  await adminApi.updateUser(u.user_id, { is_active: !u.is_active })
  load()
}

async function changeRole(u: AdminUser, role: 'user' | 'admin') {
  await adminApi.updateUser(u.user_id, { role })
  load()
}

function openPwd(u: AdminUser) {
  pwdForm.user_id = u.user_id
  pwdForm.new_password = ''
  pwdDlg.value = true
}

async function submitPwd() {
  if (pwdForm.new_password.length < 8) {
    ElMessage.warning('密码至少 8 位')
    return
  }
  await adminApi.resetPassword(pwdForm.user_id, pwdForm.new_password)
  ElMessage.success('已重置')
  pwdDlg.value = false
}

async function removeUser(u: AdminUser) {
  await ElMessageBox.confirm(`确定删除用户 ${u.username}?`, '确认', { type: 'warning' })
  await adminApi.deleteUser(u.user_id)
  ElMessage.success('已删除')
  load()
}

onMounted(load)
</script>

<template>
  <div>
    <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">
      <span style="color: var(--color-text-muted);">系统至少保留 1 个启用状态的管理员。</span>
      <el-button type="primary" @click="createDlg = true">新建用户</el-button>
    </div>
    <el-table v-loading="loading" :data="users" border>
      <el-table-column prop="username" label="用户名" />
      <el-table-column label="角色" width="180">
        <template #default="{ row }">
          <el-select :model-value="row.role" size="small" @change="(v) => changeRole(row, v)">
            <el-option value="user" label="user" />
            <el-option value="admin" label="admin" />
          </el-select>
        </template>
      </el-table-column>
      <el-table-column label="启用" width="100">
        <template #default="{ row }">
          <el-switch :model-value="row.is_active" @change="() => toggleActive(row)" />
        </template>
      </el-table-column>
      <el-table-column prop="created_at" label="创建时间" width="200" />
      <el-table-column prop="last_login_at" label="最后登录" width="200" />
      <el-table-column label="操作" width="220">
        <template #default="{ row }">
          <el-button size="small" @click="openPwd(row)">重置密码</el-button>
          <el-button size="small" type="danger" @click="removeUser(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="createDlg" title="新建用户" width="420px">
      <el-form label-position="top">
        <el-form-item label="用户名"><el-input v-model="createForm.username" /></el-form-item>
        <el-form-item label="密码 (≥ 8 位)"><el-input v-model="createForm.password" type="password" show-password /></el-form-item>
        <el-form-item label="角色">
          <el-select v-model="createForm.role" style="width:100%;">
            <el-option value="user" label="user" />
            <el-option value="admin" label="admin" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="createDlg = false">取消</el-button>
        <el-button type="primary" @click="submitCreate">创建</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="pwdDlg" title="重置密码" width="420px">
      <el-form label-position="top">
        <el-form-item label="新密码 (≥ 8 位)">
          <el-input v-model="pwdForm.new_password" type="password" show-password />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="pwdDlg = false">取消</el-button>
        <el-button type="primary" @click="submitPwd">提交</el-button>
      </template>
    </el-dialog>
  </div>
</template>
