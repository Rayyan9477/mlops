#!/bin/sh
# Frontend entrypoint script to generate runtime environment config

# Generate env-config.js with environment variables
cat > /usr/share/nginx/html/env-config.js << EOF
window.env = {
  REACT_APP_AUTH_SERVICE_URL: '${REACT_APP_AUTH_SERVICE_URL:-http://localhost:5001}',
  REACT_APP_BACKEND_SERVICE_URL: '${REACT_APP_BACKEND_SERVICE_URL:-http://localhost:5000}'
};
EOF

echo "Environment configuration generated:"
cat /usr/share/nginx/html/env-config.js

# Start nginx
nginx -g 'daemon off;'
