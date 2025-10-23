<template>
  <AppLayout>
    <!-- Header -->
    <v-row class="mb-4 mb-md-6">
      <v-col cols="12">
        <div
          class="d-flex flex-column flex-sm-row align-start align-sm-center justify-space-between"
        >
          <div class="mb-4 mb-sm-0">
            <h1
              :class="mobile ? 'text-h4' : 'text-h3'"
              class="font-weight-bold mb-2"
            >
              Products
            </h1>
            <p class="text-subtitle-1 text-grey">
              Discover our latest collection
            </p>
          </div>

          <!-- Cart Button -->
          <v-btn
            v-if="cart.length > 0"
            color="primary"
            :size="mobile ? 'default' : 'large'"
            prepend-icon="mdi-cart"
            @click="cartDialog = true"
          >
            <v-badge :content="cartItemCount" color="error" inline>
              Cart
            </v-badge>
          </v-btn>
        </div>
      </v-col>
    </v-row>

    <!-- Products Grid -->
    <v-row v-if="loadingProducts">
      <v-col cols="12" class="text-center py-12">
        <v-progress-circular
          indeterminate
          color="primary"
          size="64"
        ></v-progress-circular>
        <p class="mt-4 text-grey">Loading products...</p>
      </v-col>
    </v-row>

    <v-row v-else>
      <v-col
        v-for="product in products"
        :key="product.id"
        cols="12"
        sm="6"
        md="4"
        lg="3"
      >
        <v-card class="product-card" elevation="2" hover>
          <v-img :src="product.image" height="220" cover class="align-end">
            <v-chip class="ma-2" color="primary" size="small">
              {{ product.category }}
            </v-chip>
          </v-img>

          <v-card-title class="text-h6">
            {{ product.name }}
          </v-card-title>

          <v-card-subtitle class="text-h6 font-weight-bold text-primary">
            ₹{{ product.price.toFixed(2) }}
          </v-card-subtitle>

          <v-card-text>
            <p class="text-body-2">{{ product.description }}</p>
          </v-card-text>

          <v-card-actions>
            <v-spacer></v-spacer>
            <v-btn
              color="primary"
              variant="flat"
              prepend-icon="mdi-cart-plus"
              @click="addToCart(product)"
            >
              Add to Cart
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-col>
    </v-row>

    <!-- Cart Dialog -->
    <v-dialog
      v-model="cartDialog"
      :max-width="mobile ? '100%' : '700'"
      :fullscreen="mobile"
    >
      <v-card>
        <v-card-title class="d-flex align-center bg-primary">
          <v-icon class="mr-2">mdi-cart</v-icon>
          Shopping Cart
          <v-spacer></v-spacer>
          <v-btn
            icon="mdi-close"
            variant="text"
            @click="cartDialog = false"
          ></v-btn>
        </v-card-title>

        <v-divider></v-divider>

        <v-card-text :class="mobile ? 'pa-3' : 'pa-4'">
          <!-- Cart Items -->
          <v-list v-if="cart.length > 0" class="py-0">
            <v-list-item
              v-for="item in cart"
              :key="item.id"
              :class="mobile ? 'px-0 mb-2' : 'px-0 mb-3'"
            >
              <template v-slot:prepend>
                <v-avatar :size="mobile ? 50 : 60" rounded>
                  <v-img :src="item.image"></v-img>
                </v-avatar>
              </template>

              <v-list-item-title
                :class="mobile ? 'text-body-2' : ''"
                class="font-weight-medium"
              >
                {{ item.name }}
              </v-list-item-title>

              <v-list-item-subtitle :class="mobile ? 'text-caption' : ''">
                ₹{{ item.price }} × {{ item.quantity }} = ₹{{
                  (item.price * item.quantity).toFixed(2)
                }}
              </v-list-item-subtitle>

              <template v-slot:append>
                <div class="d-flex align-center flex-wrap">
                  <v-btn
                    icon="mdi-minus"
                    :size="mobile ? 'x-small' : 'small'"
                    variant="outlined"
                    @click="updateQuantity(item, -1)"
                  ></v-btn>
                  <span
                    :class="mobile ? 'mx-2 text-caption' : 'mx-3'"
                    class="font-weight-bold"
                    >{{ item.quantity }}</span
                  >
                  <v-btn
                    icon="mdi-plus"
                    :size="mobile ? 'x-small' : 'small'"
                    variant="outlined"
                    @click="updateQuantity(item, 1)"
                  ></v-btn>
                  <v-btn
                    icon="mdi-delete"
                    :size="mobile ? 'x-small' : 'small'"
                    variant="text"
                    color="error"
                    :class="mobile ? 'ml-1' : 'ml-2'"
                    @click="removeFromCart(item)"
                  ></v-btn>
                </div>
              </template>
            </v-list-item>
          </v-list>

          <v-alert v-else type="info" variant="tonal">
            Your cart is empty. Start shopping!
          </v-alert>

          <!-- Coupon Code -->
          <v-divider class="my-4"></v-divider>

          <div class="mb-3">
            <v-text-field
              v-model="couponCode"
              label="Have a coupon code?"
              prepend-inner-icon="mdi-ticket-percent"
              variant="outlined"
              density="comfortable"
              clearable
              :loading="validatingCoupon"
              :error="couponError !== null"
              :success="couponValid"
              @update:model-value="onCouponChange"
              @keyup.enter="validateCoupon"
            >
              <template v-slot:append-inner>
                <v-btn
                  v-if="couponCode && !couponValid"
                  size="small"
                  color="primary"
                  variant="flat"
                  :loading="validatingCoupon"
                  @click="validateCoupon"
                >
                  Apply
                </v-btn>
                <v-icon v-if="couponValid" color="success"
                  >mdi-check-circle</v-icon
                >
              </template>
            </v-text-field>

            <!-- Coupon Feedback -->
            <v-alert
              v-if="couponError"
              type="error"
              variant="tonal"
              density="compact"
              class="mt-2"
            >
              {{ couponError }}
            </v-alert>

            <v-alert
              v-if="couponValid && couponDiscount > 0"
              type="success"
              variant="tonal"
              density="compact"
              class="mt-2"
            >
              <div class="d-flex align-center">
                <span>Coupon applied! You save {{ couponDiscount }}%</span>
              </div>
            </v-alert>
          </div>

          <!-- Total -->
          <v-divider class="my-4"></v-divider>

          <div class="pricing-summary">
            <div class="d-flex justify-space-between mb-2">
              <span class="text-body-2 text-grey"
                >Subtotal ({{ cartItemCount }} items)</span
              >
              <span class="text-body-1 font-weight-medium"
                >₹{{ cartTotal.toFixed(2) }}</span
              >
            </div>

            <div
              v-if="couponValid && couponDiscount > 0"
              class="d-flex justify-space-between mb-2"
            >
              <span class="text-body-2 text-success"
                >Discount ({{ couponDiscount }}%)</span
              >
              <span class="text-body-1 font-weight-medium text-success"
                >-₹{{ discountAmount.toFixed(2) }}</span
              >
            </div>

            <v-divider class="my-2"></v-divider>

            <div class="d-flex justify-space-between align-center">
              <span class="text-h6 font-weight-bold">Total</span>
              <span class="text-h5 font-weight-bold text-primary"
                >₹{{ finalTotal.toFixed(2) }}</span
              >
            </div>
          </div>
        </v-card-text>

        <v-divider></v-divider>

        <v-card-actions class="pa-4">
          <v-btn variant="outlined" @click="cartDialog = false">
            Continue Shopping
          </v-btn>
          <v-spacer></v-spacer>

          <!-- Show login button if not authenticated -->
          <v-btn
            v-if="!authStore.isAuthenticated"
            color="primary"
            size="large"
            prepend-icon="mdi-login"
            @click="handleLogin"
          >
            Sign In to Order
          </v-btn>

          <!-- Show place order button if authenticated -->
          <v-btn
            v-else
            color="primary"
            size="large"
            :loading="loading"
            :disabled="cart.length === 0"
            prepend-icon="mdi-check"
            @click="placeOrder"
          >
            Place Order
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>

    <!-- Success Snackbar -->
    <v-snackbar
      v-model="snackbar"
      :color="snackbarColor"
      location="top"
      :timeout="3000"
    >
      <div class="d-flex align-center">
        <v-icon class="mr-2">
          {{
            snackbarColor === "success"
              ? "mdi-check-circle"
              : "mdi-alert-circle"
          }}
        </v-icon>
        {{ snackbarText }}
      </div>
    </v-snackbar>
  </AppLayout>
