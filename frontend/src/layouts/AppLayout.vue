<template>
  <v-app>
    <v-app-bar color="primary" elevation="0" prominent>
      <v-app-bar-nav-icon
        v-if="mobile"
        @click="drawer = !drawer"
      ></v-app-bar-nav-icon>

      <template v-slot:prepend v-if="!mobile">
        <img src="/ShopTrace.svg" alt="ShopTrace" height="32" class="ml-2" />
      </template>

      <v-app-bar-title class="font-weight-bold">
        <span v-if="!mobile">ShopTrace</span>
        <span v-else class="text-body-1">ShopTrace</span>
      </v-app-bar-title>

      <v-spacer></v-spacer>

      <!-- Authenticated User -->
      <template v-if="authStore.isAuthenticated">
        <v-chip
          v-if="!mobile"
          class="mr-4"
          prepend-icon="mdi-account-circle"
          variant="flat"
          color="white"
        >
          {{ authStore.user?.username }}
        </v-chip>

        <v-menu v-else>
          <template v-slot:activator="{ props }">
            <v-btn icon="mdi-account-circle" v-bind="props"></v-btn>
          </template>
          <v-list>
            <v-list-item>
              <v-list-item-title>{{
                authStore.user?.username
              }}</v-list-item-title>
            </v-list-item>
          </v-list>
        </v-menu>

        <v-btn icon="mdi-logout" variant="text" @click="handleLogout"></v-btn>
      </template>

      <!-- Not Authenticated -->
      <v-btn
        v-else
        color="white"
        variant="flat"
        prepend-icon="mdi-login"
        @click="handleLogin"
      >
        Sign In
      </v-btn>
    </v-app-bar>

    <v-navigation-drawer
      v-model="drawer"
      :permanent="!mobile"
      :temporary="mobile"
      width="260"
    >
      <v-list nav class="py-4">
        <v-list-item
          prepend-icon="mdi-view-grid"
          title="Products"
          value="home"
          to="/"
          color="primary"
          rounded="xl"
          class="mx-2"
        ></v-list-item>

        <v-list-item
          prepend-icon="mdi-package-variant"
          title="My Orders"
          value="orders"
          to="/orders"
          color="primary"
          rounded="xl"
          class="mx-2"
        ></v-list-item>
      </v-list>

      <template v-slot:append>
        <v-divider></v-divider>
        <div class="pa-4">
          <v-card variant="tonal" color="primary">
            <v-card-text class="text-caption">
              <div class="font-weight-bold mb-1">Session ID</div>
              <div class="text-truncate" :title="sessionId">
                {{ sessionId.substring(0, 20) }}...
              </div>
            </v-card-text>
          </v-card>
        </div>
      </template>
    </v-navigation-drawer>

    <v-main class="bg-grey-lighten-5">
      <v-container fluid :class="mobile ? 'pa-4' : 'pa-6'">
        <slot />
      </v-container>
    </v-main>
  </v-app>

  <!-- Global Error Alert -->
  <v-snackbar
    v-model="errorAlert.show"
    :timeout="5000"
    color="error"
    location="top"
  >
    {{ errorAlert.message }}
    <template v-slot:actions>
      <v-btn
        color="white"
        variant="text"
        @click="errorAlert.show = false"
      >
        Close
      </v-btn>
    </template>
  </v-snackbar>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from "vue";
import { useDisplay } from "vuetify";
import { useAuthStore } from "@/stores/auth";
import { signInWithRedirect, signOut } from "aws-amplify/auth";
import { sessionId } from "@/services/api";

const { mobile } = useDisplay();
const authStore = useAuthStore();
const drawer = ref(true);

const handleLogin = async () => {
  await signInWithRedirect();
};

const handleLogout = async () => {
  await signOut();
  window.location.href = "/";
};
const errorAlert = ref({
  show: false,
  message: ''
});

const handleApiError = (event) => {
  errorAlert.value.message = event.detail.message;
  errorAlert.value.show = true;
};

onMounted(() => {
  window.addEventListener('api-error', handleApiError);
});

onUnmounted(() => {
  window.removeEventListener('api-error', handleApiError);
});
</script>
