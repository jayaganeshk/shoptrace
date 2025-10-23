import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: () => import('@/views/Home.vue')
  },
  {
    path: '/orders',
    name: 'Orders',
    component: () => import('@/views/Orders.vue')
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
