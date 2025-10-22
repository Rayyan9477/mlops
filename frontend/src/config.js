// Environment configuration utility
// This ensures we can use environment variables both in development and production

const getEnvVar = (key, defaultValue = '') => {
  // In production (nginx), use window.env
  if (window.env && window.env[key]) {
    return window.env[key];
  }
  // In development, use process.env
  if (process.env[key]) {
    return process.env[key];
  }
  return defaultValue;
};

export const config = {
  AUTH_SERVICE_URL: getEnvVar('REACT_APP_AUTH_SERVICE_URL', 'http://localhost:5001'),
  BACKEND_SERVICE_URL: getEnvVar('REACT_APP_BACKEND_SERVICE_URL', 'http://localhost:5000')
};
