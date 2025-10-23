export const amplifyConfig = {
  Auth: {
    Cognito: {
      userPoolId: import.meta.env.VITE_COGNITO_USER_POOL_ID,
      userPoolClientId: import.meta.env.VITE_COGNITO_CLIENT_ID,
      loginWith: {
        oauth: {
          domain: import.meta.env.VITE_COGNITO_DOMAIN,
          scopes: ['email', 'openid', 'profile', 'aws.cognito.signin.user.admin'],
          redirectSignIn: [import.meta.env.VITE_APP_URL],
          redirectSignOut: [import.meta.env.VITE_APP_URL],
          responseType: 'code'
        }
      }
    }
  }
}
