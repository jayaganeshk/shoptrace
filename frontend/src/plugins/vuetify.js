import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'
import '@mdi/font/css/materialdesignicons.css'
import 'vuetify/styles'

export default createVuetify({
  components,
  directives,
  theme: {
    defaultTheme: 'light',
    themes: {
      light: {
        colors: {
          primary: '#6366F1',      // Modern indigo
          secondary: '#8B5CF6',    // Purple
          accent: '#EC4899',       // Pink
          error: '#EF4444',        // Red
          info: '#3B82F6',         // Blue
          success: '#10B981',      // Green
          warning: '#F59E0B',      // Amber
          background: '#F9FAFB',   // Light gray
          surface: '#FFFFFF'
        }
      }
    }
  },
  defaults: {
    VBtn: {
      rounded: 'lg'
    },
    VCard: {
      rounded: 'lg'
    },
    VChip: {
      rounded: 'lg'
    }
  }
})
