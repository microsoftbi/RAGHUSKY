import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const routes: RouteRecordRaw[] = [
  { path: '/login', name: 'login', component: () => import('@/views/LoginView.vue') },
  { path: '/', redirect: '/chat' },
  { path: '/chat', name: 'chat', component: () => import('@/views/ChatView.vue') },
  { path: '/documents', name: 'documents', component: () => import('@/views/DocumentsView.vue') },
  {
    path: '/admin',
    component: () => import('@/views/admin/AdminLayout.vue'),
    meta: { adminOnly: true },
    children: [
      { path: '', redirect: '/admin/users' },
      { path: 'users', name: 'admin-users', component: () => import('@/views/admin/UsersView.vue') },
      { path: 'documents', name: 'admin-documents', component: () => import('@/views/admin/DocumentsView.vue') },
      { path: 'retrieval', name: 'admin-retrieval', component: () => import('@/views/admin/RetrievalTestView.vue') },
      { path: 'chunk-test', name: 'admin-chunk-test', component: () => import('@/views/admin/ChunkTestView.vue') },
      { path: 'ingest-config', name: 'admin-ingest-config', component: () => import('@/views/admin/IngestConfigView.vue') }
    ]
  },
  { path: '/:pathMatch(.*)*', redirect: '/chat' }
]

const router = createRouter({ history: createWebHistory(), routes })

router.beforeEach((to) => {
  const auth = useAuthStore()
  auth.init()
  if (to.name !== 'login' && !auth.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
  if (to.matched.some((r) => r.meta.adminOnly) && !auth.isAdmin) {
    return { name: 'chat' }
  }
  if (to.name === 'login' && auth.isAuthenticated) {
    return { name: 'chat' }
  }
})

export default router
