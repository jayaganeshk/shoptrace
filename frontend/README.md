# ShopTrace Frontend

Vue 3 + Vuetify 3 with AWS Amplify authentication and OpenTelemetry browser tracing.

## Features

- AWS Amplify Authentication
- Session tracking with OpenTelemetry
- Shopping cart with coupon validation
- Order history
- Responsive Vuetify UI

## Setup

```bash
npm install

# Create .env
cat > .env << EOF
VITE_API_BASE_URL=https://your-api-gateway-url
VITE_USER_POOL_ID=your-user-pool-id
VITE_USER_POOL_CLIENT_ID=your-client-id
VITE_HONEYCOMB_API_KEY=your-honeycomb-key
EOF

# Development
npm run dev

# Production build
npm run build
```

## Structure

```
src/
├── components/     # Reusable components
├── views/          # Pages (Login, Home, Orders)
├── services/       # API and auth services
├── stores/         # Pinia state management
└── plugins/        # Vuetify configuration
```
cp .env.example .env
```

Update `.env` with your AWS resources:

```env
VITE_API_URL=https://your-api-gateway-url.execute-api.ap-south-1.amazonaws.com/dev
VITE_COGNITO_USER_POOL_ID=ap-south-1_xxxxxxxxx
VITE_COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
VITE_COGNITO_REGION=ap-south-1
```

### 3. Run Development Server

```bash
npm run dev
```

Open http://localhost:5173

### 4. Build for Production

```bash
npm run build
```

Output will be in `dist/` folder.

## Key Features

### Authentication (AWS Amplify)

- Amplify UI Authenticator component
- Pre-built login UI with best practices
- Automatic token management
- Protected routes with navigation guards
- Auth event listeners (Hub)
- Auto-redirect on session expiry

### Session Tracking

- Unique session ID generated per browser session
- Automatically sent with all API requests via `x-session-id` header
- Visible in UI for demo purposes

### API Integration

- Axios interceptors for auth tokens
- Automatic session ID injection
- Error handling with auto-logout on 401

### Shopping Experience

- Product catalog with images
- Shopping cart with quantity management
- Coupon code support
- Order placement with real-time feedback

## Architecture Highlights

### State Management (Pinia)

```javascript
// stores/auth.js
- user state
- authentication methods
- token management
```

### API Service

```javascript
// services/api.js
- Axios instance with base URL
- Request interceptor (auth + session)
- Response interceptor (error handling)
```

### Router Guards

```javascript
// router/index.js
- Check authentication before route access
- Auto-redirect to login if not authenticated
- Prevent login page access when authenticated
```

## Best Practices Implemented

✅ **Modular Code** - Separation of concerns (services, stores, views)  
✅ **Composition API** - Modern Vue 3 patterns  
✅ **TypeScript-ready** - Clean structure for TS migration  
✅ **Environment Variables** - Configuration via .env  
✅ **Error Handling** - Graceful error messages  
✅ **Loading States** - User feedback during async operations  
✅ **Responsive Design** - Mobile-friendly Vuetify components  
✅ **Session Management** - Persistent session tracking  

## Development Tips

### Hot Module Replacement

Vite provides instant HMR. Changes reflect immediately without full page reload.

### Vue DevTools

Install Vue DevTools browser extension for debugging:
- Component hierarchy
- Pinia store state
- Router navigation

### API Testing

Use browser DevTools Network tab to inspect:
- Request headers (Authorization, x-session-id)
- Response data
- Error messages

## Deployment

### Build

```bash
npm run build
```

### Deploy to Amplify

```bash
cd dist
zip -r ../frontend-build.zip .
```

Upload via Amplify Console or CLI.

## Troubleshooting

### Cognito Errors

- Verify User Pool ID and Client ID in `.env`
- Check user exists in Cognito User Pool
- Ensure user is confirmed

### API Errors

- Verify API Gateway URL in `.env`
- Check CORS configuration on backend
- Ensure Cognito authorizer is configured

### Session Issues

- Session ID stored in sessionStorage
- Clear browser storage to reset session
- Check Network tab for `x-session-id` header
