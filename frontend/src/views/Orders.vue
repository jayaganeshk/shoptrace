<template>
  <AppLayout>
    <!-- Header -->
    <v-row class="mb-4 mb-md-6">
      <v-col cols="12">
        <h1 :class="mobile ? 'text-h4' : 'text-h3'" class="font-weight-bold mb-2">My Orders</h1>
        <p class="text-subtitle-1 text-grey">Track and manage your orders</p>
      </v-col>
    </v-row>

    <!-- Loading State -->
    <v-row v-if="loading">
      <v-col cols="12" class="text-center py-12">
        <v-progress-circular
          indeterminate
          color="primary"
          size="64"
        ></v-progress-circular>
        <p class="mt-4 text-grey">Loading your orders...</p>
      </v-col>
    </v-row>

    <!-- Empty State -->
    <v-row v-else-if="orders.length === 0">
      <v-col cols="12">
        <v-card class="text-center pa-12" variant="tonal">
          <v-icon size="80" color="grey-lighten-1">
            {{ authStore.isAuthenticated ? 'mdi-package-variant' : 'mdi-lock' }}
          </v-icon>
          <h3 class="text-h5 mt-4 mb-2">
            {{ authStore.isAuthenticated ? 'No orders yet' : 'Sign in to view orders' }}
          </h3>
          <p class="text-grey mb-4">
            {{ authStore.isAuthenticated ? 'Start shopping to see your orders here' : 'Please sign in to access your order history' }}
          </p>
          <v-btn
            v-if="authStore.isAuthenticated"
            color="primary"
            to="/"
            prepend-icon="mdi-shopping"
          >
            Browse Products
          </v-btn>
          <v-btn
            v-else
            color="primary"
            prepend-icon="mdi-login"
            @click="handleLogin"
          >
            Sign In
          </v-btn>
        </v-card>
      </v-col>
    </v-row>

    <!-- Orders List -->
    <v-row v-else>
      <v-col
        v-for="order in orders"
        :key="order.order_id"
        cols="12"
      >
        <v-card elevation="2" class="order-card">
          <v-card-title class="d-flex align-center bg-grey-lighten-4">
            <v-icon class="mr-2">mdi-receipt</v-icon>
            <span class="font-weight-bold">
              Order #{{ order.order_id.substring(0, 8) }}
            </span>
            <v-spacer></v-spacer>
            <v-chip
              :color="getStatusColor(order.status)"
              size="small"
              variant="flat"
            >
              {{ order.status }}
            </v-chip>
          </v-card-title>

          <v-card-subtitle class="pt-3">
            <v-icon size="small" class="mr-1">mdi-calendar</v-icon>
            {{ formatDate(order.created_at) }}
          </v-card-subtitle>

          <v-divider class="my-2"></v-divider>

          <v-card-text>
            <!-- Order Items -->
            <v-list class="py-0">
              <v-list-item
                v-for="(item, index) in order.items"
                :key="index"
                class="px-0"
              >
                <template v-slot:prepend>
                  <v-icon color="primary">mdi-package</v-icon>
                </template>

                <v-list-item-title class="font-weight-medium">
                  {{ item.name }}
                </v-list-item-title>
                
                <v-list-item-subtitle>
                  ₹{{ item.price }} × {{ item.quantity }} = ₹{{ (item.price * item.quantity).toFixed(2) }}
                </v-list-item-subtitle>
              </v-list-item>
            </v-list>

            <v-divider class="my-3"></v-divider>

            <!-- Order Summary -->
            <div class="d-flex justify-space-between align-center">
              <div>
                <v-chip
                  v-if="order.coupon_code !== 'none'"
                  size="small"
                  color="success"
                  prepend-icon="mdi-ticket-percent"
                  variant="tonal"
                >
                  {{ order.coupon_code }} (-{{ order.discount_percentage }}%)
                </v-chip>
              </div>
              <div class="text-right">
                <p class="text-caption text-grey mb-1">Total Amount</p>
                <p class="text-h5 font-weight-bold text-primary">
                  ₹{{ order.total_price }}
                </p>
              </div>
            </div>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </AppLayout>
</template>

<script setup>
import { ref, onMounted, watch } from 'vue'
import { useDisplay } from 'vuetify'
import { signInWithRedirect } from 'aws-amplify/auth'
import AppLayout from '@/layouts/AppLayout.vue'
import { orderService } from '@/services/api'
import { useAuthStore } from '@/stores/auth'

const { mobile } = useDisplay()
const authStore = useAuthStore()
const orders = ref([])
const loading = ref(false)

const handleLogin = async () => {
  await signInWithRedirect()
}

const loadOrders = async () => {
  if (!authStore.isAuthenticated) {
    return
  }
  
  loading.value = true
  try {
    const response = await orderService.listOrders()
    orders.value = response.items || response
  } catch (error) {
    console.error('Failed to load orders:', error);
  } finally {
    loading.value = false
  }
}

const getStatusColor = (status) => {
  const colors = {
    CREATED: 'success',
    PENDING: 'warning',
    COMPLETED: 'primary',
    FAILED: 'error'
  }
  return colors[status] || 'grey'
}

const formatDate = (dateString) => {
  return new Date(dateString).toLocaleString('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

watch(() => authStore.user, (newUser) => {
  if (newUser) {
    loadOrders()
  }
})

onMounted(() => {
  loadOrders()
})
</script>

<style scoped>
.order-card {
  transition: transform 0.2s ease-in-out;
}

.order-card:hover {
  transform: translateY(-2px);
}
</style>