</template>

<script setup>
import { ref, computed, onMounted } from "vue";
import { useRouter } from "vue-router";
import { useDisplay } from "vuetify";
import { signInWithRedirect } from "aws-amplify/auth";
import AppLayout from "@/layouts/AppLayout.vue";
import { orderService } from "@/services/api";
import { useAuthStore } from "@/stores/auth";

const router = useRouter();
const { mobile } = useDisplay();
const authStore = useAuthStore();

const products = ref([]);
const loadingProducts = ref(false);
const cart = ref(JSON.parse(localStorage.getItem("cart") || "[]"));
const cartDialog = ref(false);
const couponCode = ref("");
const couponValid = ref(false);
const couponDiscount = ref(0);
const couponError = ref(null);
const validatingCoupon = ref(false);
const loading = ref(false);
const snackbar = ref(false);
const snackbarText = ref("");
const snackbarColor = ref("success");

const cartTotal = computed(() => {
  return cart.value.reduce(
    (total, item) => total + item.price * item.quantity,
    0
  );
});

const cartItemCount = computed(() => {
  return cart.value.reduce((count, item) => count + item.quantity, 0);
});

const discountAmount = computed(() => {
  return couponValid.value ? (cartTotal.value * couponDiscount.value) / 100 : 0;
});

const finalTotal = computed(() => {
  return cartTotal.value - discountAmount.value;
});

