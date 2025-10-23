import axios from 'axios'
import { useAuthStore } from '@/stores/auth'
import { v4 as uuidv4 } from 'uuid'
import { tracer } from '@/telemetry'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL
})

// Generate session ID once per browser session
const SESSION_ID_KEY = 'app_session_id'
let sessionId = sessionStorage.getItem(SESSION_ID_KEY)
if (!sessionId) {
  sessionId = uuidv4()
  sessionStorage.setItem(SESSION_ID_KEY, sessionId)
}

// Request interceptor to add auth token and session ID
api.interceptors.request.use(
  (config) => {
    const authStore = useAuthStore()

    if (authStore.idToken) {
      config.headers.Authorization = authStore.idToken
    }

    config.headers['x-session-id'] = sessionId

    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      const authStore = useAuthStore()
      authStore.logout()
      window.location.href = '/login'
    }
    
    // Show user-friendly error message
    const message = error.response?.data?.error || 'Something went wrong. Please try again later.'
    showErrorAlert(message)
    
    return Promise.reject(error)
  }
)

// Global error alert function
function showErrorAlert(message) {
  // Create and dispatch custom event for error alerts
  window.dispatchEvent(new CustomEvent('api-error', { 
    detail: { message } 
  }))
}

export const orderService = {
  async listProducts() {
    return tracer.startActiveSpan('listProducts', async (span) => {
      try {
        const response = await api.get('/products')
        span.setAttribute('product.count', response.data.length)
        return response.data
      } finally {
        span.end()
      }
    })
  },

  async createOrder(items, couponCode = null) {
    return tracer.startActiveSpan('createOrder', async (span) => {
      try {
        span.setAttribute('order.items_count', items.length)
        if (couponCode) span.setAttribute('order.coupon_code', couponCode)
        const response = await api.post('/orders', { items, coupon_code: couponCode })
        span.setAttribute('order.id', response.data.order_id)
        return response.data
      } finally {
        span.end()
      }
    })
  },

  async getOrder(orderId) {
    return tracer.startActiveSpan('getOrder', async (span) => {
      try {
        span.setAttribute('order.id', orderId)
        const response = await api.get(`/orders/${orderId}`)
        span.setAttribute('order.status', response.data.status)
        return response.data
      } finally {
        span.end()
      }
    })
  },

  async listOrders(pageSize = 100, after = null) {
    return tracer.startActiveSpan('listOrders', async (span) => {
      try {
        span.setAttribute('pagination.page_size', pageSize)
        if (after) span.setAttribute('pagination.after', after)
        const params = { page_size: pageSize }
        if (after) params.after = after
        const response = await api.get('/orders', { params })
        span.setAttribute('orders.count', response.data.orders?.length || 0)
        return response.data
      } finally {
        span.end()
      }
    })
  },

  async validateCoupon(couponCode) {
    return tracer.startActiveSpan('validateCoupon', async (span) => {
      try {
        span.setAttribute('coupon.code', couponCode)
        const response = await api.post('/coupons/validate', { coupon_code: couponCode })
        span.setAttribute('coupon.valid', response.data.valid)
        if (response.data.discount) span.setAttribute('coupon.discount', response.data.discount)
        return response.data
      } finally {
        span.end()
      }
    })
  }
}

export { sessionId }
