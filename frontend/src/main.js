import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { Amplify } from 'aws-amplify'
import App from './App.vue'
import router from './router'
import vuetify from './plugins/vuetify'
import { amplifyConfig } from './amplifyconfiguration'
import { initTelemetry } from './telemetry'

// Initialize OpenTelemetry
initTelemetry()

// Configure Amplify
Amplify.configure(amplifyConfig)

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(vuetify)

app.mount('#app')