const onCouponChange = () => {
  couponValid.value = false;
  couponDiscount.value = 0;
  couponError.value = null;
};

const validateCoupon = async () => {
  if (!couponCode.value) return;

  if (!authStore.isAuthenticated) {
    couponError.value = "Please sign in to use coupons";
    return;
  }

  validatingCoupon.value = true;
  couponError.value = null;

  try {
    const result = await orderService.validateCoupon(couponCode.value);

    if (result.valid) {
      couponValid.value = true;
      couponDiscount.value = result.discount_percentage;
      couponError.value = null;
    } else {
      couponValid.value = false;
      couponDiscount.value = 0;
      couponError.value = result.error || "Invalid coupon code";
    }
  } catch (error) {
    couponValid.value = false;
    couponDiscount.value = 0;
    console.error("Failed to validate coupon:", error);
  } finally {
    validatingCoupon.value = false;
  }
};

const handleLogin = async () => {
  await signInWithRedirect();
};

const addToCart = (product) => {
  const existingItem = cart.value.find((item) => item.id === product.id);

  if (existingItem) {
    existingItem.quantity++;
  } else {
    cart.value.push({ ...product, quantity: 1 });
  }

  localStorage.setItem("cart", JSON.stringify(cart.value));

  snackbarText.value = `${product.name} added to cart`;
  snackbarColor.value = "success";
  snackbar.value = true;
};

const updateQuantity = (item, change) => {
  item.quantity += change;

  if (item.quantity <= 0) {
    removeFromCart(item);
  } else {
    localStorage.setItem("cart", JSON.stringify(cart.value));
  }
};

const removeFromCart = (item) => {
  cart.value = cart.value.filter((i) => i.id !== item.id);
  localStorage.setItem("cart", JSON.stringify(cart.value));

  snackbarText.value = `${item.name} removed from cart`;
  snackbarColor.value = "info";
  snackbar.value = true;
};

const placeOrder = async () => {
  if (!authStore.isAuthenticated) {
    snackbarText.value = "Please sign in to place an order";
    snackbarColor.value = "warning";
    snackbar.value = true;
    return;
  }

  loading.value = true;

  try {
    const items = cart.value.map((item) => ({
      name: item.name,
      price: item.price,
      quantity: item.quantity,
    }));

    const result = await orderService.createOrder(
      items,
      couponCode.value || null
    );

    snackbarText.value = `Order placed successfully! Order ID: ${result.order_id.substring(
      0,
      8
    )}`;
    snackbarColor.value = "success";
    snackbar.value = true;

    // Clear cart and coupon
    cart.value = [];
    localStorage.removeItem("cart");
    couponCode.value = "";
    couponValid.value = false;
    couponDiscount.value = 0;
    cartDialog.value = false;

    setTimeout(() => {
      router.push("/orders");
    }, 2000);
  } catch (error) {
    console.error("Failed to place order:", error);
  } finally {
    loading.value = false;
  }
};

const loadProducts = async () => {
  loadingProducts.value = true;
  try {
    const response = await orderService.listProducts();
    products.value = response.items || [];
  } catch (error) {
    console.error("Failed to load products:", error);
  } finally {
    loadingProducts.value = false;
  }
};

onMounted(() => {
  loadProducts();
});
</script>

<style scoped>
.product-card {
  transition: transform 0.2s ease-in-out;
}

.product-card:hover {
  transform: translateY(-4px);
}
</style>
