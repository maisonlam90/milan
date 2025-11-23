/**
 * This is simple JWT API for testing purposes.
 * https://github.com/pinia-studio/jwt-api-node
 **/

// Detect environment and set API URL
const getApiUrl = () => {
  // Development: localhost
  if (window.location.hostname === "localhost") {
    return "http://localhost:3000";
  }
  
  // Production: Use same hostname but port 3000 (backend port)
  // Frontend runs on port 2000, backend on port 3000
  const hostname = window.location.hostname;
  const protocol = window.location.protocol;
  return `${protocol}//${hostname}:3000`;
};

export const JWT_HOST_API = getApiUrl();